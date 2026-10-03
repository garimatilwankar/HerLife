import re
from dataclasses import dataclass

INTENT_GENERAL = "GENERAL_INFORMATION"
INTENT_SYMPTOM = "SYMPTOM_INFORMATION"
INTENT_MEDICATION = "MEDICATION / TREATMENT"
INTENT_URGENT = "EMERGENCY / URGENT"
INTENT_DIAGNOSIS = "DIAGNOSIS_REQUEST"
INTENT_UNKNOWN = "OTHER / UNKNOWN"

SAFETY_INFORMATIONAL = "INFORMATIONAL"
SAFETY_CAUTION = "CAUTION"
SAFETY_URGENT = "URGENT"


@dataclass
class SafetyClassification:
    intent: str
    safety_level: str
    is_safe: bool
    override_answer: str | None = None


# Urgent / Emergency patterns
URGENT_PATTERNS = [
    r"\b(severe|heavy|profuse|excessive)\s+bleeding\b",
    r"\b(feel|feeling)\s+(faint|dizzy|lightheaded)\b",
    r"\b(fainted|fainting|passed out|passing out|unconscious)\b",
    r"\b(severe|unbearable|excruciating)\s+(abdominal|pelvic|stomach|period)\s+pain\b",
    r"\b(chest pain|difficulty breathing|shortness of breath)\b",
    r"\b(emergency|ambulance|call 911|hemorrhage|hemorrhaging)\b",
]

# Diagnosis patterns
DIAGNOSIS_PATTERNS = [
    r"\bdo i have\b",
    r"\bcould i have\b",
    r"\bam i suffering from\b",
    r"\bis it possible i have\b",
    r"\bdiagnose\b",
    r"\bis this (pcos|endometriosis|fibroids|a cyst|an infection|pregnancy|cancer)\b",
    r"\bdo i have (pcos|endometriosis|fibroids|cysts|an infection)\b",
]

# Medication / Treatment patterns
MEDICATION_PATTERNS = [
    r"\bwhat (medicine|medication|drug|pill|painkiller) should i (take|use)\b",
    r"\bwhat (dosage|dose) should i take\b",
    r"\bhow (much|many) (ibuprofen|paracetamol|aspirin|naproxen|tylenol|advil|pills|tablets)\b",
    r"\bshould i (start|stop|change|take|increase|decrease) (my|this|taking)? (medicine|medication|pill|treatment|prescription)\b",
    r"\bwhich (medicine|medication|pill|painkiller) (helps|is best|is safe) for\b",
    r"\bprescribe\b",
]

# Symptom patterns
SYMPTOM_PATTERNS = [
    r"\b(cramp|cramps|cramping|bloating|spotting|fatigue|headache|nausea|breast tenderness|mood swings|discharge|hot flashes|night sweats)\b",
    r"\b(why do i|why am i|reason for)\s+.*(cramps|bleeding|pain|bloating|spotting)\b",
    r"\bperiod pain\b",
]

# General information patterns
GENERAL_PATTERNS = [
    r"\b(how does|how is|what is|explain|understand)\b.*(cycle|period|ovulation|menstruation|puberty|perimenopause|menopause|hormones)\b",
    r"\b(cycle length|normal cycle|phases of)\b",
]


def classify_question(question: str) -> SafetyClassification:
    """
    Deterministically classifies a user question into safety intents and risk levels.
    """
    q_lower = question.lower().strip()

    # 1. Emergency / Urgent check
    for pattern in URGENT_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_URGENT,
                safety_level=SAFETY_URGENT,
                is_safe=False,
                override_answer=(
                    "If you are experiencing severe symptoms such as heavy bleeding, severe pain, or feeling faint, "
                    "please seek immediate emergency medical care or contact a healthcare professional right away."
                ),
            )

    # 2. Diagnosis request check
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
            )

    # 3. Medication / Treatment check
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
            )

    # 4. Symptom information check
    for pattern in SYMPTOM_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_SYMPTOM,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 5. General information check
    for pattern in GENERAL_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GENERAL,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 6. Fallback
    return SafetyClassification(
        intent=INTENT_UNKNOWN,
        safety_level=SAFETY_INFORMATIONAL,
        is_safe=True,
    )
