import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const HerLifeApp());
}

class HerLifeApp extends StatelessWidget {
  const HerLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HerLife',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE56B8A)),
        fontFamily: 'sans',
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              const Text(
                'HerLife',
                style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              const Text(
                'Your health, through every stage of life.',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 14),

              Text(
                'Track your health, understand your patterns, '
                'and access trusted information — all in one place.',
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey.shade700,
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LifecycleScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Getting Started')),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            const Text(
              'Let’s get to know you.',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            const Text(
              'What should we call you?',
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 24),

            TextField(
              decoration: InputDecoration(
                labelText: 'Your name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Continue', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LifecycleScreen extends StatefulWidget {
  const LifecycleScreen({super.key});

  @override
  State<LifecycleScreen> createState() => _LifecycleScreenState();
}

class _LifecycleScreenState extends State<LifecycleScreen> {
  String? selectedStage;

  final stages = [
    'Adolescence',
    'Menstruation',
    'Reproductive Health',
    'Pregnancy',
    'Postpartum',
    'Perimenopause',
    'Menopause',
  ];

  @override
  void initState() {
    super.initState();
    _loadLifecycleStage();
  }

  Future<void> _loadLifecycleStage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStage = prefs.getString('lifecycle_stage');

    if (!mounted) return;

    setState(() {
      selectedStage = savedStage;
    });
  }

  Future<void> _saveLifecycleStage() async {
    if (selectedStage == null) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'lifecycle_stage',
      selectedStage!,
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MainNavigation(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Health Stage'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Which stage best describes you?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'This helps HerLife provide more relevant information.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 24),

            Expanded(
              child: ListView.builder(
                itemCount: stages.length,
                itemBuilder: (context, index) {
                  final stage = stages[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: RadioListTile<String>(
                      title: Text(stage),
                      value: stage,
                      groupValue: selectedStage,
                      onChanged: (value) {
                        setState(() {
                          selectedStage = value;
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed:
                    selectedStage == null ? null : _saveLifecycleStage,
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DateTime? periodStart;
  List<String> symptoms = [];
  String? mood;
  List<String> checkInSymptoms = [];
  String? lifecycleStage;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString('period_start');
    final savedSymptoms = prefs.getStringList('symptoms') ?? [];

    final savedMood = prefs.getString('checkin_mood');
    final savedCheckInSymptoms =
        prefs.getStringList('checkin_symptoms') ?? [];

    final savedLifecycleStage =
        prefs.getString('lifecycle_stage');

    if (!mounted) return;

    setState(() {
      if (savedDate != null) {
        periodStart = DateTime.tryParse(savedDate);
      }

      symptoms = savedSymptoms;
      mood = savedMood;
      checkInSymptoms = savedCheckInSymptoms;
      lifecycleStage = savedLifecycleStage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HerLife')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good to see you!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              lifecycleStage == null
                  ? 'Here’s your health overview.'
                  : 'Your health stage: $lifecycleStage',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Today',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // Cycle Tracking
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TrackingScreen(),
                  ),
                );

                _loadTrackingData();
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cycle Tracking',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              periodStart == null
                                  ? 'No period recorded yet'
                                  : 'Last period: '
                                      '${periodStart!.day}/'
                                      '${periodStart!.month}/'
                                      '${periodStart!.year}',
                            ),

                            if (symptoms.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Symptoms: ${symptoms.join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Daily Check-in
            InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckInScreen(),
                  ),
                );

                _loadTrackingData();
              },
              borderRadius: BorderRadius.circular(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 40,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Check-in',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              mood == null
                                  ? 'How are you feeling today?'
                                  : 'Mood: $mood',
                            ),

                            if (checkInSymptoms.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Symptoms: '
                                '${checkInSymptoms.join(', ')}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Your Health Journey',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'Keep tracking regularly to build a clearer picture '
              'of your health patterns over time.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  DateTime? periodStart;
  final Set<String> symptoms = {};

  final symptomOptions = [
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Mood changes',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString('period_start');
    final savedSymptoms = prefs.getStringList('symptoms') ?? [];

    if (!mounted) return;

    setState(() {
      if (savedDate != null) {
        periodStart = DateTime.tryParse(savedDate);
      }

      symptoms.addAll(savedSymptoms);
    });
  }

  Future<void> _saveTrackingData() async {
    final prefs = await SharedPreferences.getInstance();

    if (periodStart != null) {
      await prefs.setString('period_start', periodStart!.toIso8601String());
    }

    await prefs.setStringList('symptoms', symptoms.toList());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tracking entry saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Tracking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Track your cycle',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Record information to understand your patterns.',
              style: TextStyle(color: Colors.grey.shade700),
            ),

            const SizedBox(height: 28),

            const Text(
              'Period started?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: periodStart ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );

                if (date != null) {
                  setState(() {
                    periodStart = date;
                  });
                }
              },
              icon: const Icon(Icons.calendar_today),
              label: Text(
                periodStart == null
                    ? 'Select date'
                    : '${periodStart!.day}/${periodStart!.month}/${periodStart!.year}',
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              'Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            ...symptomOptions.map(
              (symptom) => CheckboxListTile(
                title: Text(symptom),
                value: symptoms.contains(symptom),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      symptoms.add(symptom);
                    } else {
                      symptoms.remove(symptom);
                    }
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveTrackingData,
                child: const Text('Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  DateTime? periodStart;
  List<String> cycleSymptoms = [];
  String? mood;
  List<String> checkInSymptoms = [];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDate = prefs.getString('period_start');
    final savedCycleSymptoms =
        prefs.getStringList('symptoms') ?? [];

    final savedMood = prefs.getString('checkin_mood');
    final savedCheckInSymptoms =
        prefs.getStringList('checkin_symptoms') ?? [];

    if (!mounted) return;

    setState(() {
      if (savedDate != null) {
        periodStart = DateTime.tryParse(savedDate);
      }

      cycleSymptoms = savedCycleSymptoms;
      mood = savedMood;
      checkInSymptoms = savedCheckInSymptoms;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Patterns')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Insights',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Patterns based on the information you track.',
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 24),

            // Cycle Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.calendar_month,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cycle Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            periodStart == null
                                ? 'No period data recorded yet.'
                                : 'Last period started on '
                                    '${periodStart!.day}/'
                                    '${periodStart!.month}/'
                                    '${periodStart!.year}.',
                          ),

                          if (cycleSymptoms.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Recorded symptoms: '
                              '${cycleSymptoms.join(', ')}.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Symptom Patterns
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.favorite_outline,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Symptom Patterns',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            checkInSymptoms.isEmpty
                                ? 'No check-in symptoms recorded yet.'
                                : 'Latest symptoms: '
                                    '${checkInSymptoms.join(', ')}.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mood
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.mood_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Latest Mood',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            mood == null
                                ? 'No daily check-in recorded yet.'
                                : 'Your latest recorded mood is $mood.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Important',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'These insights are for awareness and tracking only '
              'and are not a medical diagnosis.',
              style: TextStyle(
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EducationTopic {
  final String title;
  final String description;
  final String content;

  const EducationTopic({
    required this.title,
    required this.description,
    required this.content,
  });
}

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class EducationDetailScreen extends StatelessWidget {
  final EducationTopic topic;

  const EducationDetailScreen({
    super.key,
    required this.topic,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              topic.content,
              style: const TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This information is for education and '
                        'awareness only and is not a medical diagnosis.',
                        style: TextStyle(height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EducationScreenState extends State<EducationScreen> {
  String? lifecycleStage;

  @override
  void initState() {
    super.initState();
    _loadLifecycleStage();
  }

  Future<void> _loadLifecycleStage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStage = prefs.getString('lifecycle_stage');

    if (!mounted) return;

    setState(() {
      lifecycleStage = savedStage;
    });
  }

  List<EducationTopic> getTopics() {
    switch (lifecycleStage) {
      case 'Adolescence':
        return [
          const EducationTopic(
            title: 'Understanding Puberty',
            description: 'Learn about physical and hormonal changes.',
            content:
                'Puberty is a natural stage of development involving '
                'physical, emotional and hormonal changes.',
          ),
          const EducationTopic(
            title: 'Period Basics',
            description: 'Understand menstrual cycles and period care.',
            content:
                'Menstruation is a normal part of the menstrual cycle. '
                'Tracking your cycle can help you understand your patterns.',
          ),
          const EducationTopic(
            title: 'Healthy Habits',
            description: 'Learn about habits that support wellbeing.',
            content:
                'Balanced nutrition, regular movement, adequate sleep '
                'and personal hygiene support overall wellbeing.',
          ),
        ];

      case 'Menstruation':
        return [
          const EducationTopic(
            title: 'Understanding Your Menstrual Cycle',
            description: 'Learn how the menstrual cycle works.',
            content:
                'The menstrual cycle involves hormonal changes that '
                'prepare the body for a possible pregnancy.',
          ),
          const EducationTopic(
            title: 'Period Health',
            description: 'Learn about common period symptoms.',
            content:
                'Cramps, fatigue, bloating and mood changes can occur '
                'during the menstrual cycle.',
          ),
          const EducationTopic(
            title: 'Tracking Your Period',
            description: 'Understand why tracking can be useful.',
            content:
                'Tracking dates, symptoms and mood can help you identify '
                'your own patterns over time.',
          ),
        ];

      case 'Reproductive Health':
        return [
          const EducationTopic(
            title: 'Reproductive Health',
            description: 'Understand important aspects of reproductive health.',
            content:
                'Reproductive health includes physical, emotional and '
                'social wellbeing related to the reproductive system.',
          ),
          const EducationTopic(
            title: 'Hormonal Changes',
            description: 'Learn how hormones affect the body.',
            content:
                'Hormones influence many processes including the menstrual '
                'cycle, mood and reproductive functions.',
          ),
          const EducationTopic(
            title: 'When to Seek Help',
            description: 'Know when professional guidance may be useful.',
            content:
                'Persistent, severe or concerning symptoms should be '
                'discussed with a qualified healthcare professional.',
          ),
        ];

      case 'Pregnancy':
        return [
          const EducationTopic(
            title: 'Understanding Pregnancy',
            description: 'Learn about changes during pregnancy.',
            content:
                'Pregnancy involves many physical and hormonal changes '
                'as the body supports fetal development.',
          ),
          const EducationTopic(
            title: 'Pregnancy Wellbeing',
            description: 'Learn about general wellbeing during pregnancy.',
            content:
                'Nutrition, rest, appropriate activity and regular '
                'professional care are important during pregnancy.',
          ),
          const EducationTopic(
            title: 'When to Seek Help',
            description: 'Understand when professional care is important.',
            content:
                'New, severe or concerning symptoms during pregnancy '
                'should be discussed promptly with a healthcare professional.',
          ),
        ];

      case 'Postpartum':
        return [
          const EducationTopic(
            title: 'Postpartum Changes',
            description: 'Understand changes after childbirth.',
            content:
                'The postpartum period involves physical, hormonal and '
                'emotional changes while the body recovers from childbirth.',
          ),
          const EducationTopic(
            title: 'Postpartum Wellbeing',
            description: 'Learn about supporting recovery and wellbeing.',
            content:
                'Rest, nutrition, support and appropriate healthcare '
                'can help during postpartum recovery.',
          ),
          const EducationTopic(
            title: 'When to Seek Help',
            description: 'Know when professional support may be needed.',
            content:
                'Persistent or concerning physical or emotional symptoms '
                'should be discussed with a healthcare professional.',
          ),
        ];

      case 'Perimenopause':
        return [
          const EducationTopic(
            title: 'Understanding Perimenopause',
            description: 'Learn about the transition toward menopause.',
            content:
                'Perimenopause is a transitional stage in which hormonal '
                'changes can affect menstrual cycles and other symptoms.',
          ),
          const EducationTopic(
            title: 'Common Changes',
            description: 'Learn about changes that may occur.',
            content:
                'Changes in periods, sleep, mood and body temperature '
                'can occur during perimenopause.',
          ),
          const EducationTopic(
            title: 'Tracking Symptoms',
            description: 'Understand how tracking can help.',
            content:
                'Recording symptoms and cycle changes can help you '
                'understand patterns over time.',
          ),
        ];

      case 'Menopause':
        return [
          const EducationTopic(
            title: 'Understanding Menopause',
            description: 'Learn about menopause and hormonal changes.',
            content:
                'Menopause marks the end of menstrual periods and is '
                'associated with changes in reproductive hormones.',
          ),
          const EducationTopic(
            title: 'Common Symptoms',
            description: 'Learn about changes that may occur.',
            content:
                'Some people experience changes such as hot flashes, '
                'sleep changes or mood changes around menopause.',
          ),
          const EducationTopic(
            title: 'Healthy Habits',
            description: 'Learn about supporting overall wellbeing.',
            content:
                'Regular movement, balanced nutrition, adequate sleep '
                'and healthcare support overall wellbeing.',
          ),
        ];

      default:
        return [
          const EducationTopic(
            title: 'Understanding Your Menstrual Cycle',
            description: 'Learn how the menstrual cycle works.',
            content:
                'The menstrual cycle involves hormonal changes that '
                'prepare the body for a possible pregnancy.',
          ),
          const EducationTopic(
            title: 'Period Health',
            description: 'Learn about common period symptoms.',
            content:
                'Tracking your period and symptoms can help you '
                'understand your personal patterns.',
          ),
          const EducationTopic(
            title: 'When to Seek Help',
            description: 'Know when professional guidance may be useful.',
            content:
                'Persistent, severe or concerning symptoms should be '
                'discussed with a qualified healthcare professional.',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final topics = getTopics();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: topics.length,
        itemBuilder: (context, index) {
          final topic = topics[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                topic.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(topic.description),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios,
                size: 18,
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        EducationDetailScreen(topic: topic),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final List<Widget> screens = const [
    DashboardScreen(),
    TrackingScreen(),
    InsightsScreen(),
    EducationScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.track_changes_outlined),
            selectedIcon: Icon(Icons.track_changes),
            label: 'Track',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  String? mood;
  final Set<String> symptoms = {};

  final moods = ['Great', 'Good', 'Okay', 'Low', 'Not well'];

  final symptomOptions = [
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Stress',
  ];

  @override
  void initState() {
    super.initState();
    _loadCheckInData();
  }

  Future<void> _loadCheckInData() async {
    final prefs = await SharedPreferences.getInstance();

    final savedMood = prefs.getString('checkin_mood');
    final savedSymptoms = prefs.getStringList('checkin_symptoms') ?? [];

    if (!mounted) return;

    setState(() {
      mood = savedMood;
      symptoms.addAll(savedSymptoms);
    });
  }

  Future<void> _saveCheckIn() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('checkin_mood', mood!);
    await prefs.setStringList('checkin_symptoms', symptoms.toList());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Check-in')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            const Text(
              'Mood',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              children: moods.map((item) {
                return ChoiceChip(
                  label: Text(item),
                  selected: mood == item,
                  onSelected: (_) {
                    setState(() {
                      mood = item;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 28),

            const Text(
              'Symptoms',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            ...symptomOptions.map(
              (symptom) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(symptom),
                value: symptoms.contains(symptom),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      symptoms.add(symptom);
                    } else {
                      symptoms.remove(symptom);
                    }
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: mood == null ? null : _saveCheckIn,
                child: const Text('Save Check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
