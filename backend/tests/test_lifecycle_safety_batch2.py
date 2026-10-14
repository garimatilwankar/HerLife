from __future__ import annotations

import sys
from pathlib import Path
from unittest.mock import MagicMock, patch

# Add backend directory to sys.path
backend_dir = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(backend_dir))

import unittest

from app.core.lifecycle_resolver import (
    STAGE_ADOLESCENCE,
    STAGE_MENOPAUSE,
    STAGE_MENSTRUAL_HEALTH,
    STAGE_PERIMENOPAUSE,
    STAGE_POSTPARTUM,
    STAGE_PREGNANCY,
    STAGE_REPRODUCTIVE_HEALTH,
    STAGE_UNSPECIFIED,
)
from app.core.question_safety import (
    INTENT_CLINICAL_EVALUATION,
    INTENT_DIAGNOSIS,
    INTENT_GENERAL,
    INTENT_MEDICATION,
    INTENT_SYMPTOM,
    INTENT_URGENT,
    SAFETY_CAUTION,
    SAFETY_INFORMATIONAL,
    SAFETY_URGENT,
    classify_question,
)
from app.models.profile import Profile
from app.models.user import User
from app.routers.ask import ask_question
from app.schemas.ask import AskRequest


class TestUniversalAndBaselineSafety(unittest.TestCase):
    """Verifies existing universal emergency detection, diagnosis guards, and medication guards."""

    def test_universal_emergencies(self):
        # 1. Severe bleeding
        res = classify_question("I have severe bleeding and lost a lot of blood")
        self.assertEqual(res.safety_level, SAFETY_URGENT)
        self.assertEqual(res.intent, INTENT_URGENT)

        # 2. Chest pain & difficulty breathing
        res = classify_question("I am having chest pain and difficulty breathing")
        self.assertEqual(res.safety_level, SAFETY_URGENT)
        self.assertEqual(res.intent, INTENT_URGENT)

        # 3. Fainting & syncope
        res = classify_question("I fainted earlier and passed out")
        self.assertEqual(res.safety_level, SAFETY_URGENT)

        # 4. Bleeding + dizziness
        res = classify_question("I am bleeding heavily and feel very dizzy")
        self.assertEqual(res.safety_level, SAFETY_URGENT)

        # 5. Seizures
        res = classify_question("Someone is having a seizure")
        self.assertEqual(res.safety_level, SAFETY_URGENT)

        # 6. Crisis / Self-harm (with regional guidance verified)
        res = classify_question("I want to kill myself")
        self.assertEqual(res.safety_level, SAFETY_URGENT)
        self.assertIn("988", res.override_answer)
        self.assertIn("112", res.override_answer)

    def test_diagnosis_guardrails(self):
        # Must flag caution and provide educational disclaimer
        res = classify_question("Do I have PCOS?")
        self.assertEqual(res.safety_level, SAFETY_CAUTION)
        self.assertEqual(res.intent, INTENT_DIAGNOSIS)
        self.assertTrue(res.is_safe)
        self.assertIn("cannot diagnose", res.override_answer)

        res2 = classify_question("Could I have endometriosis or fibroids?")
        self.assertEqual(res2.safety_level, SAFETY_CAUTION)
        self.assertEqual(res2.intent, INTENT_DIAGNOSIS)

    def test_medication_guardrails(self):
        # Must flag caution and refuse prescription/dosing
        res = classify_question("What dose of ibuprofen should I take for pain?")
        self.assertEqual(res.safety_level, SAFETY_CAUTION)
        self.assertEqual(res.intent, INTENT_MEDICATION)
        self.assertTrue(res.is_safe)
        self.assertIn("does not prescribe medications", res.override_answer)

        res2 = classify_question("Can I take 800mg paracetamol?")
        self.assertEqual(res2.safety_level, SAFETY_CAUTION)
        self.assertEqual(res2.intent, INTENT_MEDICATION)


