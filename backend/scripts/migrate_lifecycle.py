#!/usr/bin/env python3
"""
HerLife Lifecycle Personalization Migration Utility.

Safe, idempotent, standalone migration script for Phase 1 lifecycle schema additions.
No third-party migration tools required. Runs with standard library + SQLAlchemy.

Usage:
    python backend/scripts/migrate_lifecycle.py --dry-run
    python backend/scripts/migrate_lifecycle.py --backup
    python backend/scripts/migrate_lifecycle.py --apply
    python backend/scripts/migrate_lifecycle.py --rollback --confirm-rollback
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

from dotenv import load_dotenv
load_dotenv(backend_dir / ".env")

from sqlalchemy import inspect, text
from app.database import engine
from app.core.lifecycle_resolver import normalize_stage_name

BACKUP_DIR = backend_dir / "backups"


def create_backup(conn) -> Path:
    """Exports all rows in `profiles` to a JSON backup file."""
    BACKUP_DIR.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
    backup_file = BACKUP_DIR / f"profiles_backup_{timestamp}.json"

    rows = conn.execute(text("SELECT * FROM profiles;")).mappings().all()
    serializable = []
    for row in rows:
        item = {}
        for k, v in dict(row).items():
            if hasattr(v, "isoformat"):
                item[k] = v.isoformat()
            else:
                item[k] = v
        serializable.append(item)

    with open(backup_file, "w", encoding="utf-8") as f:
        json.dump(serializable, f, indent=2)

    return backup_file


def inspect_current_schema(conn) -> dict[str, Any]:
    """Inspects existing tables and columns."""
    insp = inspect(conn)
    tables = insp.get_table_names()
    profile_cols = [c["name"] for c in insp.get_columns("profiles")] if "profiles" in tables else []
    history_cols = [c["name"] for c in insp.get_columns("stage_history")] if "stage_history" in tables else []
    return {
        "has_profiles": "profiles" in tables,
        "has_stage_history": "stage_history" in tables,
        "profile_columns": profile_cols,
        "stage_history_columns": history_cols,
    }


def plan_migration(current_schema: dict[str, Any], conn) -> dict[str, Any]:
    """Computes necessary DDL and backfill operations."""
    ddl_statements: list[str] = []

    # 1. Create stage_history table if missing
    if not current_schema["has_stage_history"]:
        ddl_statements.append(
            """
            CREATE TABLE IF NOT EXISTS stage_history (
                id SERIAL PRIMARY KEY,
                user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
                stage VARCHAR(50) NOT NULL,
                started_on DATE NULL,
                is_estimated BOOLEAN NOT NULL DEFAULT FALSE,
                ended_on DATE NULL,
                reason VARCHAR(255) NULL,
                created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
            );
            """
        )
        ddl_statements.append(
            "CREATE INDEX IF NOT EXISTS idx_stage_history_user ON stage_history(user_id, stage);"
        )

    # 2. Add additive columns to profiles if missing
    existing_cols = set(current_schema["profile_columns"])
    desired_cols = [
        ("primary_stage", "VARCHAR(50) NULL"),
        ("stage_start_date", "DATE NULL"),
        ("goal", "VARCHAR(100) NULL"),
        ("contexts", "JSON NULL DEFAULT '[]'::json"),
        ("due_date", "DATE NULL"),
        ("delivery_date", "DATE NULL"),
    ]

    for col_name, col_type in desired_cols:
        if col_name not in existing_cols:
            ddl_statements.append(
                f"ALTER TABLE profiles ADD COLUMN IF NOT EXISTS {col_name} {col_type};"
            )

    # 3. Identify rows to backfill
    backfill_plan = []
    if current_schema["has_profiles"]:
        # Query existing profiles
        rows = conn.execute(text("SELECT id, user_id, lifecycle_stage, date_of_birth FROM profiles;")).mappings().all()
        for r in rows:
            old_stage = r["lifecycle_stage"]
            canonical = normalize_stage_name(old_stage)
            backfill_plan.append({
                "profile_id": r["id"],
                "user_id": r["user_id"],
                "old_lifecycle_stage": old_stage,
                "canonical_primary_stage": canonical,
                # Honest handling: unknown start date preserved as None / estimated
                "stage_start_date": None,
                "is_estimated": True,
            })

    return {
        "ddl_statements": ddl_statements,
        "backfill_plan": backfill_plan,
    }


def execute_migration(conn, dry_run: bool = False) -> None:
    """Executes or dry-runs the migration."""
    schema = inspect_current_schema(conn)
    plan = plan_migration(schema, conn)

    print("=" * 60)
    print("HerLife Lifecycle Migration Plan")
    print("=" * 60)
    print(f"Mode: {'DRY-RUN (Simulating without modifying DB)' if dry_run else 'APPLY (Writing changes to DB)'}")
    print(f"Existing profiles table present: {schema['has_profiles']}")
    print(f"Existing stage_history table present: {schema['has_stage_history']}")
    print(f"Pending DDL statements: {len(plan['ddl_statements'])}")

    for idx, stmt in enumerate(plan["ddl_statements"], 1):
        print(f"\n  [DDL {idx}]:\n  {stmt.strip()}")

    print(f"\nProfiles to backfill: {len(plan['backfill_plan'])}")
    for item in plan["backfill_plan"]:
        print(f"  User {item['user_id']} (Profile {item['profile_id']}): "
              f"'{item['old_lifecycle_stage']}' -> canonical '{item['canonical_primary_stage']}' "
              f"(started_on=None, is_estimated=True)")

    if dry_run:
        print("\n" + "=" * 60)
        print("Dry run completed successfully. Zero database changes were committed.")
        print("=" * 60)
        return

    # Execute DDL statements
    print("\nApplying DDL statements...")
    for stmt in plan["ddl_statements"]:
        conn.execute(text(stmt))

    # Execute Backfill
    print("Applying backfill updates...")
    for item in plan["backfill_plan"]:
        if item["canonical_primary_stage"] is not None:
            # Update primary_stage only if currently null
            conn.execute(
                text("""
                    UPDATE profiles
                    SET primary_stage = :canonical
                    WHERE id = :pid AND (primary_stage IS NULL OR primary_stage = '');
                """),
                {"canonical": item["canonical_primary_stage"], "pid": item["profile_id"]},
            )

            # Insert initial stage history record if none exists for this user and stage
            existing_hist = conn.execute(
                text("""
                    SELECT id FROM stage_history
                    WHERE user_id = :uid AND stage = :stage
                    LIMIT 1;
                """),
                {"uid": item["user_id"], "stage": item["canonical_primary_stage"]},
            ).scalar()

            if not existing_hist:
                conn.execute(
                    text("""
                        INSERT INTO stage_history (
                            user_id, stage, started_on, is_estimated, ended_on, reason, created_at
                        ) VALUES (
                            :uid, :stage, NULL, TRUE, NULL, :reason, (NOW() AT TIME ZONE 'UTC')
                        );
                    """),
                    {
                        "uid": item["user_id"],
                        "stage": item["canonical_primary_stage"],
                        "reason": "Initial backfill from legacy selection",
                    },
                )

    print("\n" + "=" * 60)
    print("Migration applied successfully! All records backfilled safely.")
    print("=" * 60)


def execute_rollback(conn, confirm: bool = False) -> None:
    """
    Rolls back Phase 1 lifecycle schema additions safely.

    Rollback Limitations & Guarantees:
    - Drops added columns: primary_stage, stage_start_date, goal, contexts, due_date, delivery_date.
    - Drops added table: stage_history.
    - PRESERVES all pre-existing columns: id, user_id, date_of_birth, biological_assignment, lifecycle_stage.
    - PRESERVES all existing user rows and tracking data.
    - LIMITATION: Any stage_history audit records recorded since migration will be removed.
    """
    if not confirm:
        print("ERROR: Rollback requires explicit confirmation flag: --confirm-rollback")
        sys.exit(1)

    print("=" * 60)
    print("ROLLBACK: Reverting Phase 1 Lifecycle Additions")
    print("=" * 60)

    # 1. Drop stage_history table
    conn.execute(text("DROP TABLE IF EXISTS stage_history CASCADE;"))
    print("  Dropped table: stage_history")

    # 2. Drop additive columns from profiles (preserving original lifecycle_stage)
    drop_columns = [
        "primary_stage",
        "stage_start_date",
        "goal",
        "contexts",
        "due_date",
        "delivery_date",
    ]
    for col in drop_columns:
        conn.execute(text(f"ALTER TABLE profiles DROP COLUMN IF EXISTS {col} CASCADE;"))
        print(f"  Dropped column: profiles.{col}")

    print("\nRollback complete. Original profiles table schema restored.")


def main():
    parser = argparse.ArgumentParser(description="HerLife Lifecycle Migration Utility")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--dry-run", action="store_true", help="Simulate migration without modifying DB")
    group.add_argument("--backup", action="store_true", help="Export JSON backup of profiles table")
    group.add_argument("--apply", action="store_true", help="Apply migration and backfill inside a transaction")
    group.add_argument("--rollback", action="store_true", help="Rollback Phase 1 additions")

    parser.add_argument(
        "--confirm-rollback",
        action="store_true",
        help="Required confirmation flag to execute rollback",
    )

    args = parser.parse_args()

    if args.backup:
        with engine.connect() as conn:
            backup_path = create_backup(conn)
            print(f"Backup saved successfully to: {backup_path}")
        return

    if args.dry_run:
        with engine.connect() as conn:
            execute_migration(conn, dry_run=True)
        return

    if args.apply:
        # Automatically take backup before applying changes
        with engine.connect() as conn:
            backup_path = create_backup(conn)
            print(f"Pre-migration backup saved to: {backup_path}")

        # Transaction-wrapped apply
        with engine.begin() as conn:
            execute_migration(conn, dry_run=False)
        return

    if args.rollback:
        with engine.begin() as conn:
            execute_rollback(conn, confirm=args.confirm_rollback)
        return


if __name__ == "__main__":
    main()
