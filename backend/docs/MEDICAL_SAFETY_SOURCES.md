# HerLife Medical Safety Sources & Clinical Guidance Documentation

This document records the authoritative medical sources, publishing organizations, clinical guidance, trigger criteria, and scope boundaries for all deterministic safety rules implemented in HerLife.

---

## 1. Guiding Principles & Scope Boundaries

1. **Educational Awareness vs. Medical Diagnosis**:
   HerLife is an educational and cycle-tracking application designed to foster health awareness and body literacy. It does **not** provide medical diagnoses, treatment plans, triage decisions, or prescription recommendations.
2. **Deterministic Pre-Generation Safety**:
   All safety rules are evaluated deterministically **before** database retrieval and large language model (AI) generation. Urgent clinical emergencies bypass both article retrieval and AI processing entirely.
3. **Graduated Guidance (Immediate Emergency vs. Prompt Clinical Evaluation)**:
   Not all clinical concerns represent immediate emergency room emergencies. Situations involving acute threats to life or stability are classified as immediate emergencies (`SAFETY_URGENT`), while unexpected symptoms that require diagnostic investigation without acute instability (such as isolated postmenopausal spotting) are classified as requiring prompt clinical evaluation (`SAFETY_CAUTION`).
4. **Verified Guidance Over Guesswork**:
   No clinical thresholds, emergency numbers, or pharmacological advice are invented. Where established regional resources exist, standard services (such as emergency services or maternity units) are recommended.

---

## 2. Authoritative Clinical Sources & Implemented Rules

### A. Pregnancy Emergencies & Preeclampsia Red Flags
- **Publishing Organization**: Centers for Disease Control and Prevention (CDC) & American College of Obstetricians and Gynecologists (ACOG).
- **Source Documents**:
  - CDC "Hear Her" Campaign: *Urgent Maternal Warning Signs*.  
    URL: https://www.cdc.gov/hearher/maternal-warning-signs/index.html
  - ACOG Practice Guideline / Clinical Practice Bulletin: *Gestational Hypertension and Preeclampsia*.  
    URL: https://www.acog.org/clinical/clinical-guidance/practice-bulletin/articles/2020/06/gestational-hypertension-and-preeclampsia
- **Clinical Recommendations**:
  - Cardinal signs of severe preeclampsia / eclampsia include persistent severe headache with visual disturbances (blurriness, spots, flashing lights), and severe epigastric or right upper quadrant abdominal pain.
  - Obstetric emergencies requiring immediate evaluation include leaking of amniotic fluid, vaginal bleeding, and marked decrease or cessation of fetal movement.
- **Implemented Rules in HerLife**:
  - `RULE_PREGNANCY_PREECLAMPSIA`: Severe headache paired with visual changes or sudden facial swelling.
  - `RULE_PREGNANCY_OBSTETRIC_EMERGENCY`: Fluid leakage / rupture of membranes, decreased or absent fetal movement, or active vaginal bleeding during pregnancy.
- **Safety Level**: `SAFETY_URGENT`.
- **Response Directive**: Immediate emergency obstetric care, maternity assessment unit, or nearest emergency services.

---

### B. Postpartum Hemorrhage, Infections, Thromboembolism & Vascular Complications
- **Publishing Organizations**: Centers for Disease Control and Prevention (CDC) & American College of Obstetricians and Gynecologists (ACOG).
- **Source Documents**:
  - CDC "Hear Her" Campaign: *Urgent Maternal Warning Signs (Postpartum)*.  
    URL: https://www.cdc.gov/hearher/maternal-warning-signs/index.html
  - ACOG Postpartum Toolkit & Maternal Safety Bundles: *Optimizing Postpartum Care* (Committee Opinion No. 736).  
    URL: https://www.acog.org/clinical/clinical-guidance/committee-opinion/articles/2018/05/optimizing-postpartum-care
  - ACOG Practice Bulletin No. 222: *Gestational Hypertension and Preeclampsia* (June 2020).  
    URL: https://www.acog.org/clinical/clinical-guidance/practice-bulletin/articles/2020/06/gestational-hypertension-and-preeclampsia
