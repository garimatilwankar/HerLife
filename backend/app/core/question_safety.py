"""
HerLife Deterministic Question Safety & Lifecycle-Aware Triage Engine.

This module evaluates user questions deterministically BEFORE any article retrieval
or language model generation. It enforces medical safety guardrails, detects acute
clinical emergencies (universal and lifecycle-specific), guards against unauthorized
medical diagnosis or prescribing, and provides safe, calm, actionable guidance grounded
in authoritative clinical sources (CDC, ACOG, NHS, WHO).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from typing import Any

from app.core.lifecycle_resolver import (
    STAGE_ADOLESCENCE,
    STAGE_MENOPAUSE,
    STAGE_MENSTRUAL_HEALTH,
    STAGE_PERIMENOPAUSE,
    STAGE_POSTPARTUM,
    STAGE_PREGNANCY,
    STAGE_REPRODUCTIVE_HEALTH,
    STAGE_UNSPECIFIED,
    normalize_stage_name,
)

# Intent classifications
INTENT_GENERAL = "GENERAL_INFORMATION"
INTENT_SYMPTOM = "SYMPTOM_INFORMATION"
INTENT_MEDICATION = "MEDICATION / TREATMENT"
INTENT_URGENT = "EMERGENCY / URGENT"
INTENT_DIAGNOSIS = "DIAGNOSIS_REQUEST"
INTENT_CLINICAL_EVALUATION = "CLINICAL_EVALUATION_RECOMMENDED"
INTENT_GREETING = "GREETING"
INTENT_IDENTITY = "IDENTITY"
INTENT_GENERAL_KNOWLEDGE = "GENERAL_KNOWLEDGE"
INTENT_UNKNOWN = "OTHER / UNKNOWN"

# Safety risk levels
SAFETY_INFORMATIONAL = "INFORMATIONAL"
SAFETY_CAUTION = "CAUTION"
SAFETY_URGENT = "URGENT"


@dataclass
class SafetyClassification:
    intent: str
    safety_level: str
    is_safe: bool
    override_answer: str | None = None
    rule_id: str | None = None
    medical_source: str | None = None


# =============================================================================
# 1. UNIVERSAL URGENT PATTERNS (Applicable across all life stages)
# =============================================================================
UNIVERSAL_URGENT_PATTERNS = [
    # Bleeding emergencies
    (
        "RULE_UNIVERSAL_HEAVY_BLEEDING",
        r"\b(severe|heavy|profuse|excessive)\s+bleeding\b",
        "CDC & ACOG: Acute hemorrhage requires urgent medical evaluation.",
    ),
    (
        "RULE_UNIVERSAL_BLOOD_LOSS",
        r"\b(losing|lost)\s+(a\s+lot\s+of|excessive|too\s+much)\s+blood\b",
        "CDC & ACOG: Excessive blood loss requires urgent medical evaluation.",
    ),
    (
        "RULE_UNIVERSAL_PROFUSE_BLEEDING",
        r"\bbleeding\s+(a\s+lot|heavily|profusely|excessively)\b",
        "CDC & ACOG: Profuse bleeding requires urgent medical evaluation.",
    ),
    (
        "RULE_UNIVERSAL_SOAKING_PADS",
        r"\bsoaking\s+through\s+(pads?|tampons?)\s+(every|each|an)\s+hour\b",
        "ACOG Menorrhagia Guidance: Soaking through pads/tampons an hour warrants urgent evaluation.",
    ),

    # Fainting / Loss of consciousness / Syncope
    (
        "RULE_UNIVERSAL_SYNCOPE",
        r"\b(fainted|fainting|passed\s+out|passing\s+out|unconscious|unconsciousness|blacked\s+out)\b",
        "Emergency clinical triage: Loss of consciousness warrants immediate medical evaluation.",
    ),
    (
        "RULE_UNIVERSAL_BLEEDING_AND_SYNCOPE",
        r"\b(bleed|bleeding|blood)\b.*?\b(dizzy|faint|lightheaded)\b",
        "ACOG & CDC: Bleeding accompanied by dizziness or syncope indicates hemodynamic compromise.",
    ),
    (
        "RULE_UNIVERSAL_SYNCOPE_AND_BLEEDING",
        r"\b(dizzy|faint|lightheaded)\b.*?\b(bleed|bleeding|blood)\b",
        "ACOG & CDC: Bleeding accompanied by dizziness or syncope indicates hemodynamic compromise.",
    ),

    # Severe unbearable pain
    (
        "RULE_UNIVERSAL_SEVERE_PAIN",
        r"\b(severe|unbearable|excruciating|intense|extreme)\s+.*?\b(pain|cramps?)\b",
        "Emergency clinical triage: Acute unbearable pain requires emergency evaluation.",
    ),

    # Respiratory / Cardiopulmonary distress
    (
        "RULE_UNIVERSAL_CHEST_RESPIRATORY",
        r"\b(chest\s+pain|difficulty\s+breathing|shortness\s+of\s+breath|gasping\s+for\s+air)\b",
        "Emergency clinical triage: Chest pain and respiratory distress require emergency care.",
    ),

    # Neurological convulsions
    (
        "RULE_UNIVERSAL_SEIZURE",
        r"\b(seizure|seizures|convulsions|convulsing)\b",
        "Emergency clinical triage: Seizures warrant immediate emergency intervention.",
    ),

    # Self-harm / Crisis
    (
        "RULE_UNIVERSAL_SELF_HARM",
        r"\b(suicide|suicidal|kill\s+myself|end\s+my\s+life|self[- ]harm)\b",
        "SAMHSA 988 / Crisis Guidance: Acute self-harm risk requires immediate crisis support.",
    ),

    # General Emergency terms
    (
        "RULE_UNIVERSAL_EMERGENCY_TERMS",
        r"\b(emergency|ambulance|hemorrhage|hemorrhaging)\b",
        "Emergency clinical triage: Acute emergency declarations require immediate medical attention.",
    ),
]


# =============================================================================
# 2. LIFECYCLE-SPECIFIC RED FLAGS
# =============================================================================

# Pregnancy warning signs (CDC Hear Her & ACOG Practice Bulletin on Preeclampsia)
PREGNANCY_URGENT_PATTERNS = [
    # Preeclampsia: Severe headache with visual changes
    (
        "RULE_PREGNANCY_PREECLAMPSIA_HEADACHE_VISION",
        r"\b(headache|head\s+hurts?)\b.*?\b(blurr(y|ed)|vision|seeing\s+spots|spots|flashing|flashes)\b",
        "CDC Hear Her & ACOG: Severe headache with vision changes in pregnancy suggests preeclampsia.",
    ),
    (
        "RULE_PREGNANCY_PREECLAMPSIA_VISION_HEADACHE",
        r"\b(blurr(y|ed)\s+vision|seeing\s+spots|flashes\s+of\s+light)\b.*?\b(headache|head\s+hurts?)\b",
        "CDC Hear Her & ACOG: Vision changes with headache in pregnancy suggest preeclampsia.",
    ),
    # Preeclampsia: Right upper quadrant / epigastric pain
    (
        "RULE_PREGNANCY_PREECLAMPSIA_RUQ_PAIN",
        r"\b(severe|intense|sharp)\s+.*?\b(upper\s+right|right\s+upper|epigastric)\s+(belly|abdominal|stomach)?\s*pain\b",
        "ACOG Practice Bulletin No. 222: RUQ/epigastric pain in pregnancy is a cardinal sign of severe preeclampsia.",
    ),
    # Obstetric: Rupture of membranes / fluid leaking
    (
        "RULE_PREGNANCY_FLUID_LEAKAGE",
        r"\b(fluid|water|amniotic\s+fluid)\b.*?\b(leaking|leaked|gushing|broke|breaking)\b|\bleaking\s+.*?\b(fluid|water|amniotic)\b",
        "CDC Hear Her & ACOG: Fluid leakage during pregnancy requires prompt obstetric evaluation.",
    ),
    # Obstetric: Decreased or absent fetal movement
    (
        "RULE_PREGNANCY_FETAL_MOVEMENT_DECREASED",
        r"\b(baby|fetus|kicks?|movement)\s+(stopped|not\s+moving|stopped\s+moving|decreased\s+a\s+lot|haven't\s+felt|hasn't\s+moved)\b|\b(haven't\s+felt|not\s+feeling|no)\s+(baby\s+movement|kicks?|the\s+baby\s+kick|the\s+baby\s+move)\b",
        "CDC Hear Her & ACOG: Decreased or absent fetal movement requires immediate fetal assessment.",
    ),
    # Obstetric: Vaginal bleeding during pregnancy
    (
        "RULE_PREGNANCY_VAGINAL_BLEEDING",
        r"\b(bleed|bleeding|blood|spotting)\b",
        "CDC Hear Her & ACOG: Vaginal bleeding during pregnancy warrants immediate clinical triage.",
    ),
]

# Postpartum warning signs (CDC Hear Her & ACOG Postpartum Toolkit)
POSTPARTUM_URGENT_PATTERNS = [
    # Postpartum hemorrhage: soaking >= 1 pad an hour or golf-ball sized clots
    (
        "RULE_POSTPARTUM_HEMORRHAGE_PAD_SOAKING",
        r"\bsoaking\s+(through\s+)?(a|1|one|more\s+than\s+one)\s+(pad|tampon)s?\s+(an|every|per|in\s+an)\s+hour\b|\bsoaking\s+(a|1|one)\s+pad\s+(an|every|each)\s+hour\b",
        "CDC Hear Her & ACOG: Soaking a pad an hour postpartum indicates secondary hemorrhage.",
    ),
    (
        "RULE_POSTPARTUM_HEMORRHAGE_LARGE_CLOTS",
        r"\b(clots?|blood\s+clots?)\s+.*?\b(golf\s*ball|large|huge|lemon|egg)\b|\b(golf\s*ball|large|huge)\s+sized?\s+(clots?|blood\s+clots?)\b",
        "CDC Hear Her & ACOG: Golf-ball sized or larger clots postpartum indicate significant hemorrhage.",
    ),
    # Postpartum fever / chills (independent warning sign per CDC Hear Her & ACOG)
    (
        "RULE_POSTPARTUM_FEVER_CHILLS",
        r"\b(fever|chills|shaking\s+chills|shivering|high\s+temperature|temp(erature)?\s+(of\s+)?(10\d(\.\d+)?|3[89](\.\d+)?))\b",
        "CDC Hear Her & ACOG: Fever of 100.4°F (38°C) or higher or chills postpartum indicates possible endometritis, mastitis, or sepsis.",
    ),
    # Postpartum foul-smelling lochia / discharge
    (
        "RULE_POSTPARTUM_FOUL_DISCHARGE",
        r"\b(foul|smelly|bad|stinky|offensive|rotten)\s+.*?\b(lochia|discharge|vaginal\s+odor|vaginal\s+smell)\b|\b(lochia|discharge)\s+.*?\b(foul|smelly|bad|stinky|smells\s+bad)\b",
        "CDC Hear Her & ACOG: Foul-smelling lochia or discharge postpartum indicates possible uterine infection (endometritis).",
    ),
    # Postpartum thromboembolism (DVT)
    (
        "RULE_POSTPARTUM_DVT",
        r"\b(calf|leg)\b.*?\b(swelling|swollen|pain|painful|red|redness|warm|warmth|tender)\b|\b(swelling|swollen|pain|painful|red|redness|warm|warmth|tender)\b.*?\b(calf|leg)\b",
        "CDC Hear Her & ACOG: Unilateral calf swelling/pain postpartum is a key warning sign of DVT.",
    ),
    # Postpartum preeclampsia & maternal vascular warning signs (CDC Hear Her & ACOG 222)
    (
        "RULE_POSTPARTUM_PREECLAMPSIA",
        r"\b(severe|terrible|bad|worst)\s+headache\b.*?\b(vision|blurr(y|ed)|seeing\s+spots|flashing|spots)\b|\b(blurr(y|ed)\s+vision|seeing\s+spots|flashes\s+of\s+light|vision\s+changes)\b.*?\b(severe|terrible|bad|worst)?\s*(headache|head\s+hurts?)\b",
        "CDC Hear Her Campaign & ACOG Practice Bulletin No. 222: Severe headache with vision changes during the postpartum period (up to 1 year after delivery) is an urgent maternal warning sign indicating preeclampsia, cerebral venous thrombosis, or hypertensive crisis.",
    ),
]

# Infant safety & perinatal mental health patterns (evaluated across all life stages)
INFANT_ACTIVE_INTENT_PATTERN = (
    r"\b("
    r"(want\s+to|going\s+to|plan\s+to|urge\s+to|feel\s+like|trying\s+to|will|thinking\s+about|thoughts?\s+of)\s+(harm|harming|hurt|hurting|kill|killing|shake|shaking|drown|drowning)\s+(my\s+baby|the\s+baby|my\s+infant|the\s+infant|my\s+newborn|the\s+newborn|my\s+child)|"
    r"(kill|killing|shake|shaking|drown|drowning)\s+(my\s+baby|the\s+baby|my\s+infant|the\s+infant|my\s+newborn|the\s+newborn)|"
    r"(harm|harming|hurt|hurting)\s+(my\s+baby|the\s+baby|my\s+infant|the\s+infant|my\s+newborn|the\s+newborn|my\s+child)"
    r")\b"
)

INFANT_INTRUSIVE_THOUGHTS_PATTERN = (
    r"\b("
    r"intrusive\s+thoughts?|"
    r"(scared|terrified|afraid|frightened|worried)\s+(i\s+(might|will)|of|that\s+i)|"
    r"unwanted\s+(thoughts?|images?)|"
    r"distressing\s+thoughts?|"
    r"horrible\s+thoughts?|"
    r"fear\s+of\s+(hurting|harming|dropping)"
    r")\b.*?\b(baby|infant|newborn|child)\b|\b(baby|infant|newborn|child)\b.*?\b("
    r"intrusive\s+thoughts?|"
    r"(scared|terrified|afraid|frightened|worried)\s+(i\s+(might|will)|of|that\s+i)|"
    r"unwanted\s+(thoughts?|images?)|"
    r"distressing\s+thoughts?|"
    r"horrible\s+thoughts?"
    r")\b"
)

ACTIVE_INTENT_INDICATORS = (
    r"\b(want\s+to|going\s+to|plan\s+to|urge\s+to|feel\s+like|trying\s+to|will)\s+(harm|harming|hurt|hurting|kill|killing|shake|shaking|drown|drowning)\b|\b(kill|killing|shake|shaking|drown|drowning)\b"
)

# Menstrual Health / Acute Menorrhagia (ACOG & CDC Menorrhagia Guidelines)
MENSTRUAL_ACUTE_PATTERNS = [
    (
        "RULE_MENSTRUAL_ACUTE_SOAKING_CONSECUTIVE",
        r"\bsoaking\s+(through\s+)?(pads?|tampons?)\s+(every|each)\s+hour\s+(for\s+)?(two|2|\d+)\s+hours\b",
        "ACOG Menorrhagia FAQ: Soaking a pad/tampon every hour for 2+ consecutive hours requires urgent medical care.",
    ),
]

# Postmenopausal bleeding: Acute escalation vs Isolated prompt evaluation
POSTMENOPAUSAL_BLEEDING_PATTERN = r"\b(bleed|bleeding|blood|spotting|pink\s+discharge|brown\s+discharge)\b"
POSTMENOPAUSAL_ACUTE_ESCALATION = r"\b(heavy|severe|profuse|dizzy|faint|unbearable\s+pain|excruciating\s+pain)\b"


# =============================================================================
# 3. DIAGNOSIS & MEDICATION GUARD PATTERNS (Preserved)
# =============================================================================
DIAGNOSIS_PATTERNS = [
    r"\bdo i have\b",
    r"\bcould i have\b",
    r"\bam i suffering from\b",
    r"\bis it possible i have\b",
    r"\bdiagnose\b",
    r"\bis this (pcos|endometriosis|fibroids|a cyst|an infection|pregnancy|cancer)\b",
    r"\bdo i have (pcos|endometriosis|fibroids|cysts|an infection)\b",
]

MEDICATION_PATTERNS = [
    r"\bwhat\s+(medicine|medication|drug|pill|painkiller)\b.*?\bshould\s+i\s+(take|use)\b",
    r"\bwhat\s+(dosage|dose)\b.*?\bshould\s+i\s+(take|use)\b",
    r"\bhow\s+(much|many)\s+.*?\b(ibuprofen|paracetamol|aspirin|naproxen|tylenol|advil|pills|tablets|mg)\b",
    r"\bcan\s+i\s+take\b.*?\b(ibuprofen|paracetamol|aspirin|naproxen|tylenol|advil|pills|tablets|mg|milligrams)\b",
    r"\bshould\s+i\s+(start|stop|change|take|increase|decrease).*?(medicine|medication|pill|treatment|prescription)\b",
    r"\bwhich\s+(medicine|medication|pill|painkiller)\b.*?\b(helps|is\s+best|is\s+safe)\b",
    r"\bprescribe\b",
]

# Greetings
GREETING_PATTERNS = [
    r"^(hi|hello|hey|greetings|howdy|good morning|good afternoon|good evening|thanks|thank you|okay|got it|bye|goodbye|how are you|how s it going)[\!\.\?]*$",
    r"^(hi|hello|hey)\s+(herlife|there|bot)[\!\.\?]*$",
]

# Identity
IDENTITY_PATTERNS = [
    r"\b(who are you|what is your name|what are you|who created you|what can you do|what do you do)\b",
]

# General knowledge / Unrelated
GENERAL_KNOWLEDGE_PATTERNS = [
    r"\b(capital of|who invented|tell me a joke|weather|sports|score|president|prime minister)\b",
]

# Common Symptoms
SYMPTOM_PATTERNS = [
    r"\b(cramp|cramps|cramping|bloating|bloated|spotting|fatigue|tired|exhaustion|headache|nausea|nauseous|breast tenderness|mood swings|discharge|hot flashes|night sweats)\b",
    r"\b(why do i|why am i|reason for)\s+.*(cramps|bleeding|pain|bloating|bloated|spotting|tired)\b",
    r"\bperiod pain\b",
]

# General Cycle Information
GENERAL_PATTERNS = [
    r"\b(how does|how is|what is|explain|understand)\b.*(cycle|period|ovulation|menstruation|puberty|perimenopause|menopause|hormones)\b",
    r"\b(cycle length|normal cycle|phases of)\b",
]


# =============================================================================
# 4. HELPER FUNCTIONS: INTENT & CONTEXT DISCOVERY
# =============================================================================

def is_educational_or_hypothetical_query(q_lower: str) -> bool:
    """
    Detects if the query is an educational, definitional, or hypothetical inquiry
    asking about warning signs in the abstract rather than reporting an acute personal emergency.
    Examples:
      - 'what are pregnancy warning signs?'
      - 'what is preeclampsia?'
      - 'tell me about postpartum hemorrhage'
      - 'can you list danger signs during pregnancy?'
    """
    # Active emergency declarations must NEVER be treated as educational
    active_distress_pattern = (
        r"\b(i('?m|\s+am)\s+(having|experiencing|bleeding|soaking|fainting|dizzy)|"
        r"help\s+me|right\s+now|my\s+blood|my\s+baby\s+stopped|i\s+feel\s+(faint|dizzy)|"
        r"i\s+can('?t|\s+not)\s+breathe|i\s+have\s+severe)\b"
    )
    if re.search(active_distress_pattern, q_lower):
        return False

    educational_structure = (
        r"^(what\s+(is|are|does|means|causes)|tell\s+me\s+about|can\s+you\s+(explain|tell|list)|"
        r"explain|describe|guide\s+to|information\s+about|learn\s+about)\b"
    )
    educational_topic = (
        r"\b(warning\s+signs?|danger\s+signs?|red\s+flags?|symptoms?\s+of|signs?\s+of|"
        r"complications?\s+of|definition\s+of|preeclampsia|postpartum\s+hemorrhage|"
        r"postpartum\s+fever|postpartum\s+infection|postmenopausal\s+bleeding|"
        r"intrusive\s+thoughts|postpartum\s+depression|postpartum\s+anxiety)\b"
    )
    return bool(re.search(educational_structure, q_lower) and re.search(educational_topic, q_lower))


def is_past_or_resolved_symptom(q_lower: str) -> bool:
    """
    Detects if the query describes a resolved, historical symptom rather than an active crisis.
    Examples:
      - 'last month I had severe cramps for an hour but now I'm fine'
      - 'two weeks ago I felt dizzy and lightheaded, is that normal?'
      - 'last year I had heavy bleeding during my period'
    """
    # Active emergency markers override historical phrasing
    active_distress = r"\b(right\s+now|today|currently|still\s+hurts|still\s+bleeding|help\s+me|getting\s+worse)\b"
    if re.search(active_distress, q_lower):
        return False

    past_temporal_marker = (
        r"\b(last\s+(month|year|week|cycle|pregnancy)|weeks\s+ago|months\s+ago|years\s+ago|"
        r"in\s+the\s+past|previously|had\s+in\s+the\s+past)\b"
    )
    resolution_marker = (
        r"\b(now\s+i('?m|\s+am)\s+(fine|okay|better)|it\s+(stopped|went\s+away|resolved)|"
        r"already\s+(stopped|resolved)|is\s+that\s+normal|was\s+that\s+normal)\b"
    )
    return bool(re.search(past_temporal_marker, q_lower) and (
        re.search(resolution_marker, q_lower) or "was that" in q_lower or "is that normal" in q_lower
    ))


def extract_explicit_lifecycle_context(q_lower: str) -> dict[str, bool]:
    """
    Identifies whether the user explicitly declared a lifecycle stage in the question itself.
    Respects negations (e.g., 'I am not pregnant').
    """
    is_negated_pregnancy = bool(re.search(
        r"\b(not|never|neither|n't)\s+(been\s+)?pregnant\b|\bi('?m| am)\s+not\s+pregnant\b",
        q_lower,
    ))
    is_negated_postpartum = bool(re.search(
        r"\b(not|never|n't)\s+(postpartum|had a baby|given birth)\b",
        q_lower,
    ))

    is_pregnant = False
    if not is_negated_pregnancy:
        is_pregnant = bool(re.search(
            r"\b(i('?m| am)\s+(pregnant|\d+\s*weeks?\s+pregnant)|\bmy\s+pregnancy\b|\bduring\s+pregnancy\b|\bpregnant\s+with\b|\btrimester\b)",
            q_lower,
        ))

    is_postpartum = False
    if not is_negated_postpartum:
        is_postpartum = bool(re.search(
            r"\b("
            r"i('?m| am)\s+postpartum|"
            r"postpartum(\s+recovery|\s+period)?|"
            r"(had\s+a\s+baby|gave\s+birth|delivered(\s+a\s+baby)?)(\s+(\d+|a|few|several)?\s*(days?|weeks?|months?|years?)\s*ago)?|"
            r"after\s+(delivery|giving\s+birth|childbirth|birth)|"
            r"post[- ]?(delivery|birth)|"
            r"(\d+|a|few|several|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve)\s+"
            r"(days?|weeks?|months?|years?)\s+"
            r"(postpartum|after\s+(delivery|giving\s+birth|childbirth|birth)|post[- ]?(delivery|birth|baby))|"
            r"(days?|weeks?|months?|years?)\s+postpartum"
            r")\b",
            q_lower,
        ))

    is_menopause = bool(re.search(
        r"\b(after\s+menopause|post[- ]?menopaus(e|al)|past\s+menopause|went\s+through\s+menopause|in\s+menopause|since\s+menopause)\b",
        q_lower,
    ))

    return {
        "pregnant": is_pregnant,
        "postpartum": is_postpartum,
        "menopause": is_menopause,
        "negated_pregnancy": is_negated_pregnancy,
        "negated_postpartum": is_negated_postpartum,
    }


# =============================================================================
# 5. CORE DETERMINISTIC CLASSIFICATION FUNCTION
# =============================================================================

def classify_question(
    question: str,
    lifecycle_stage: str | None = None,
    contexts: list[str] | None = None,
) -> SafetyClassification:
    """
    Deterministically classifies a user question into safety intents and risk levels.
    Evaluated on EVERY turn BEFORE article retrieval or AI model generation.

    Arguments:
      - question: The text of the user's question.
      - lifecycle_stage: Optional user lifecycle stage (canonical identifier or legacy string).
      - contexts: Optional active context flags (e.g., ['breastfeeding']).

    Returns:
      A SafetyClassification object containing intent, safety_level, is_safe,
      optional override_answer, rule_id, and medical_source.
    """
    q_clean = question.strip()
    q_lower = q_clean.lower()
    canonical_user_stage = normalize_stage_name(lifecycle_stage)

    # -------------------------------------------------------------------------
    # STEP 1: Check for Educational / Hypothetical Questions & Past Symptoms
    # Educational inquiries and resolved past symptoms must NOT trigger emergencies.
    # -------------------------------------------------------------------------
    if is_educational_or_hypothetical_query(q_lower):
        return SafetyClassification(
            intent=INTENT_GENERAL,
            safety_level=SAFETY_INFORMATIONAL,
            is_safe=True,
            rule_id="RULE_EDUCATIONAL_QUERY",
            medical_source="Clinical awareness: Educational requests are routed to instructional content.",
        )

    if is_past_or_resolved_symptom(q_lower):
        return SafetyClassification(
            intent=INTENT_SYMPTOM,
            safety_level=SAFETY_INFORMATIONAL,
            is_safe=True,
            rule_id="RULE_PAST_RESOLVED_SYMPTOM",
            medical_source="Clinical awareness: Past resolved symptoms are evaluated for pattern education.",
        )

    # -------------------------------------------------------------------------
    # STEP 2: Extract Explicit Lifecycle Mentions & Resolve Effective Stage
    # Explicit symptom context reported in query overrides unspecified profile.
    # -------------------------------------------------------------------------
    explicit = extract_explicit_lifecycle_context(q_lower)

    # Determine effective stage context for safety evaluation
    effective_is_pregnant = (
        (canonical_user_stage == STAGE_PREGNANCY or explicit["pregnant"])
        and not explicit["negated_pregnancy"]
    )
    effective_is_postpartum = (
        (canonical_user_stage == STAGE_POSTPARTUM or explicit["postpartum"])
        and not explicit["negated_postpartum"]
    )
    effective_is_menopause = (
        canonical_user_stage == STAGE_MENOPAUSE or explicit["menopause"]
    )

    # -------------------------------------------------------------------------
    # STEP 3: Self-Harm & Universal Crisis Check (Highest Priority)
    # -------------------------------------------------------------------------
    for rule_id, pattern, source in UNIVERSAL_URGENT_PATTERNS:
        if rule_id == "RULE_UNIVERSAL_SELF_HARM" and re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_URGENT,
                safety_level=SAFETY_URGENT,
                is_safe=False,
                override_answer=(
                    "If you are having thoughts of self-harm or suicide, please know that support is available right now. "
                    "Reach out immediately to a trusted professional or local crisis services: in the US and Canada, you can "
                    "call or text 988; in the UK, call 111 or 999; in India, call 112 or Tele-MANAS at 14416; or contact your "
                    "nearest emergency department immediately."
                ),
                rule_id=rule_id,
                medical_source=source,
            )

    # Infant safety & perinatal mental health evaluation (evaluated for all users)
    has_intrusive_marker = bool(re.search(INFANT_INTRUSIVE_THOUGHTS_PATTERN, q_lower))
    has_active_intent = bool(re.search(ACTIVE_INTENT_INDICATORS, q_lower))
    has_infant_harm_mention = bool(re.search(INFANT_ACTIVE_INTENT_PATTERN, q_lower))

    if has_intrusive_marker and not has_active_intent:
        # Distressing, unwanted intrusive thoughts without intent to act -> Supportive, non-stigmatizing guidance
        return SafetyClassification(
            intent=INTENT_CLINICAL_EVALUATION,
            safety_level=SAFETY_CAUTION,
            is_safe=True,
            override_answer=(
                "Unwanted, scary, or distressing thoughts about harm coming to your baby (often called intrusive thoughts) are "
                "a common experience for new parents, frequently related to postpartum anxiety or obsessive-compulsive symptoms. "
                "Having these upsetting thoughts is not your fault, does not mean you are a bad parent, and is not the same as an intent to act on them.\n\n"
                "However, coping with these thoughts can be very overwhelming, and supportive help is available:\n"
                "- National Maternal Mental Health Hotline (US): Call or text 1-833-852-6262 (1-833-TLC-MAMA) — free, confidential, 24/7 support in English and Spanish.\n"
                "- Postpartum Support International (PSI): Call or text 1-800-944-4773 for perinatal mental health support and local provider connections.\n"
                "- In the UK: Contact your GP, health visitor, or call NHS 111 (or PANDAS Foundation at 0808 1961 776).\n"
                "- In India: Contact Tele-MANAS at 14416 or your healthcare provider.\n\n"
                "We strongly encourage you to reach out to your doctor, midwife, or a mental health professional who specializes in perinatal care. "
                "If your thoughts ever change into an urge or intention to act, or if you feel you cannot keep your baby safe, please place your baby safely in their crib and call 988 or emergency services immediately."
            ),
            rule_id="RULE_POSTPARTUM_INTRUSIVE_THOUGHTS",
            medical_source=(
                "Postpartum Support International & ACOG Clinical Practice Guideline No. 4: "
                "Unwanted, distressing intrusive thoughts without intent to harm are common in perinatal anxiety/OCD "
                "and require compassionate clinical support and specialized perinatal mental health care."
            ),
        )

    if has_infant_harm_mention or (has_intrusive_marker and has_active_intent):
        # Active intent, urge to act, or ambiguous harm statements -> Emergency crisis intervention
        return SafetyClassification(
            intent=INTENT_URGENT,
            safety_level=SAFETY_URGENT,
            is_safe=False,
            override_answer=(
                "If you are experiencing thoughts or urges to harm your baby, or if you or your baby are in immediate danger, "
                "please know that compassionate, confidential support is available right now. Please place your baby safely in "
                "their crib or bassinet and reach out immediately for help:\n"
                "- In the US: Call or text 988 to reach the Suicide & Crisis Lifeline, or call the National Maternal Mental Health Hotline at 1-833-852-6262 (1-833-TLC-MAMA) for free, 24/7 confidential support.\n"
                "- In the UK: Call 111 or 999 for immediate crisis support.\n"
                "- In India: Call 112 (national emergency) or Tele-MANAS at 14416.\n"
                "- In Canada: Call or text 988.\n"
                "- Or go to the nearest emergency department immediately."
            ),
            rule_id="RULE_CRISIS_INFANT_INTENT",
            medical_source=(
                "ACOG Clinical Practice Guideline No. 4 & SAMHSA: "
                "Thoughts, urges, or immediate intent to harm an infant require emergency crisis intervention."
            ),
        )

    # -------------------------------------------------------------------------
    # STEP 4: Stage-Specific Acute Emergencies (Pregnancy & Postpartum)
    # -------------------------------------------------------------------------
    if effective_is_pregnant:
        for rule_id, pattern, source in PREGNANCY_URGENT_PATTERNS:
            if re.search(pattern, q_lower):
                return SafetyClassification(
                    intent=INTENT_URGENT,
                    safety_level=SAFETY_URGENT,
                    is_safe=False,
                    override_answer=(
                        "If you are pregnant and experiencing potential warning signs—such as leaking fluid, changes in "
                        "your baby's movement, vaginal bleeding, severe headache with vision changes, or severe belly pain—"
                        "please seek immediate emergency medical evaluation or contact your obstetrician, maternity assessment unit, "
                        "or nearest emergency department right away."
                    ),
                    rule_id=rule_id,
                    medical_source=source,
                )

    if effective_is_postpartum:
        for rule_id, pattern, source in POSTPARTUM_URGENT_PATTERNS:
            if re.search(pattern, q_lower):
                return SafetyClassification(
                    intent=INTENT_URGENT,
                    safety_level=SAFETY_URGENT,
                    is_safe=False,
                    override_answer=(
                        "If you have recently given birth and are experiencing warning signs—such as soaking through a pad an hour, "
                        "passing large golf-ball-sized clots, fever or chills, foul-smelling discharge, unilateral calf pain or swelling, "
                        "or severe headache with vision changes—please seek immediate emergency medical care, go to the nearest emergency "
                        "department, or contact your maternity care team right away."
                    ),
                    rule_id=rule_id,
                    medical_source=source,
                )

    # -------------------------------------------------------------------------
    # STEP 5: Menopause / Postmenopausal Bleeding Evaluation
    # Refinement 2: Distinguish prompt clinical evaluation from immediate emergency.
    # -------------------------------------------------------------------------
    if effective_is_menopause and re.search(POSTMENOPAUSAL_BLEEDING_PATTERN, q_lower):
        # Check if accompanied by acute red flags (heavy bleeding, dizzy/faint, severe pain)
        if re.search(POSTMENOPAUSAL_ACUTE_ESCALATION, q_lower):
            return SafetyClassification(
                intent=INTENT_URGENT,
                safety_level=SAFETY_URGENT,
                is_safe=False,
                override_answer=(
                    "Any vaginal bleeding occurring after menopause requires clinical evaluation. Because you are experiencing "
                    "severe symptoms (such as heavy bleeding, severe pain, dizziness, or feeling faint), please seek immediate emergency "
                    "medical care at the nearest emergency department right away."
                ),
                rule_id="RULE_MENOPAUSE_BLEEDING_ACUTE",
                medical_source="ACOG Committee Opinion No. 734: Acute postmenopausal hemorrhage requires emergency triage.",
            )
        else:
            # Isolated postmenopausal spotting / bleeding -> Prompt clinical evaluation (SAFETY_CAUTION)
            return SafetyClassification(
                intent=INTENT_CLINICAL_EVALUATION,
                safety_level=SAFETY_CAUTION,
                is_safe=True,
                override_answer=(
                    "Any vaginal bleeding, spotting, or unusual discharge occurring after menopause (12 or more consecutive months "
                    "without a period) is unexpected and should be evaluated promptly by a gynecologist or healthcare provider. "
                    "While many causes are benign (such as vaginal or endometrial atrophy, or benign polyps), clinical evaluation "
                    "(such as an ultrasound or biopsy) is essential to determine the cause. If bleeding becomes heavy, or if you also experience "
                    "dizziness, feeling faint, or severe pelvic pain, seek immediate emergency medical care."
                ),
                rule_id="RULE_MENOPAUSE_BLEEDING_ISOLATED",
                medical_source=(
                    "ACOG Committee Opinion No. 734 & NHS Guidance: All postmenopausal bleeding requires prompt clinical "
                    "investigation by a physician to rule out endometrial hyperplasia or carcinoma."
                ),
            )

    # -------------------------------------------------------------------------
    # STEP 6: Menstrual Acute Hemorrhage Check
    # -------------------------------------------------------------------------
    for rule_id, pattern, source in MENSTRUAL_ACUTE_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_URGENT,
                safety_level=SAFETY_URGENT,
                is_safe=False,
                override_answer=(
                    "Soaking through a sanitary pad or tampon every hour for two or more consecutive hours is a sign of acute "
                    "menorrhagia. Please seek prompt emergency medical care or visit the nearest emergency department right away, "
                    "especially if you also feel dizzy, weak, or short of breath."
                ),
                rule_id=rule_id,
                medical_source=source,
            )

    # -------------------------------------------------------------------------
    # STEP 7: Universal Urgent Check (Remaining universal emergency rules)
    # -------------------------------------------------------------------------
    for rule_id, pattern, source in UNIVERSAL_URGENT_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_URGENT,
                safety_level=SAFETY_URGENT,
                is_safe=False,
                override_answer=(
                    "If you are experiencing severe symptoms such as heavy bleeding, unbearable pain, difficulty breathing, "
                    "or feeling faint, please seek immediate emergency medical care, go to the nearest emergency department, "
                    "or contact your local emergency services right away."
                ),
                rule_id=rule_id,
                medical_source=source,
            )

    # -------------------------------------------------------------------------
    # STEP 8: Diagnosis Guardrail Check (Preserved)
    # -------------------------------------------------------------------------
    for pattern in DIAGNOSIS_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_DIAGNOSIS,
                safety_level=SAFETY_CAUTION,
                is_safe=True,
                override_answer=(
                    "HerLife provides general educational information and cannot diagnose medical conditions. "
                    "If you suspect you may have a health condition, please consult a qualified healthcare provider for a professional evaluation."
                ),
                rule_id="RULE_DIAGNOSIS_GUARD",
                medical_source="ACOG / Clinical Ethics: Automated applications cannot perform differential diagnosis.",
            )

    # -------------------------------------------------------------------------
    # STEP 9: Medication / Prescription Guardrail Check (Preserved)
    # -------------------------------------------------------------------------
    for pattern in MEDICATION_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_MEDICATION,
                safety_level=SAFETY_CAUTION,
                is_safe=True,
                override_answer=(
                    "HerLife does not prescribe medications, recommend dosages, or advise starting or stopping treatments. "
                    "Please consult a doctor or pharmacist for guidance on medications appropriate for you."
                ),
                rule_id="RULE_MEDICATION_GUARD",
                medical_source="Pharmacy & Clinical Ethics: Medication dosing requires licensed clinical oversight.",
            )

    # -------------------------------------------------------------------------
    # STEP 10: Conversational / Informational Routing
    # -------------------------------------------------------------------------
    for pattern in GREETING_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GREETING,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    for pattern in IDENTITY_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_IDENTITY,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    for pattern in GENERAL_KNOWLEDGE_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GENERAL_KNOWLEDGE,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    for pattern in SYMPTOM_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_SYMPTOM,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    for pattern in GENERAL_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GENERAL,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # Neutral fallback for unclassified questions
    return SafetyClassification(
        intent=INTENT_UNKNOWN,
        safety_level=SAFETY_INFORMATIONAL,
        is_safe=True,
    )
