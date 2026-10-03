import 'package:flutter/material.dart';
import 'package:herlife/screens/auth_screens.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:herlife/services/tracking_service.dart';
import 'package:herlife/models/api_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herlife/screens/tabs/home_tab.dart';
import 'package:herlife/screens/tabs/track_tab.dart';
import 'package:herlife/screens/tabs/insights_tab.dart';
import 'package:herlife/screens/tabs/learn_tab.dart';
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/lifecycle_screen.dart';

import 'package:herlife/core/network/api_client.dart';

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
      home: const AppGate(),
    );
  }
}

/// Decides the first screen: logged out -> welcome, logged in without a
/// stage -> stage picker, logged in with a stage -> the app.
class AppGate extends StatefulWidget {
  const AppGate({super.key});

  @override
  State<AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<AppGate> {
  late final Future<Widget> _destination;

  @override
  void initState() {
    super.initState();
    ApiClient().onUnauthorized = () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
          (route) => false,
        );
      }
    };
    _destination = _decide();
  }

  Future<Widget> _decide() async {
    final isValidSession = await AuthService.validateSession();
    if (!isValidSession) return const WelcomeScreen();

    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('lifecycle_stage');

    if (stage == null || stage.isEmpty) return const LifecycleScreen();
    return const MainNavigation();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _destination,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return snapshot.data!;
      },
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
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.favorite, size: 80, color: Color(0xFFE56B8A)),
              const SizedBox(height: 24),
              const Text(
                'Welcome to HerLife',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Understand your health. Track your patterns. '
                'Get information that fits your life stage.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Log in', style: TextStyle(fontSize: 16)),
                ),
              ),
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
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final backendPeriods = await TrackingService.getPeriods();
    final backendSymptoms = await TrackingService.getSymptoms();
    final backendCheckins = await TrackingService.getCheckins();
    final profile = await ProfileService.getProfile();
    final prefs = await SharedPreferences.getInstance();

    final savedName = await AuthService.currentName();

    final parsedDates = backendPeriods
        .map((p) => DateTime(p.startDate.year, p.startDate.month, p.startDate.day))
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final loadedSymptoms = backendSymptoms.map((s) => s.name).toSet().toList();
    final loadedMood = backendCheckins.isNotEmpty ? backendCheckins.first.mood : prefs.getString('checkin_mood');
    final loadedCheckInSymptoms = backendCheckins.isNotEmpty && backendCheckins.first.notes != null
        ? backendCheckins.first.notes!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : (prefs.getStringList('checkin_symptoms') ?? []);

    if (!mounted) return;

    setState(() {
      periodStart = parsedDates.isNotEmpty ? parsedDates.first : null;
      symptoms = loadedSymptoms;
      mood = loadedMood;
      checkInSymptoms = loadedCheckInSymptoms;
      lifecycleStage = profile?.lifecycleStage ?? prefs.getString('lifecycle_stage');
      userName = savedName;
    });
  }

  String _getStageMessage() {
    switch (lifecycleStage) {
      case 'Adolescence':
        return 'Learn about the changes happening in your body and build healthy habits.';
      case 'Menstruation':
        return 'Track your cycle, understand symptoms, and notice your personal patterns.';
      case 'Reproductive Health':
        return 'Keep track of your reproductive health and understand your body better.';
      case 'Pregnancy':
        return 'Track your pregnancy journey and learn about changes throughout each stage.';
      case 'Postpartum':
        return 'Focus on recovery, wellbeing, and changes after childbirth.';
      case 'Perimenopause':
        return 'Understand changing cycles, symptoms, and patterns during this transition.';
      case 'Menopause':
        return 'Track symptoms and learn about your health during and after menopause.';
      default:
        return 'Track your health and understand your personal patterns.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HerLife'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'stage') {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LifecycleScreen()),
                  (route) => false,
                );
              } else if (value == 'logout') {
                await AuthService.logOut();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AppGate()),
                  (route) => false,
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'stage', child: Text('Change life stage')),
              PopupMenuItem(value: 'logout', child: Text('Log out')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName == null ? 'Good to see you!' : 'Hi, $userName',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lifecycleStage == null
                      ? 'Here’s your health overview.'
                      : 'Your health stage: $lifecycleStage',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                ),

                const SizedBox(height: 8),

                Text(
                  _getStageMessage(),
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            const Text(
              'Today',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const Icon(Icons.arrow_forward_ios, size: 18),
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
                                style: TextStyle(color: Colors.grey.shade700),
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
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
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
  List<DateTime> periodHistory = [];
  Map<String, DateTime> periodEndDates = {};
  final Set<String> symptoms = {};

  final List<String> symptomOptions = [
    'Cramps',
    'Headache',
    'Fatigue',
    'Bloating',
    'Mood changes',
  ];

  DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime? get latestPeriod {
    if (periodHistory.isEmpty) return null;
    return periodHistory.first;
  }

  int get cycleDay {
    if (latestPeriod == null) return 0;

    return today.difference(latestPeriod!).inDays + 1;
  }

  List<int> get cycleLengths {
    if (periodHistory.length < 2) return [];

    final sorted = [...periodHistory]..sort((a, b) => b.compareTo(a));

    List<int> lengths = [];

    for (int i = 0; i < sorted.length - 1; i++) {
      lengths.add(sorted[i].difference(sorted[i + 1]).inDays);
    }

    return lengths;
  }

  double? get averageCycleLength {
    if (cycleLengths.isEmpty) return null;

    final total = cycleLengths.reduce((a, b) => a + b);
    return total / cycleLengths.length;
  }

  DateTime? get nextPeriodDate {
    if (latestPeriod == null) return null;

    final cycleLength = averageCycleLength ?? 28;

    return latestPeriod!.add(Duration(days: cycleLength.round()));
  }

  @override
  void initState() {
    super.initState();
    _loadTrackingData();
  }

  Future<void> _loadTrackingData() async {
    final backendPeriods = await TrackingService.getPeriods();
    final backendSymptoms = await TrackingService.getSymptoms();

    final loadedEndDates = <String, DateTime>{};
    final parsedDates = <DateTime>[];

    for (final p in backendPeriods) {
      final startDate = DateTime(p.startDate.year, p.startDate.month, p.startDate.day);
      parsedDates.add(startDate);
      if (p.endDate != null) {
        loadedEndDates[startDate.toIso8601String()] = DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day);
      }
    }
    parsedDates.sort((a, b) => b.compareTo(a));

    if (!mounted) return;

    setState(() {
      periodHistory = parsedDates;
      periodEndDates = loadedEndDates;
      symptoms.clear();
      symptoms.addAll(backendSymptoms.map((s) => s.name));
    });
  }

  Future<void> _selectPeriodDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: latestPeriod ?? today,
      firstDate: DateTime(2000),
      lastDate: today,
    );

    if (selectedDate == null) return;

    await TrackingService.createPeriod(selectedDate);
    await _loadTrackingData();
  }

  Future<void> _selectPeriodEndDate(DateTime startDate) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: periodEndDates[startDate.toIso8601String()] ?? startDate,
      firstDate: startDate,
      lastDate: today,
    );

    if (selectedDate == null) return;

    final backendPeriods = await TrackingService.getPeriods();
    final existing = backendPeriods.firstWhere(
      (p) =>
          p.startDate.year == startDate.year &&
          p.startDate.month == startDate.month &&
          p.startDate.day == startDate.day,
      orElse: () => PeriodResponse(id: -1, startDate: startDate),
    );

    if (existing.id != -1) {
      await TrackingService.updatePeriod(existing.id, startDate, endDate: selectedDate);
    } else {
      await TrackingService.createPeriod(startDate, endDate: selectedDate);
    }

    await _loadTrackingData();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Tracking')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Period Tracking',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Record your period dates to understand your cycle patterns.',
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latest Period',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      latestPeriod == null
                          ? 'No period date recorded'
                          : _formatDate(latestPeriod!),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: _selectPeriodDate,
                      child: const Text('Add Period Date'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (latestPeriod != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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

                      const SizedBox(height: 12),

                      Text('Current cycle day: $cycleDay'),

                      const SizedBox(height: 8),

                      if (latestPeriod != null &&
                          periodEndDates[latestPeriod!.toIso8601String()] !=
                              null)
                        Text(
                          'Latest period duration: '
                          '${periodEndDates[latestPeriod!.toIso8601String()]!.difference(latestPeriod!).inDays + 1} days',
                        ),

                      const SizedBox(height: 8),

                      Text(
                        averageCycleLength == null
                            ? 'Average cycle length: Not enough data'
                            : 'Average cycle length: ${averageCycleLength!.round()} days',
                      ),
                      const SizedBox(height: 8),

                      Text(
                        nextPeriodDate == null
                            ? 'Estimated next period: Not available'
                            : 'Estimated next period: ${_formatDate(nextPeriodDate!)}',
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            if (periodHistory.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Period History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      ...periodHistory.map((date) {
                        final endDate = periodEndDates[date.toIso8601String()];

                        final duration = endDate == null
                            ? null
                            : endDate.difference(date).inDays + 1;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Started: ${_formatDate(date)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 4),

                              if (endDate != null)
                                Text(
                                  'Ended: ${_formatDate(endDate)} • Duration: $duration days',
                                )
                              else
                                TextButton(
                                  onPressed: () => _selectPeriodEndDate(date),
                                  child: const Text('Add end date'),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Symptoms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    ...symptomOptions.map(
                      (symptom) => CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(symptom),
                        value: symptoms.contains(symptom),
                        onChanged: (value) async {
                          final now = DateTime.now();
                          setState(() {
                            if (value == true) {
                              symptoms.add(symptom);
                            } else {
                              symptoms.remove(symptom);
                            }
                          });

                          if (value == true) {
                            await TrackingService.createSymptom(now, symptom);
                          } else {
                            final backendSymptoms = await TrackingService.getSymptoms();
                            final toDelete = backendSymptoms.where((s) => s.name == symptom).toList();
                            for (final s in toDelete) {
                              await TrackingService.deleteSymptom(s.id);
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  for (final s in symptoms) {
                    await TrackingService.createSymptom(now, s);
                  }

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tracking data saved')),
                  );
                },
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
  List<DateTime> periodHistory = [];
  List<int> cycleLengths = [];
  double? averageCycleLength;
  int? cycleVariation;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    final prefs = await SharedPreferences.getInstance();

    final savedDates = prefs.getStringList('period_history') ?? [];
    final savedMood = prefs.getString('checkin_mood');
    final savedCycleSymptoms = prefs.getStringList('symptoms') ?? [];
    final savedCheckInSymptoms = prefs.getStringList('checkin_symptoms') ?? [];

    final dates = savedDates
        .map((date) => DateTime.tryParse(date))
        .whereType<DateTime>()
        .toList();

    dates.sort((a, b) => a.compareTo(b));

    final lengths = <int>[];

    for (int i = 1; i < dates.length; i++) {
      lengths.add(dates[i].difference(dates[i - 1]).inDays);
    }

    double? average;
    int? variation;

    if (lengths.isNotEmpty) {
      average = lengths.reduce((a, b) => a + b) / lengths.length;

      variation =
          lengths.reduce((a, b) => a > b ? a : b) -
          lengths.reduce((a, b) => a < b ? a : b);
    }

    if (!mounted) return;

    setState(() {
      periodHistory = dates;
      periodStart = dates.isNotEmpty ? dates.last : null;

      cycleLengths = lengths;
      averageCycleLength = average;
      cycleVariation = variation;

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
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'Patterns based on the information you track.',
              style: TextStyle(color: Colors.grey.shade700),
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
                              style: TextStyle(color: Colors.grey.shade700),
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

            // Cycle Pattern
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cycle Pattern',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (averageCycleLength == null)
                            const Text(
                              'Track at least two periods to see your cycle pattern here.',
                            )
                          else ...[
                            Text(
                              'Average recorded cycle: '
                              '${averageCycleLength!.round()} days.',
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Recorded cycles: '
                              '${cycleLengths.join(', ')} days.',
                            ),

                            const SizedBox(height: 6),

                            Text(
                              cycleVariation! <= 7
                                  ? 'Your recorded cycle lengths have been relatively consistent.'
                                  : 'Your recorded cycle lengths have varied by '
                                        '$cycleVariation days.',
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              'These insights are for awareness and tracking only '
              'and are not a medical diagnosis.',
              style: TextStyle(color: Colors.grey.shade700, height: 1.4),
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

  const EducationDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              topic.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Text(
              topic.content,
              style: const TextStyle(fontSize: 16, height: 1.6),
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
      appBar: AppBar(title: const Text('Learn')),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(topic.description),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 18),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EducationDetailScreen(topic: topic),
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
    HomeTab(),
    TrackTab(),
    InsightsTab(),
    LearnTab(),
    AskTab(),
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
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Ask',
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
    final checkins = await TrackingService.getCheckins();
    final backendSymptoms = await TrackingService.getSymptoms();
    final prefs = await SharedPreferences.getInstance();

    final savedMood = checkins.isNotEmpty ? checkins.first.mood : prefs.getString('checkin_mood');
    final loadedSymptoms = backendSymptoms.map((s) => s.name).toSet();

    if (!mounted) return;

    setState(() {
      mood = savedMood;
      symptoms.clear();
      symptoms.addAll(loadedSymptoms);
    });
  }

  Future<void> _saveCheckIn() async {
    if (mood == null) return;

    final now = DateTime.now();

    await TrackingService.createCheckin(
      now,
      mood!,
      notes: symptoms.isNotEmpty ? symptoms.join(', ') : null,
    );

    for (final symptom in symptoms) {
      await TrackingService.createSymptom(now, symptom);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkin_mood', mood!);
    await prefs.setStringList('checkin_symptoms', symptoms.toList());

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in saved successfully!')),
    );

    Navigator.pop(context);
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