class TestEducationalNegationAndPastSymptoms(unittest.TestCase):
    """Refinement 3: Verifies negation, hypothetical/educational queries, and resolved past symptoms."""

    def test_educational_queries_do_not_trigger_urgent(self):
        # Educational inquiries asking for definitions or lists of warning signs
        queries = [
            "What are pregnancy warning signs?",
            "What are danger signs in pregnancy?",
            "What are red flags during pregnancy?",
            "What is preeclampsia?",
            "Tell me about postpartum hemorrhage",
            "Can you explain postmenopausal bleeding?",
            "What is lochia?",
            "What causes postpartum fever?",
            "What are postpartum intrusive thoughts?",
            "Can you explain postpartum depression?",
        ]
        for q in queries:
            res = classify_question(q)
            self.assertEqual(
                res.safety_level,
                SAFETY_INFORMATIONAL,
                f"Query '{q}' should be INFORMATIONAL, not {res.safety_level}",
            )
            self.assertNotEqual(res.intent, INTENT_URGENT)

    def test_negation_handling(self):
        # Explicit negation must suppress stage-specific emergency triggers
        q1 = "I'm not pregnant, but my period is late"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_INFORMATIONAL)
        self.assertNotEqual(res1.intent, INTENT_URGENT)

        q2 = "I am not pregnant and have mild cramping"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_INFORMATIONAL)

        q3 = "Not postpartum, why am I tired?"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_INFORMATIONAL)

        q4 = "I am not postpartum and have a fever"
        res4 = classify_question(q4)
        self.assertEqual(res4.safety_level, SAFETY_INFORMATIONAL)
        self.assertNotEqual(res4.intent, INTENT_URGENT)

        # Negated postpartum diagnostic question triggers diagnosis caution, but NEVER postpartum urgent emergency
        q5 = "I am not postpartum, why do I have a fever?"
        res5 = classify_question(q5)
        self.assertNotEqual(res5.intent, INTENT_URGENT)
        self.assertNotEqual(res5.safety_level, SAFETY_URGENT)

    def test_past_resolved_symptoms(self):
        # Symptoms that occurred in the past and resolved should not trigger acute emergency
        q1 = "Last month I had severe cramps for an hour but now I'm fine"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_INFORMATIONAL)
        self.assertEqual(res1.intent, INTENT_SYMPTOM)

        q2 = "Two weeks ago I felt dizzy and lightheaded, is that normal?"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_INFORMATIONAL)

        q3 = "Last year I had heavy bleeding during my period but it stopped"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_INFORMATIONAL)

        q4 = "Last week I had a fever for an hour but now I feel fine"
        res4 = classify_question(q4)
        self.assertEqual(res4.safety_level, SAFETY_INFORMATIONAL)


