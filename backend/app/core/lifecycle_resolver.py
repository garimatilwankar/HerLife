from __future__ import annotations

from datetime import date
from typing import Any

# Canonical lifecycle stage identifiers
STAGE_ADOLESCENCE = "adolescence"
STAGE_MENSTRUAL_HEALTH = "menstrual_health"
STAGE_REPRODUCTIVE_HEALTH = "reproductive_health"
STAGE_PREGNANCY = "pregnancy"
STAGE_POSTPARTUM = "postpartum"
STAGE_PERIMENOPAUSE = "perimenopause"
STAGE_MENOPAUSE = "menopause"
STAGE_UNSPECIFIED = "unspecified"

VALID_CANONICAL_STAGES = {
    STAGE_ADOLESCENCE,
    STAGE_MENSTRUAL_HEALTH,
    STAGE_REPRODUCTIVE_HEALTH,
    STAGE_PREGNANCY,
    STAGE_POSTPARTUM,
    STAGE_PERIMENOPAUSE,
    STAGE_MENOPAUSE,
}

# Mapping of legacy / display string values to canonical identifiers
LEGACY_STAGE_MAPPING = {
    "adolescence": STAGE_ADOLESCENCE,
    "menstruation": STAGE_MENSTRUAL_HEALTH,
    "menstrual health": STAGE_MENSTRUAL_HEALTH,
    "reproductive health": STAGE_REPRODUCTIVE_HEALTH,
    "reproductive years": STAGE_REPRODUCTIVE_HEALTH,
    "pregnancy": STAGE_PREGNANCY,
    "postpartum": STAGE_POSTPARTUM,
    "perimenopause": STAGE_PERIMENOPAUSE,
    "menopause": STAGE_MENOPAUSE,
}

# Display names for canonical stages
STAGE_DISPLAY_NAMES = {
    STAGE_ADOLESCENCE: "Adolescence",
    STAGE_MENSTRUAL_HEALTH: "Menstrual Health",
    STAGE_REPRODUCTIVE_HEALTH: "Reproductive Health",
    STAGE_PREGNANCY: "Pregnancy",
    STAGE_POSTPARTUM: "Postpartum",
    STAGE_PERIMENOPAUSE: "Perimenopause",
    STAGE_MENOPAUSE: "Menopause & Beyond",
    STAGE_UNSPECIFIED: "Unspecified Stage",
}

# Recognized context flags
VALID_CONTEXTS = {
    "breastfeeding",
    "hormonal_contraception",
    "irregular_cycles",
    "trying_to_conceive",
    "avoiding_pregnancy",
    "surgical_menopause",
    "recent_pregnancy_loss",
}

# Recognized user goals
VALID_GOALS = {
    "track_cycle",
    "conceive",
    "avoid_pregnancy",
    "manage_symptoms",
    "postpartum_recovery",
    "general_awareness",
}


def normalize_stage_name(stage: str | None) -> str | None:
    """
    Normalizes a stage string (canonical or legacy display name) to canonical identifier.
    Returns None if missing or unrecognized.
    """
    if not stage or not stage.strip():
        return None
    cleaned = stage.strip().lower()
    if cleaned in VALID_CANONICAL_STAGES:
        return cleaned
    return LEGACY_STAGE_MAPPING.get(cleaned)


def build_neutral_fallback_config(raw_input: str | None = None) -> dict[str, Any]:
    """
    Returns a safe, neutral fallback configuration when lifecycle stage is missing or invalid.
    Strictly avoids defaulting to menstrual health or any single reproductive assumption.
    """
    reason = (
        f"Stage '{raw_input}' is unrecognized."
        if raw_input
        else "Lifecycle stage is unspecified."
    )
    return {
        "primary_stage": STAGE_UNSPECIFIED,
        "display_name": STAGE_DISPLAY_NAMES[STAGE_UNSPECIFIED],
        "is_neutral_fallback": True,
        "active_contexts": [],
        "goal": "general_awareness",
        "enabled_modules": {
            "cycle_tracking": False,
            "ovulation_prediction": False,
            "gestation_timeline": False,
            "lochia_logger": False,
            "symptom_logger": True,
            "vasomotor_tracker": False,
            "recovery_checkin": False,
        },
        "behavioral_flags": {
            "cycle_prediction_mode": "disabled",
            "cycle_variance_tolerance": "standard",
            "pregnancy_mode": False,
            "postpartum_mode": False,
        },
        "symptom_catalog": [
            {"name": "Headache", "category": "general"},
            {"name": "Fatigue", "category": "general"},
            {"name": "Stress", "category": "mood"},
            {"name": "Sleep disruption", "category": "general"},
        ],
        "dashboard_cards": [
            {
                "card_type": "stage_setup_prompt",
                "priority": 1,
                "title": "Select your life stage",
                "subtitle": "Choose your lifecycle stage in settings to personalize tracking.",
                "action_payload": {"route": "/lifecycle"},
            },
            {
                "card_type": "daily_checkin_card",
                "priority": 2,
                "title": "Daily Wellness Check-in",
                "subtitle": "Log how you are feeling today.",
                "action_payload": {"route": "/checkin"},
            },
        ],
        "ask_system_context": (
            "The user has not specified a lifecycle stage. Provide safe, general, "
            "foundational health information without assuming menstrual status, pregnancy, or menopause."
        ),
        "why": f"{reason} Neutral baseline active with specialized tracking modules inactive until configured.",
    }