- **Clinical Recommendations & Timing Distinctions**:
  - **Maternal Warning Signs Timeframe**: Per the CDC "Hear Her" campaign, urgent maternal warning signs can occur during pregnancy and **in the year after delivery (up to 12 months postpartum)**. More than half of maternal pregnancy-related deaths occur postpartum, and over one-third occur beyond the first week postpartum.
  - **Preeclampsia vs. Broader Vascular Risks**: While ACOG Practice Bulletin No. 222 notes that classic delayed-onset postpartum preeclampsia typically presents within the first 6 weeks, postpartum cerebrovascular complications (such as cerebral venous sinus thrombosis, reversible cerebral vasoconstriction syndrome / RCVS, intracranial hemorrhage, and postpartum stroke) remain significantly elevated across the first postpartum year. Therefore, severe persistent headaches paired with visual disturbances are treated as urgent red flags throughout the postpartum year and are not dismissed at 6 weeks.
  - **Postpartum Infection & Sepsis**: Fever of $100.4^\circ\text{F}$ ($38^\circ\text{C}$) or higher, or chills (including shaking chills), is an independent warning sign indicating potential endometritis, mastitis, incision infection, urinary tract infection, or systemic sepsis. Foul-smelling lochia/discharge is a separate cardinal sign of uterine infection (endometritis) and does not need to co-occur with fever to warrant urgent evaluation.
  - **Postpartum Hemorrhage**: Soaking through one or more sanitary pads in an hour, or passing blood clots the size of a golf ball or larger.
  - **Deep Vein Thrombosis (DVT)**: Unilateral calf pain, redness, warmth, or swelling.
- **Implemented Rules in HerLife**:
  - `RULE_POSTPARTUM_HEMORRHAGE_PAD_SOAKING`: Soaking $\ge 1$ pad/hour postpartum.
  - `RULE_POSTPARTUM_HEMORRHAGE_LARGE_CLOTS`: Passing golf-ball-sized clots postpartum.
  - `RULE_POSTPARTUM_FEVER_CHILLS`: Fever $\ge 100.4^\circ\text{F}$ ($38^\circ\text{C}$) or chills/shivering postpartum (evaluated independently of lochia odor).
  - `RULE_POSTPARTUM_FOUL_DISCHARGE`: Foul-smelling lochia or vaginal discharge postpartum (evaluated independently of fever).
  - `RULE_POSTPARTUM_DVT`: Unilateral calf pain/swelling/redness after delivery.
  - `RULE_POSTPARTUM_PREECLAMPSIA`: Severe headache combined with visual changes during the postpartum period (up to 1 year).
- **Safety Level**: `SAFETY_URGENT`.
- **Response Directive**: Immediate emergency department or urgent maternal care evaluation.

---

### C. Postmenopausal Bleeding (Prompt Clinical Evaluation)
- **Publishing Organization**: American College of Obstetricians and Gynecologists (ACOG) & National Health Service (NHS).
- **Source Documents**:
  - ACOG Committee Opinion No. 734: *The Role of Transvaginal Ultrasonography in Evaluating the Endometrium of Women With Postmenopausal Bleeding* (Reaffirmed 2021).  
    URL: https://www.acog.org/clinical/clinical-guidance/committee-opinion/articles/2018/05/the-role-of-transvaginal-ultrasonography-in-evaluating-the-endometrium-of-women-with-postmenopausal-bleeding
  - NHS Clinical Overview: *Post-menopausal bleeding*.  
    URL: https://www.nhs.uk/conditions/post-menopausal-bleeding/
- **Clinical Recommendations**:
  - Any vaginal bleeding occurring 12 or more months after the final menstrual period is unexpected.
  - Approximately 90% of cases are caused by benign conditions (e.g., endometrial atrophy, polyps, cervical changes), but approximately 10% are associated with endometrial carcinoma or hyperplasia.
  - Therefore, **all postmenopausal bleeding requires prompt clinical investigation by a healthcare provider (such as pelvic ultrasound and/or endometrial biopsy)**. It is **not** an immediate ambulance emergency unless accompanied by hemodynamic instability or severe pain, but must never be ignored.
- **Implemented Rules in HerLife**:
  - `RULE_MENOPAUSE_BLEEDING_ISOLATED`: Spotting, discharge, or light bleeding after menopause without acute instability.
    - Safety Level: `SAFETY_CAUTION`.
    - Guidance: Clearly communicates that postmenopausal bleeding is unexpected, explains benign vs. endometrial investigation reasons calmly, and directs the user to schedule a prompt appointment with their gynecologist or doctor.
  - `RULE_MENOPAUSE_BLEEDING_ACUTE`: Postmenopausal bleeding accompanied by severe pelvic pain, dizziness, fainting, or heavy hemorrhage.
    - Safety Level: `SAFETY_URGENT`.
    - Guidance: Immediate emergency medical care.

---

### D. Acute Menorrhagia & Severe Gynecologic Pain
- **Publishing Organization**: Centers for Disease Control and Prevention (CDC) & American College of Obstetricians and Gynecologists (ACOG).
- **Source Documents**:
  - CDC: *Heavy Menstrual Bleeding (Menorrhagia)*.  
    URL: https://www.cdc.gov/ncbddd/blooddisorders/women/menorrhagia.html
  - ACOG FAQ: *Heavy Menstrual Bleeding*.  
    URL: https://www.acog.org/womens-health/faqs/heavy-menstrual-bleeding
- **Clinical Recommendations**:
  - Menorrhagia requiring urgent evaluation: Soaking through a pad or tampon every hour for two or more consecutive hours; bleeding accompanied by dizziness, shortness of breath, or feeling faint (signs of acute anemia/hypovolemia).
  - Sudden, severe, sharp, or unbearable pelvic pain (rule out ovarian torsion, ruptured ectopic pregnancy, or pelvic infection).