class TestLifecycleAwareEmergencyRules(unittest.TestCase):
    """Refinements 2, 4, 6: Tests pregnancy, postpartum, menorrhagia, and menopause distinction."""

    def test_pregnancy_emergencies_explicit_query(self):
        # 1. Preeclampsia: Severe headache + blurry vision
        q1 = "I'm 28 weeks pregnant and have a severe headache with blurry vision"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_PREGNANCY_PREECLAMPSIA_HEADACHE_VISION")
        self.assertIn("obstetrician", res1.override_answer.lower())

        # 2. Fluid leakage
        q2 = "I am pregnant and fluid is leaking down my legs"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_PREGNANCY_FLUID_LEAKAGE")

        # 3. Cessation of fetal movement
        q3 = "I'm pregnant and the baby stopped moving today"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_PREGNANCY_FETAL_MOVEMENT_DECREASED")

        # 4. Vaginal bleeding in pregnancy
        q4 = "I am 16 weeks pregnant and having vaginal bleeding"
        res4 = classify_question(q4)
        self.assertEqual(res4.safety_level, SAFETY_URGENT)
        self.assertEqual(res4.rule_id, "RULE_PREGNANCY_VAGINAL_BLEEDING")

    def test_pregnancy_emergencies_via_profile_stage(self):
        # Query omits the word 'pregnant', but user profile indicates pregnancy
        q = "The baby hasn't moved for hours and my head hurts with spots in vision"
        res = classify_question(q, lifecycle_stage=STAGE_PREGNANCY)
        self.assertEqual(res.safety_level, SAFETY_URGENT)

    def test_postpartum_emergencies(self):
        # 1. Postpartum hemorrhage: Soaking a pad an hour
        q1 = "I had a baby 5 days ago and I am soaking a pad an hour"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_HEMORRHAGE_PAD_SOAKING")

        # 2. Passing golf ball sized clots
        q2 = "I am 10 days postpartum and passing golf ball sized blood clots"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)

        # 3. Postpartum fever and chills
        q3 = "1 week postpartum with high fever and foul smelling lochia"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_POSTPARTUM_FEVER_CHILLS")

        # 4. Unilateral calf pain/swelling (DVT)
        q4 = "I gave birth last week and my left calf is swollen, red and painful"
        res4 = classify_question(q4)
        self.assertEqual(res4.safety_level, SAFETY_URGENT)
        self.assertEqual(res4.rule_id, "RULE_POSTPARTUM_DVT")

        # 5. Postpartum preeclampsia
        q5 = "I am 2 weeks postpartum and have a terrible headache with blurry vision"
        res5 = classify_question(q5)
        self.assertEqual(res5.safety_level, SAFETY_URGENT)
        self.assertEqual(res5.rule_id, "RULE_POSTPARTUM_PREECLAMPSIA")

    def test_postpartum_month_and_elapsed_time_detection(self):
        """Batch 2 Fix 1: Verifies month-based and elapsed time phrases trigger postpartum safety rules."""
        # A. '10 months postpartum'
        q1 = "I am 10 months postpartum and soaking a pad an hour"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_HEMORRHAGE_PAD_SOAKING")

        # B. '10 months after delivery'
        q2 = "10 months after delivery with severe headache and blurry vision"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_POSTPARTUM_PREECLAMPSIA")

        # C. '3 months postpartum'
        q3 = "3 months postpartum with a fever of 102 and chills"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_POSTPARTUM_FEVER_CHILLS")

        # D. 'gave birth 10 months ago'
        q4 = "I gave birth 10 months ago and my left calf is swollen, red and painful"
        res4 = classify_question(q4)
        self.assertEqual(res4.safety_level, SAFETY_URGENT)
        self.assertEqual(res4.rule_id, "RULE_POSTPARTUM_DVT")

    def test_postpartum_fever_and_chills_independent(self):
        """Batch 2 Fix 2: Verifies fever/chills triggers urgent guidance without foul discharge."""
        # Query with explicit postpartum context: fever and shaking chills without discharge
        q1 = "I'm 2 weeks postpartum and have a high fever and shaking chills"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_FEVER_CHILLS")
        self.assertIn("fever or chills", res1.override_answer.lower())

        # Query via profile stage: fever of 101 without lochia mention
        q2 = "I have a high fever of 101 and chills"
        res2 = classify_question(q2, lifecycle_stage=STAGE_POSTPARTUM)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_POSTPARTUM_FEVER_CHILLS")

    def test_postpartum_foul_discharge_independent(self):
        """Batch 2 Fix 2: Verifies foul discharge triggers urgent guidance without fever."""
        q1 = "I gave birth last week and have foul smelling lochia"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_FOUL_DISCHARGE")

        q2 = "I am 5 days postpartum with foul smelly discharge"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_POSTPARTUM_FOUL_DISCHARGE")

    def test_postpartum_headache_and_vision_beyond_six_weeks(self):
        """Batch 2 Fix 4: Verifies severe headache and vision changes are not dismissed after 6 weeks."""
        # At 10 weeks postpartum
        q1 = "I am 10 weeks postpartum and have a severe headache with blurry vision"
        res1 = classify_question(q1)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_PREECLAMPSIA")

        # At 6 months postpartum
        q2 = "6 months postpartum and having a terrible headache and seeing spots"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_POSTPARTUM_PREECLAMPSIA")

        # At 10 months after delivery
        q3 = "10 months after delivery and having blurry vision and a bad headache"
        res3 = classify_question(q3)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_POSTPARTUM_PREECLAMPSIA")

    def test_menopause_bleeding_distinction(self):
        """Refinement 2: Distinguish prompt clinical evaluation from immediate emergency."""
        # A. Isolated postmenopausal spotting -> Prompt clinical evaluation (SAFETY_CAUTION)
        q_isolated = "I went through menopause 2 years ago and noticed spotting today"
        res_iso = classify_question(q_isolated)
        self.assertEqual(res_iso.safety_level, SAFETY_CAUTION)
        self.assertEqual(res_iso.intent, INTENT_CLINICAL_EVALUATION)
        self.assertEqual(res_iso.rule_id, "RULE_MENOPAUSE_BLEEDING_ISOLATED")
        self.assertIn("gynecologist or healthcare provider", res_iso.override_answer)
        self.assertIn("ultrasound or biopsy", res_iso.override_answer)
        self.assertIn("unexpected and should be evaluated promptly", res_iso.override_answer)

        # B. Postmenopausal bleeding via profile stage (isolated)
        q_profile = "I noticed some light bleeding and pink discharge"
        res_profile = classify_question(q_profile, lifecycle_stage=STAGE_MENOPAUSE)
        self.assertEqual(res_profile.safety_level, SAFETY_CAUTION)
        self.assertEqual(res_profile.intent, INTENT_CLINICAL_EVALUATION)

        # C. Postmenopausal bleeding WITH acute escalation -> SAFETY_URGENT
        q_acute = "I am postmenopausal and have heavy bleeding and feel very dizzy"
        res_acute = classify_question(q_acute)
        self.assertEqual(res_acute.safety_level, SAFETY_URGENT)
        self.assertEqual(res_acute.rule_id, "RULE_MENOPAUSE_BLEEDING_ACUTE")
        self.assertIn("emergency department", res_acute.override_answer)

    def test_menstrual_acute_menorrhagia(self):
        q = "I have been soaking through pads every hour for two hours"
        res = classify_question(q, lifecycle_stage=STAGE_MENSTRUAL_HEALTH)
        self.assertEqual(res.safety_level, SAFETY_URGENT)
        self.assertEqual(res.rule_id, "RULE_MENSTRUAL_ACUTE_SOAKING_CONSECUTIVE")

    def test_unspecified_stage_neutrality(self):
        # 1. Unspecified stage with ordinary symptom remains safe & neutral
        res1 = classify_question("Why am I feeling tired and bloated?", lifecycle_stage=STAGE_UNSPECIFIED)
        self.assertEqual(res1.safety_level, SAFETY_INFORMATIONAL)
        self.assertEqual(res1.intent, INTENT_SYMPTOM)

        # 2. Unspecified stage with universal emergency triggers universal emergency
        res2 = classify_question("I have chest pain and trouble breathing", lifecycle_stage=None)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)

        # 3. Unspecified stage with explicit pregnancy emergency triggers pregnancy emergency
        res3 = classify_question("I am pregnant and have severe headache and vision loss", lifecycle_stage=None)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_PREGNANCY_PREECLAMPSIA_HEADACHE_VISION")


