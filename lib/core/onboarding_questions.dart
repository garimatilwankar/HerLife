/// The 14 personalisation questions asked after sign up.
/// Edit the wording or options here. The screen reads this list.

enum QType { single, multi, date }

class OnboardingQuestion {
  final String id;
  final String title;
  final QType type;
  final List<String> options;

  /// Options that cannot be combined with others (for example "None").
  final List<String> exclusive;

  /// Return true to hide this question for the answers given so far.
  final bool Function(Map<String, dynamic> answers)? hideWhen;

  const OnboardingQuestion({
    required this.id,
    required this.title,
    required this.type,
    this.options = const [],
    this.exclusive = const [],
    this.hideWhen,
  });
}

/// Periods have stopped or never started, so cycle questions do not apply.
bool _noPeriods(Map<String, dynamic> a) {
  final v = a['cycle_now'];
  return v == 'No, they have stopped' || v == 'I have never menstruated';
}

final List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    id: 'life_stage',
    title: 'Which best describes your current reproductive life stage?',
    type: QType.single,
    options: [
      'Menstruation',
      'Reproductive years (not currently menstruating)',
      'Pregnancy',
      'Postpartum',
      'Perimenopause',
      'Menopause',
      'Postmenopause',
      "I'm not sure",
    ],
  ),
  OnboardingQuestion(
    id: 'cycle_now',
    title: 'Are you currently experiencing menstrual cycles?',
    type: QType.single,
    options: [
      'Yes, regularly',
      'Yes, but irregularly',
      'No, they have stopped',
      'I have never menstruated',
      'Not sure',
    ],
  ),
  OnboardingQuestion(
    id: 'conditions',
    title: 'Do you have any known reproductive health conditions?',
    type: QType.multi,
    options: [
      'PCOS / PCOD',
      'Endometriosis',
      'Thyroid disorder',
      'Uterine fibroids',
      'Adenomyosis',
      'None',
      'Other',
      'Prefer not to say',
    ],
    exclusive: ['None', 'Prefer not to say'],
  ),
  OnboardingQuestion(
    id: 'hormonal',
    title: 'Are you currently taking hormonal medication or contraception?',
    type: QType.single,
    options: ['Yes', 'No', 'Not sure', 'Prefer not to say'],
  ),
  OnboardingQuestion(
    id: 'cycle_length',
    title: 'How long is your average menstrual cycle?',
    type: QType.single,
    options: [
      '21-24 days',
      '25-28 days',
      '29-32 days',
      '33+ days',
      "It varies / I'm not sure",
    ],
    hideWhen: _noPeriods,
  ),
  OnboardingQuestion(
    id: 'period_length',
    title: 'How many days does your period usually last?',
    type: QType.single,
    options: [
      '1-3 days',
      '4-5 days',
      '6-7 days',
      'More than 7 days',
      'Not sure',
    ],
    hideWhen: _noPeriods,
  ),
  OnboardingQuestion(
    id: 'symptoms',
    title: 'What symptoms do you usually experience?',
    type: QType.multi,
    options: [
      'Cramps',
      'Bloating',
      'Headaches',
      'Acne',
      'Fatigue',
      'Mood changes',
      'Breast tenderness',
      'Back pain',
      'Heavy bleeding',
      'None',
    ],
    exclusive: ['None'],
  ),
  OnboardingQuestion(
    id: 'last_period',
    title: 'When was your last period?',
    type: QType.date,
    hideWhen: _noPeriods,
  ),
  OnboardingQuestion(
    id: 'activity_level',
    title: 'How active are you during the day?',
    type: QType.single,
    options: [
      'Mostly sitting',
      'Lightly active',
      'Moderately active',
      'Very active',
    ],
  ),
  OnboardingQuestion(
    id: 'activities',
    title: 'What type of physical activity do you enjoy?',
    type: QType.multi,
    options: [
      'Walking',
      'Yoga',
      'Gym / Strength training',
      'Dance',
      'Running',
      'Sports',
      'Cycling',
      'None currently',
    ],
    exclusive: ['None currently'],
  ),
  OnboardingQuestion(
    id: 'sleep',
    title: 'How many hours do you usually sleep?',
    type: QType.single,
    options: ['Less than 5 hours', '5-6 hours', '7-8 hours', '9+ hours'],
  ),
  OnboardingQuestion(
    id: 'stress',
    title: 'How would you describe your stress levels?',
    type: QType.single,
    options: ['Low', 'Moderate', 'High', 'Not sure'],
  ),
  OnboardingQuestion(
    id: 'goals',
    title: 'What are your primary wellness goals?',
    type: QType.multi,
    options: [
      'Understand my menstrual cycle',
      'Manage PCOS / PCOD',
      'Improve hormonal health awareness',
      'Manage stress and anxiety',
      'Improve sleep',
      'Improve fitness',
      'Understand menopause',
      'Track symptoms and patterns',
      'Learn about reproductive health',
      'Improve nutrition',
    ],
  ),
  OnboardingQuestion(
    id: 'focus',
    title: 'What would you like HerLife to help you with most?',
    type: QType.single,
    options: [
      'Tracking and monitoring',
      'Learning and education',
      'Understanding health patterns',
      'Building healthy habits',
      'A combination of everything',
    ],
  ),
];

/// The questions that apply for the answers given so far.
List<OnboardingQuestion> visibleQuestions(Map<String, dynamic> answers) =>
    onboardingQuestions.where((q) => q.hideWhen?.call(answers) != true).toList();