def resolve_lifecycle_experience(
    primary_stage: str | None,
    contexts: list[str] | None = None,
    goal: str | None = None,
    days_in_stage: int | None = None,
    due_date: date | None = None,
    delivery_date: date | None = None,
    strict: bool = False,
) -> dict[str, Any]:
    """
    Pure table-driven resolver mapping primary stage and context flags into an
    application experience configuration (feature availability, modules, cards, symptoms, rules).

    If primary_stage is missing or invalid:
    - If strict=True, raises ValueError.
    - If strict=False, returns a safe neutral fallback configuration.
    """
    canonical_stage = normalize_stage_name(primary_stage)

    if canonical_stage is None:
        if strict:
            raise ValueError(
                f"Invalid or missing lifecycle stage: {primary_stage!r}. "
                f"Valid stages: {sorted(VALID_CANONICAL_STAGES)}"
            )
        return build_neutral_fallback_config(primary_stage)

    clean_contexts = [
        c.strip().lower() for c in (contexts or []) if c and c.strip().lower() in VALID_CONTEXTS
    ]
    clean_goal = goal.strip().lower() if (goal and goal.strip().lower() in VALID_GOALS) else None

    # Base module defaults
    enabled_modules: dict[str, bool] = {
        "cycle_tracking": False,
        "ovulation_prediction": False,
        "gestation_timeline": False,
        "lochia_logger": False,
        "symptom_logger": True,
        "vasomotor_tracker": False,
        "recovery_checkin": False,
    }

    # Behavioral flags
    behavioral_flags: dict[str, Any] = {
        "cycle_prediction_mode": "disabled",
        "cycle_variance_tolerance": "standard",
        "pregnancy_mode": False,
        "postpartum_mode": False,
    }

    # Dashboard card descriptors
    dashboard_cards: list[dict[str, Any]] = []

    # Symptom catalog
    symptom_catalog: list[dict[str, str]] = []

    # Ask assistant persona grounding
    ask_system_context: str = ""

    # Human-readable why audit trail
    why_factors: list[str] = [f"Primary stage: {STAGE_DISPLAY_NAMES[canonical_stage]}"]

    # -------------------------------------------------------------
    # 1. ADOLESCENCE
    # -------------------------------------------------------------
    if canonical_stage == STAGE_ADOLESCENCE:
        enabled_modules["cycle_tracking"] = True
        enabled_modules["ovulation_prediction"] = False  # Avoid rigid ovulation forecasting for developing cycles
        behavioral_flags["cycle_prediction_mode"] = "active"
        behavioral_flags["cycle_variance_tolerance"] = "expected_variable"

        why_factors.append("Developing hypothalamic-pituitary-ovarian axis: irregular cycles expected")

        symptom_catalog = [
            {"name": "Cramps", "category": "cycle"},
            {"name": "Acne", "category": "physical"},
            {"name": "Mood changes", "category": "mood"},
            {"name": "Headache", "category": "physical"},
            {"name": "Fatigue", "category": "physical"},
        ]
        dashboard_cards = [
            {
                "card_type": "cycle_summary_card",
                "priority": 1,
                "title": "Cycle Overview",
                "subtitle": "Track your periods to discover your natural rhythm.",
                "action_payload": {"route": "/track"},
            },
            {
                "card_type": "stage_guidance_card",
                "priority": 2,
                "title": "Puberty & Cycle Awareness",
                "subtitle": "Cycle lengths frequently vary in the first few years after menarche.",
                "action_payload": {"route": "/learn"},
            },
        ]
        ask_system_context = (
            "User is in Adolescence. Provide reassuring, clear, supportive foundational education. "
            "Emphasize that cycle irregularity is normal during early reproductive development."
        )

    # -------------------------------------------------------------
    # 2. MENSTRUAL HEALTH & REPRODUCTIVE HEALTH
    # -------------------------------------------------------------
    elif canonical_stage in (STAGE_MENSTRUAL_HEALTH, STAGE_REPRODUCTIVE_HEALTH):
        enabled_modules["cycle_tracking"] = True
        enabled_modules["ovulation_prediction"] = True
        behavioral_flags["cycle_prediction_mode"] = "active"

        # Check contraception context
        if "hormonal_contraception" in clean_contexts:
            enabled_modules["ovulation_prediction"] = False
            why_factors.append("Hormonal contraception active: physiological ovulation predictions suppressed")

        # Check irregular cycles context
        if "irregular_cycles" in clean_contexts:
            behavioral_flags["cycle_variance_tolerance"] = "expected_variable"
            why_factors.append("Irregular cycles reported: variance tolerances expanded")

        symptom_catalog = [
            {"name": "Cramps", "category": "cycle"},
            {"name": "Bloating", "category": "physical"},
            {"name": "Headache", "category": "physical"},
            {"name": "Fatigue", "category": "physical"},
            {"name": "Breast tenderness", "category": "physical"},
            {"name": "Mood changes", "category": "mood"},
        ]
        dashboard_cards = [
            {
                "card_type": "cycle_summary_card",
                "priority": 1,
                "title": "Cycle Overview",
                "subtitle": "Track your period and cycle phases.",
                "action_payload": {"route": "/track"},
            },
            {
                "card_type": "daily_checkin_card",
                "priority": 2,
                "title": "Daily Check-in",
                "subtitle": "Log mood and symptoms to understand patterns.",
                "action_payload": {"route": "/checkin"},
            },
        ]
        ask_system_context = (
            "User is in reproductive/menstrual health stage. Offer evidence-based educational insights "
            "on follicular/luteal phases, cycle patterns, and common symptoms."
        )

    # -------------------------------------------------------------
    # 3. PREGNANCY
    # -------------------------------------------------------------
    elif canonical_stage == STAGE_PREGNANCY:
        enabled_modules["cycle_tracking"] = False
        enabled_modules["ovulation_prediction"] = False
        enabled_modules["gestation_timeline"] = True
        behavioral_flags["cycle_prediction_mode"] = "paused"
        behavioral_flags["pregnancy_mode"] = True

        why_factors.append("Pregnancy active: menstrual cycle predictions paused; gestation timeline enabled")

        symptom_catalog = [
            {"name": "Nausea / Morning sickness", "category": "pregnancy"},
            {"name": "Fatigue", "category": "physical"},
            {"name": "Back pain", "category": "physical"},
            {"name": "Heartburn", "category": "physical"},
            {"name": "Frequent urination", "category": "physical"},
            {"name": "Swelling", "category": "physical"},
        ]
        dashboard_cards = [
            {
                "card_type": "gestation_milestone_card",
                "priority": 1,
                "title": "Pregnancy Journey",
                "subtitle": "Monitor your developmental milestones and prenatal well-being.",
                "action_payload": {"due_date": due_date.isoformat() if due_date else None},
            },
            {
                "card_type": "prenatal_guidance_card",
                "priority": 2,
                "title": "Prenatal Wellness",
                "subtitle": "Educational guidance on maternal nutrition, hydration, and rest.",
                "action_payload": {"route": "/learn"},
            },
        ]
        ask_system_context = (
            "User is currently pregnant. Emphasize maternal wellness and developmental awareness. "
            "Period tracking is paused. Never provide obstetrical diagnoses."
        )

    # -------------------------------------------------------------
    # 4. POSTPARTUM
    # -------------------------------------------------------------
    elif canonical_stage == STAGE_POSTPARTUM:
        enabled_modules["cycle_tracking"] = False
        enabled_modules["ovulation_prediction"] = False
        enabled_modules["lochia_logger"] = True
        enabled_modules["recovery_checkin"] = True
        behavioral_flags["cycle_prediction_mode"] = "paused"
        behavioral_flags["postpartum_mode"] = True

        why_factors.append("Postpartum active: recovery tracking active; cycle predictions paused")
        if "breastfeeding" in clean_contexts:
            why_factors.append("Breastfeeding: lactational amenorrhea expected")

        symptom_catalog = [
            {"name": "Lochia discharge", "category": "postpartum"},
            {"name": "Breast engorgement", "category": "postpartum"},
            {"name": "Perineal discomfort", "category": "postpartum"},
            {"name": "Fatigue", "category": "physical"},
            {"name": "Baby blues / Mood shifts", "category": "mood"},
        ]
        dashboard_cards = [
            {
                "card_type": "postpartum_recovery_card",
                "priority": 1,
                "title": "Postpartum Recovery",
                "subtitle": "Track your healing, physical rest, and emotional well-being.",
                "action_payload": {"delivery_date": delivery_date.isoformat() if delivery_date else None},
            },
            {
                "card_type": "daily_checkin_card",
                "priority": 2,
                "title": "Daily Recovery Check-in",
                "subtitle": "Log how you are feeling today.",
                "action_payload": {"route": "/checkin"},
            },
        ]
        ask_system_context = (
            "User is in postpartum recovery. Focus on healing, emotional wellness, lactation, "
            "and gradual recovery principles. Period tracking remains paused."
        )

    # -------------------------------------------------------------
    # 5. PERIMENOPAUSE
    # -------------------------------------------------------------
    elif canonical_stage == STAGE_PERIMENOPAUSE:
        enabled_modules["cycle_tracking"] = True
        enabled_modules["ovulation_prediction"] = False  # Ovulation is sporadic
        enabled_modules["vasomotor_tracker"] = True
        behavioral_flags["cycle_prediction_mode"] = "active"
        behavioral_flags["cycle_variance_tolerance"] = "expected_variable"

        why_factors.append("Perimenopause: fluctuating hormones; cycle length variability expected; vasomotor tracking enabled")

        symptom_catalog = [
            {"name": "Hot flashes", "category": "vasomotor"},
            {"name": "Night sweats", "category": "vasomotor"},
            {"name": "Irregular bleeding", "category": "cycle"},
            {"name": "Sleep disruption", "category": "physical"},
            {"name": "Brain fog", "category": "cognitive"},
            {"name": "Mood changes", "category": "mood"},
        ]
        dashboard_cards = [
            {
                "card_type": "cycle_summary_card",
                "priority": 1,
                "title": "Cycle Variability Tracker",
                "subtitle": "Track cycle shifts and symptom changes during this transition.",
                "action_payload": {"route": "/track"},
            },
            {
                "card_type": "vasomotor_logger_card",
                "priority": 2,
                "title": "Hot Flash & Sleep Tracker",
                "subtitle": "Log thermal surges and rest patterns.",
                "action_payload": {"route": "/checkin"},
            },
        ]
        ask_system_context = (
            "User is in perimenopause. Address cycle length variability as natural physiological transition. "
            "Provide evidence-based guidance on vasomotor symptoms, sleep changes, and hormone fluctuation."
        )

    # -------------------------------------------------------------
    # 6. MENOPAUSE & BEYOND
    # -------------------------------------------------------------
    elif canonical_stage == STAGE_MENOPAUSE:
        enabled_modules["cycle_tracking"] = False
        enabled_modules["ovulation_prediction"] = False
        enabled_modules["vasomotor_tracker"] = True
        behavioral_flags["cycle_prediction_mode"] = "disabled"

        why_factors.append("Menopause confirmed (12+ months amenorrhea): cycle tracking disabled; wellness tracking active")

        symptom_catalog = [
            {"name": "Hot flashes", "category": "vasomotor"},
            {"name": "Night sweats", "category": "vasomotor"},
            {"name": "Vaginal dryness", "category": "physical"},
            {"name": "Joint stiffness", "category": "physical"},
            {"name": "Sleep disruption", "category": "physical"},
        ]
        dashboard_cards = [
            {
                "card_type": "menopause_wellness_card",
                "priority": 1,
                "title": "Long-Term Wellness",
                "subtitle": "Focus on bone density, heart health, and vitality.",
                "action_payload": {"route": "/learn"},
            },
            {
                "card_type": "daily_checkin_card",
                "priority": 2,
                "title": "Daily Wellness Check-in",
                "subtitle": "Log symptoms, sleep, and activity.",
                "action_payload": {"route": "/checkin"},
            },
        ]
        ask_system_context = (
            "User is in post-menopause. Focus on bone vitality, cardiovascular health, "
            "and long-term vitality. Cycle prediction is disabled."
        )

    # Context-specific why additions
    if clean_contexts:
        why_factors.append(f"Context flags: {', '.join(clean_contexts)}")
    if clean_goal:
        why_factors.append(f"Goal: {clean_goal}")

    return {
        "primary_stage": canonical_stage,
        "display_name": STAGE_DISPLAY_NAMES[canonical_stage],
        "is_neutral_fallback": False,
        "active_contexts": clean_contexts,
        "goal": clean_goal,
        "enabled_modules": enabled_modules,
        "behavioral_flags": behavioral_flags,
        "symptom_catalog": symptom_catalog,
        "dashboard_cards": dashboard_cards,
        "ask_system_context": ask_system_context,
        "why": "; ".join(why_factors),
    }