class TestInfantSafetyAndPerinatalMentalHealth(unittest.TestCase):
    """Batch 2 Fix 3: Tests universal infant safety, intent escalation, and intrusive thoughts distinction."""

    def test_unknown_stage_infant_harm_intent(self):
        # 1. Active intent with unspecified lifecycle stage
        q1 = "I want to hurt my baby"
        res1 = classify_question(q1, lifecycle_stage=None)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.intent, INTENT_URGENT)
        self.assertEqual(res1.rule_id, "RULE_CRISIS_INFANT_INTENT")
        self.assertIn("988", res1.override_answer)
        self.assertIn("1-833-852-6262", res1.override_answer)
        self.assertIn("crib", res1.override_answer.lower())

        # 2. Urge to hurt with explicitly unspecified profile
        q2 = "I feel like hurting the baby"
        res2 = classify_question(q2, lifecycle_stage=STAGE_UNSPECIFIED)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_CRISIS_INFANT_INTENT")

        # 3. Kill declaration
        q3 = "I am going to kill my baby"
        res3 = classify_question(q3, lifecycle_stage=STAGE_REPRODUCTIVE_HEALTH)
        self.assertEqual(res3.safety_level, SAFETY_URGENT)
        self.assertEqual(res3.rule_id, "RULE_CRISIS_INFANT_INTENT")

    def test_unwanted_intrusive_thoughts_without_intent(self):
        # 1. Distressing intrusive thoughts about hurting baby (without intent)
        q1 = "I keep having intrusive thoughts of hurting my baby and I'm terrified"
        res1 = classify_question(q1, lifecycle_stage=None)
        self.assertEqual(res1.safety_level, SAFETY_CAUTION)
        self.assertEqual(res1.intent, INTENT_CLINICAL_EVALUATION)
        self.assertEqual(res1.rule_id, "RULE_POSTPARTUM_INTRUSIVE_THOUGHTS")
        self.assertTrue(res1.is_safe)
        self.assertIn("not your fault", res1.override_answer)
        self.assertIn("not the same as an intent", res1.override_answer)
        self.assertIn("1-833-852-6262", res1.override_answer)
        self.assertIn("1-800-944-4773", res1.override_answer)
        self.assertIn("crib", res1.override_answer.lower())

        # 2. Intrusive thoughts of dropping baby
        q2 = "I have scary intrusive thoughts about dropping my baby, I love him so much"
        res2 = classify_question(q2)
        self.assertEqual(res2.safety_level, SAFETY_CAUTION)
        self.assertEqual(res2.rule_id, "RULE_POSTPARTUM_INTRUSIVE_THOUGHTS")

        # 3. Terrified of harming baby
        q3 = "I am terrified I might harm my baby, why am I thinking this?"
        res3 = classify_question(q3, lifecycle_stage=STAGE_POSTPARTUM)
        self.assertEqual(res3.safety_level, SAFETY_CAUTION)
        self.assertEqual(res3.rule_id, "RULE_POSTPARTUM_INTRUSIVE_THOUGHTS")

    def test_ambiguous_infant_harm_queries(self):
        # Ambiguous statements without intrusive thought markers escalate to urgent crisis guidance cautiously
        q = "Thoughts of hurting my baby"
        res = classify_question(q, lifecycle_stage=None)
        self.assertEqual(res.safety_level, SAFETY_URGENT)
        self.assertEqual(res.rule_id, "RULE_CRISIS_INFANT_INTENT")
        self.assertIn("988", res.override_answer)
        self.assertIn("1-833-852-6262", res.override_answer)

    def test_self_harm_priority(self):
        # Explicit self-harm remains highest priority
        res1 = classify_question("I want to kill myself", lifecycle_stage=None)
        self.assertEqual(res1.safety_level, SAFETY_URGENT)
        self.assertEqual(res1.rule_id, "RULE_UNIVERSAL_SELF_HARM")

        # Mixed self-harm and infant harm retains acute crisis level
        res2 = classify_question("I want to kill myself and my baby", lifecycle_stage=None)
        self.assertEqual(res2.safety_level, SAFETY_URGENT)
        self.assertEqual(res2.rule_id, "RULE_UNIVERSAL_SELF_HARM")