- **Implemented Rules in HerLife**:
  - `RULE_MENSTRUAL_ACUTE_SOAKING_CONSECUTIVE`: Soaking pads/tampons every hour for 2+ consecutive hours.
  - `RULE_UNIVERSAL_BLEEDING_AND_SYNCOPE`: Bleeding with dizziness/fainting.
  - `RULE_UNIVERSAL_SEVERE_PAIN`: Unbearable, agonizing, or severe sudden pelvic pain.
- **Safety Level**: `SAFETY_URGENT`.

---

### E. Universal Emergencies, Crisis Support & Perinatal Mental Health
- **Publishing Organizations**:
  - Substance Abuse and Mental Health Services Administration (SAMHSA) / 988 Suicide & Crisis Lifeline.  
    URL: https://988lifeline.org/
  - Health Resources and Services Administration (HRSA) / National Maternal Mental Health Hotline.  
    URL: https://mchb.hrsa.gov/national-maternal-mental-health-hotline
  - Postpartum Support International (PSI).  
    URL: https://www.postpartum.net/
  - ACOG Clinical Practice Guideline No. 4: *Screening and Diagnosis of Mental Health Conditions During Pregnancy and Postpartum* (June 2023).  
    URL: https://www.acog.org/clinical/clinical-guidance/clinical-practice-guideline/articles/2023/06/screening-and-diagnosis-of-mental-health-conditions-during-pregnancy-and-postpartum
  - World Health Organization (WHO) & National Health Service (NHS).
- **Clinical Recommendations & Verified Contact Details**:
  - **Universal Acute Emergencies**: Immediate emergency dispatch for cardiopulmonary distress, loss of consciousness, convulsions, or active suicidal crisis.
    - Verified contact: Call or text **988** (US/Canada); call **111** or **999** (UK); call **112** or Tele-MANAS at **14416** (India).
  - **Infant Harm Intent & Crisis**: Immediate crisis intervention when there is an active urge, intent, or danger of harming an infant.
    - Verified contact: Call or text **988** (Suicide & Crisis Lifeline); call **1-833-852-6262** (1-833-TLC-MAMA, US National Maternal Mental Health Hotline); call **111** / **999** (UK); call **112** / **14416** (India).
    - Directive: Place baby safely in crib/bassinet and contact emergency services or trusted support immediately.
  - **Unwanted Intrusive Thoughts (Perinatal OCD / Anxiety)**:
    - Per ACOG and Postpartum Support International (PSI), up to 70–90% of postpartum women experience unwanted, frightening, and intrusive thoughts of harm coming to their baby (e.g., accidental harm, dropping, or taboo thoughts).
    - These thoughts are ego-dystonic (deeply distressing to the parent), do **not** reflect psychotic processes or intent to act, and are distinct from postpartum psychosis.
    - Punitive or accusatory responses induce severe shame and barrier to care. Appropriate clinical management provides compassionate reassurance that intrusive thoughts are common in postpartum anxiety and OCD, offers warm line support, strongly encourages discussion with a perinatal mental health specialist, and provides clear emergency boundaries if urges or loss of safety control should ever arise.
    - Verified contact: National Maternal Mental Health Hotline (**1-833-852-6262**, 24/7 free/confidential in English and Spanish); Postpartum Support International (**1-800-944-4773**, call or text "HELP"); UK NHS **111** / PANDAS Foundation (**0808 1961 776**); India Tele-MANAS (**14416**).
- **Implemented Rules in HerLife**:
  - `RULE_UNIVERSAL_SELF_HARM`: Acute suicide / self-harm thoughts (`SAFETY_URGENT`).
  - `RULE_CRISIS_INFANT_INTENT`: Thoughts, urges, or intent to harm an infant (`SAFETY_URGENT`).
  - `RULE_POSTPARTUM_INTRUSIVE_THOUGHTS`: Unwanted, distressing intrusive thoughts without intent to act (`SAFETY_CAUTION`).
  - Universal rules for chest pain, dyspnea, seizures, and fainting/syncope (`SAFETY_URGENT`).

---

## 3. Disclaimers & Limitations

1. **No Algorithmic Diagnosis**: Pattern matching serves exclusively to safeguard users from delays in seeking care when experiencing red-flag symptoms.
2. **Contextual Evaluation**: Explicit symptom context reported by the user overrides missing or legacy lifecycle stage labels.
3. **Negations and Hypotheticals**: Educational questions (e.g., *"What are warning signs in pregnancy?"*, *"What causes postpartum fever?"*, *"What are postpartum intrusive thoughts?"*) and negations (e.g., *"I am not pregnant"*, *"Not postpartum"*) are classified as informational queries to allow educational content retrieval without triggering false alarms.
