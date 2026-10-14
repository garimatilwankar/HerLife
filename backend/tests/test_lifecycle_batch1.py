from __future__ import annotations

import sys
from pathlib import Path

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

import unittest
from datetime import date
from sqlalchemy import create_engine, text

from app.core.lifecycle_resolver import (
    STAGE_ADOLESCENCE,
    STAGE_MENOPAUSE,
    STAGE_MENSTRUAL_HEALTH,
    STAGE_PERIMENOPAUSE,
    STAGE_POSTPARTUM,
    STAGE_PREGNANCY,
    STAGE_REPRODUCTIVE_HEALTH,
    STAGE_UNSPECIFIED,
    build_neutral_fallback_config,
    normalize_stage_name,
    resolve_lifecycle_experience,
)
from scripts.migrate_lifecycle import plan_migration


class TestLifecycleResolver(unittest.TestCase):
    """Tests the pure table-driven lifecycle experience resolver."""

    def test_canonical_stage_normalization(self):
        self.assertEqual(normalize_stage_name("Adolescence"), STAGE_ADOLESCENCE)
        self.assertEqual(normalize_stage_name("Menstruation"), STAGE_MENSTRUAL_HEALTH)
        self.assertEqual(normalize_stage_name("Reproductive Years"), STAGE_REPRODUCTIVE_HEALTH)
        self.assertEqual(normalize_stage_name("Reproductive Health"), STAGE_REPRODUCTIVE_HEALTH)
        self.assertEqual(normalize_stage_name("Pregnancy"), STAGE_PREGNANCY)
        self.assertEqual(normalize_stage_name("Postpartum"), STAGE_POSTPARTUM)
        self.assertEqual(normalize_stage_name("Perimenopause"), STAGE_PERIMENOPAUSE)
        self.assertEqual(normalize_stage_name("Menopause"), STAGE_MENOPAUSE)

    def test_missing_or_invalid_stage_safe_neutral_fallback(self):
        """Adjustment 1: Must NOT silently default to menstrual health on missing or invalid stage."""
        # 1. None stage
        config_none = resolve_lifecycle_experience(None)
        self.assertTrue(config_none["is_neutral_fallback"])
        self.assertEqual(config_none["primary_stage"], STAGE_UNSPECIFIED)
        self.assertFalse(config_none["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config_none["enabled_modules"]["gestation_timeline"])
        self.assertIn("unspecified", config_none["why"].lower())

        # 2. Empty string stage
        config_empty = resolve_lifecycle_experience("")
        self.assertTrue(config_empty["is_neutral_fallback"])
        self.assertEqual(config_empty["primary_stage"], STAGE_UNSPECIFIED)
        self.assertFalse(config_empty["enabled_modules"]["cycle_tracking"])

        # 3. Invalid unknown string stage
        config_invalid = resolve_lifecycle_experience("unknown_stage_xyz")
        self.assertTrue(config_invalid["is_neutral_fallback"])
        self.assertEqual(config_invalid["primary_stage"], STAGE_UNSPECIFIED)
        self.assertFalse(config_invalid["enabled_modules"]["cycle_tracking"])
        self.assertIn("unrecognized", config_invalid["why"].lower())

    def test_strict_mode_raises_on_invalid_stage(self):
        """Adjustment 1: Explicit validation error option under strict mode."""
        with self.assertRaises(ValueError):
            resolve_lifecycle_experience(None, strict=True)
        with self.assertRaises(ValueError):
            resolve_lifecycle_experience("invalid_stage", strict=True)

    def test_adolescence_configuration(self):
        config = resolve_lifecycle_experience(STAGE_ADOLESCENCE)
        self.assertEqual(config["primary_stage"], STAGE_ADOLESCENCE)
        self.assertTrue(config["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config["enabled_modules"]["ovulation_prediction"])
        self.assertEqual(config["behavioral_flags"]["cycle_prediction_mode"], "active")
        self.assertEqual(config["behavioral_flags"]["cycle_variance_tolerance"], "expected_variable")
        self.assertIn("developing", config["why"].lower())
        self.assertTrue(any(c["card_type"] == "cycle_summary_card" for c in config["dashboard_cards"]))

    def test_reproductive_health_and_menstrual_health(self):
        config = resolve_lifecycle_experience("Reproductive Years")
        self.assertEqual(config["primary_stage"], STAGE_REPRODUCTIVE_HEALTH)
        self.assertTrue(config["enabled_modules"]["cycle_tracking"])
        self.assertTrue(config["enabled_modules"]["ovulation_prediction"])
        self.assertEqual(config["behavioral_flags"]["cycle_prediction_mode"], "active")
        self.assertEqual(config["behavioral_flags"]["cycle_variance_tolerance"], "standard")

    def test_contraception_overlap_context(self):
        """Hormonal contraception should suppress physiological ovulation prediction."""
        config = resolve_lifecycle_experience(
            STAGE_REPRODUCTIVE_HEALTH,
            contexts=["hormonal_contraception"],
        )
        self.assertTrue(config["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config["enabled_modules"]["ovulation_prediction"])
        self.assertIn("hormonal contraception", config["why"].lower())

    def test_irregular_cycles_overlap_context(self):
        config = resolve_lifecycle_experience(
            STAGE_REPRODUCTIVE_HEALTH,
            contexts=["irregular_cycles"],
        )
        self.assertEqual(config["behavioral_flags"]["cycle_variance_tolerance"], "expected_variable")
        self.assertIn("irregular cycles", config["why"].lower())

    def test_pregnancy_configuration(self):
        test_due_date = date(2026, 11, 20)
        config = resolve_lifecycle_experience(STAGE_PREGNANCY, due_date=test_due_date)
        self.assertEqual(config["primary_stage"], STAGE_PREGNANCY)
        self.assertFalse(config["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config["enabled_modules"]["ovulation_prediction"])
        self.assertTrue(config["enabled_modules"]["gestation_timeline"])
        self.assertEqual(config["behavioral_flags"]["cycle_prediction_mode"], "paused")
        self.assertTrue(config["behavioral_flags"]["pregnancy_mode"])
        self.assertIn("gestation_milestone_card", [c["card_type"] for c in config["dashboard_cards"]])
        milestone_card = next(c for c in config["dashboard_cards"] if c["card_type"] == "gestation_milestone_card")
        self.assertEqual(milestone_card["action_payload"]["due_date"], "2026-11-20")

    def test_postpartum_configuration(self):
        test_delivery = date(2026, 8, 1)
        config = resolve_lifecycle_experience(
            STAGE_POSTPARTUM,
            contexts=["breastfeeding"],
            delivery_date=test_delivery,
        )
        self.assertEqual(config["primary_stage"], STAGE_POSTPARTUM)
        self.assertFalse(config["enabled_modules"]["cycle_tracking"])
        self.assertTrue(config["enabled_modules"]["lochia_logger"])
        self.assertTrue(config["enabled_modules"]["recovery_checkin"])
        self.assertEqual(config["behavioral_flags"]["cycle_prediction_mode"], "paused")
        self.assertTrue(config["behavioral_flags"]["postpartum_mode"])
        self.assertIn("breastfeeding", config["why"].lower())

    def test_perimenopause_configuration(self):
        config = resolve_lifecycle_experience(STAGE_PERIMENOPAUSE)
        self.assertEqual(config["primary_stage"], STAGE_PERIMENOPAUSE)
        self.assertTrue(config["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config["enabled_modules"]["ovulation_prediction"])
        self.assertTrue(config["enabled_modules"]["vasomotor_tracker"])
        self.assertEqual(config["behavioral_flags"]["cycle_variance_tolerance"], "expected_variable")

    def test_menopause_configuration(self):
        config = resolve_lifecycle_experience(STAGE_MENOPAUSE)
        self.assertEqual(config["primary_stage"], STAGE_MENOPAUSE)
        self.assertFalse(config["enabled_modules"]["cycle_tracking"])
        self.assertFalse(config["enabled_modules"]["ovulation_prediction"])
        self.assertTrue(config["enabled_modules"]["vasomotor_tracker"])
        self.assertEqual(config["behavioral_flags"]["cycle_prediction_mode"], "disabled")
        self.assertIn("menopause_wellness_card", [c["card_type"] for c in config["dashboard_cards"]])

    def test_why_field_present_on_all_outputs(self):
        """Ensures every configuration carries an explicit, non-empty audit why string."""
        for stage in [
            STAGE_ADOLESCENCE,
            STAGE_MENSTRUAL_HEALTH,
            STAGE_REPRODUCTIVE_HEALTH,
            STAGE_PREGNANCY,
            STAGE_POSTPARTUM,
            STAGE_PERIMENOPAUSE,
            STAGE_MENOPAUSE,
            STAGE_UNSPECIFIED,
            None,
        ]:
            cfg = resolve_lifecycle_experience(stage)
            self.assertIn("why", cfg)
            self.assertIsInstance(cfg["why"], str)
            self.assertTrue(len(cfg["why"]) > 10)


class TestMigrationLogicOnSimulatedDatabase(unittest.TestCase):
    """
    Tests migration planning and backfill logic on an isolated in-memory SQLite database
    simulating the 4 live PostgreSQL profile records. Zero live database alteration.
    """

    def setUp(self):
        self.engine = create_engine("sqlite:///:memory:")
        with self.engine.begin() as conn:
            conn.execute(text("""
                CREATE TABLE users (
                    id INTEGER PRIMARY KEY,
                    name VARCHAR(100),
                    email VARCHAR(255)
                );
            """))
            conn.execute(text("""
                CREATE TABLE profiles (
                    id INTEGER PRIMARY KEY,
                    user_id INTEGER NOT NULL REFERENCES users(id),
                    date_of_birth DATE,
                    biological_assignment VARCHAR(50),
                    lifecycle_stage VARCHAR(50),
                    updated_at TIMESTAMP
                );
            """))

            # Populate with mock records matching the exact 4 live rows in PostgreSQL:
            conn.execute(text("""
                INSERT INTO profiles (id, user_id, lifecycle_stage, date_of_birth)
                VALUES
                    (1, 1, 'Reproductive Years', '2005-05-15'),
                    (2, 3, 'Menstruation', NULL),
                    (3, 4, 'Menstruation', NULL),
                    (4, 2, 'Adolescence', NULL);
            """))

    def tearDown(self):
        self.engine.dispose()

    def test_plan_migration_detects_existing_profiles(self):
        with self.engine.connect() as conn:
            schema = {
                "has_profiles": True,
                "has_stage_history": False,
                "profile_columns": ["id", "user_id", "date_of_birth", "biological_assignment", "lifecycle_stage", "updated_at"],
            }
            plan = plan_migration(schema, conn)

            self.assertEqual(len(plan["backfill_plan"]), 4)
            # Verify honest date handling (Adjustment 4: started_on is None, is_estimated is True)
            for item in plan["backfill_plan"]:
                self.assertIsNone(item["stage_start_date"])
                self.assertTrue(item["is_estimated"])

            canonical_mapped = [item["canonical_primary_stage"] for item in plan["backfill_plan"]]
            self.assertIn(STAGE_REPRODUCTIVE_HEALTH, canonical_mapped)
            self.assertIn(STAGE_MENSTRUAL_HEALTH, canonical_mapped)
            self.assertIn(STAGE_ADOLESCENCE, canonical_mapped)


if __name__ == "__main__":
    unittest.main()