class TestAskEndpointSafetyBypass(unittest.TestCase):
    """
    Refinement 7: Tests the actual Ask endpoint with mocked DB retrieval and Gemini calls
    to verify that urgent questions completely bypass article retrieval and Gemini.
    """

    def setUp(self):
        self.mock_user = User(id=1, email="test@example.com", name="Test User")
        self.mock_db = MagicMock()

    @patch("app.routers.ask.generate_conversational_answer")
    @patch("app.routers.ask.seed_education_data")
    def test_urgent_question_bypasses_gemini_and_article_retrieval(
        self,
        mock_seed,
        mock_gemini,
    ):
        # Configure profile as pregnant
        mock_profile = Profile(
            id=1,
            user_id=1,
            primary_stage="pregnancy",
            lifecycle_stage="pregnancy",
        )
        self.mock_db.scalar.return_value = mock_profile

        request_data = AskRequest(
            question="I'm 30 weeks pregnant and leaking fluid down my legs",
            conversation_history=[],
        )

        response = ask_question(
            data=request_data,
            current_user=self.mock_user,
            db=self.mock_db,
        )

        # 1. Response must be URGENT with static safe guidance
        self.assertEqual(response.safety_level, SAFETY_URGENT)
        self.assertEqual(response.intent, INTENT_URGENT)
        self.assertIn("obstetrician", response.answer.lower())
        self.assertEqual(response.sources, [])

        # 2. Gemini must NEVER be called for urgent questions
        mock_gemini.assert_not_called()

        # 3. Article retrieval queries must be bypassed (db.scalars not called for articles)
        self.mock_db.scalars.assert_not_called()

    @patch("app.routers.ask.generate_conversational_answer")
    @patch("app.routers.ask.seed_education_data")
    def test_non_urgent_educational_question_invokes_gemini(
        self,
        mock_seed,
        mock_gemini,
    ):
        mock_profile = Profile(
            id=1,
            user_id=1,
            primary_stage="reproductive_health",
            lifecycle_stage="reproductive_health",
        )
        self.mock_db.scalar.return_value = mock_profile
        self.mock_db.scalars.return_value.all.return_value = []
        mock_gemini.return_value = "Educational response about cycle phases."

        request_data = AskRequest(
            question="What are the phases of the menstrual cycle?",
            conversation_history=[],
        )

        response = ask_question(
            data=request_data,
            current_user=self.mock_user,
            db=self.mock_db,
        )

        self.assertEqual(response.safety_level, SAFETY_INFORMATIONAL)
        self.assertEqual(response.answer, "Educational response about cycle phases.")
        mock_gemini.assert_called_once()

    @patch("app.routers.ask.generate_conversational_answer")
    @patch("app.routers.ask.seed_education_data")
    def test_fallback_when_gemini_unavailable(
        self,
        mock_seed,
        mock_gemini,
    ):
        mock_profile = Profile(id=1, user_id=1, primary_stage="menopause")
        self.mock_db.scalar.return_value = mock_profile
        self.mock_db.scalars.return_value.all.return_value = []
        # Simulate Gemini failure/unavailable
        mock_gemini.return_value = None

        request_data = AskRequest(
            question="I went through menopause 2 years ago and noticed spotting today",
            conversation_history=[],
        )

        response = ask_question(
            data=request_data,
            current_user=self.mock_user,
            db=self.mock_db,
        )

        # Fallback uses override_answer for clinical evaluation
        self.assertEqual(response.safety_level, SAFETY_CAUTION)
        self.assertIn("gynecologist or healthcare provider", response.answer)


if __name__ == "__main__":
    unittest.main()
