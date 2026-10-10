import re
from dataclasses import dataclass

INTENT_GENERAL = "GENERAL_INFORMATION"
INTENT_SYMPTOM = "SYMPTOM_INFORMATION"
INTENT_MEDICATION = "MEDICATION / TREATMENT"
INTENT_URGENT = "EMERGENCY / URGENT"
INTENT_DIAGNOSIS = "DIAGNOSIS_REQUEST"
INTENT_GREETING = "GREETING"
INTENT_IDENTITY = "IDENTITY"
INTENT_GENERAL_KNOWLEDGE = "GENERAL_KNOWLEDGE"
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
    # Bleeding emergencies (heavy, severe, profuse, excessive, losing a lot of blood, soaking through)
    r"\b(severe|heavy|profuse|excessive)\s+bleeding\b",
    r"\b(losing|lost)\s+(a\s+lot\s+of|excessive|too\s+much)\s+blood\b",
    r"\bbleeding\s+(a\s+lot|heavily|profusely|excessively)\b",
    r"\bsoaking\s+through\s+(pads?|tampons?)\b",

    # Fainting / Dizziness / Lightheadedness (allowing adverbs like feel extremely/very dizzy)
    r"\b(feel|feeling|felt)\s+.*?\b(faint|dizzy|lightheaded)\b",
    r"\b(fainted|fainting|passed\s+out|passing\s+out|unconscious|unconsciousness|blacked\s+out)\b",

    # Combination: Bleeding + Dizziness/Fainting anywhere in input
    r"\b(bleed|bleeding|blood)\b.*?\b(dizzy|faint|lightheaded)\b",
    r"\b(dizzy|faint|lightheaded)\b.*?\b(bleed|bleeding|blood)\b",

    # Severe Pain
    r"\b(severe|unbearable|excruciating|intense|extreme)\s+.*?\b(pain|cramps?)\b",

    # Respiratory / Chest Pain
    r"\b(chest\s+pain|difficulty\s+breathing|shortness\s+of\s+breath|gasping\s+for\s+air)\b",

    # Seizures / Convulsions
    r"\b(seizure|seizures|convulsions|convulsing)\b",

    # Self-harm / Crisis
    r"\b(suicide|suicidal|kill\s+myself|end\s+my\s+life|self[- ]harm)\b",

    # General Emergency
    r"\b(emergency|ambulance|call\s+911|call\s+999|call\s+112|hemorrhage|hemorrhaging)\b",
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
    r"\bcan i take \d+.*?(ibuprofen|paracetamol|aspirin|naproxen|tylenol|advil|pills|tablets|mg|milligrams)\b",
    r"\bshould i (start|stop|change|take|increase|decrease).*?(medicine|medication|pill|treatment|prescription)\b",
    r"\bwhich (medicine|medication|pill|painkiller) (helps|is best|is safe)\b",
    r"\bprescribe\b",
]

# Greeting patterns
GREETING_PATTERNS = [
    r"^(hi|hello|hey|greetings|howdy|good morning|good afternoon|good evening|thanks|thank you|okay|got it|bye|goodbye|how are you|how s it going)[\!\.\?]*$",
    r"^(hi|hello|hey)\s+(herlife|there|bot)[\!\.\?]*$",
]

# Identity patterns
IDENTITY_PATTERNS = [
    r"\b(who are you|what is your name|what are you|who created you|what can you do|what do you do)\b",
]

# General knowledge / Unrelated patterns
GENERAL_KNOWLEDGE_PATTERNS = [
    r"\b(capital of|who invented|tell me a joke|weather|sports|score|president|prime minister)\b",
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
    Evaluated on EVERY turn before model generation.
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

    # 4. Greeting check
    for pattern in GREETING_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GREETING,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 5. Identity check
    for pattern in IDENTITY_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_IDENTITY,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 6. General knowledge / Unrelated check
    for pattern in GENERAL_KNOWLEDGE_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GENERAL_KNOWLEDGE,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 7. Symptom information check
    for pattern in SYMPTOM_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_SYMPTOM,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 8. General information check
    for pattern in GENERAL_PATTERNS:
        if re.search(pattern, q_lower):
            return SafetyClassification(
                intent=INTENT_GENERAL,
                safety_level=SAFETY_INFORMATIONAL,
                is_safe=True,
            )

    # 9. Fallback
    return SafetyClassification(
        intent=INTENT_UNKNOWN,
        safety_level=SAFETY_INFORMATIONAL,
        is_safe=True,
    )
