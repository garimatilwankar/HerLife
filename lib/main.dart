import 'package:flutter/material.dart';
import 'package:herlife/screens/auth_screens.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:herlife/services/tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herlife/screens/tabs/home_tab.dart';
import 'package:herlife/screens/tabs/track_tab.dart';
import 'package:herlife/screens/tabs/insights_tab.dart';
import 'package:herlife/screens/tabs/learn_tab.dart';
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/screens/lifecycle_screen.dart';
import 'package:herlife/widgets/herlife_logo.dart';
import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/core/config/app_config.dart';
import 'package:herlife/widgets/server_config_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadPersistedUrl();
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
        colorScheme: ColorScheme.fromSeed(seedColor: kWine),
        fontFamily: 'sans',
      ),
      home: const AppGate(),
    );
  }
}

/// Professional HerLife Splash & Loading Screen.
class HerLifeSplashScreen extends StatelessWidget {
  final String? subtitle;

  const HerLifeSplashScreen({super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const HerLifeBrandLogo(
              iconSize: 76,
              fontSize: 34,
              direction: Axis.vertical,
              hasBackgroundIcon: true,
            ),
            const SizedBox(height: 24),
            Text(
              subtitle ?? 'Your health, your data, your journey.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 36),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: kWine,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Decides the first screen: logged out -> welcome, logged in without a
/// stage -> stage picker, logged in with a stage -> the main app.
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
    // validateSession clears the token on 401. If a token is still stored,
    // the failure was transient (offline/server down): keep the user in.
    if (!isValidSession && !await AuthService.isLoggedIn()) {
      return const WelcomeScreen();
    }

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
          return const HerLifeSplashScreen();
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
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: () => ServerConfigDialog.show(context),
                child: const HerLifeBrandLogo(
                  iconSize: 84,
                  fontSize: 36,
                  direction: Axis.vertical,
                  hasBackgroundIcon: true,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Understand your health. Track your patterns. Get information tailored to your lifecycle stage.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kWine,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    );
                  },
                  child: const Text(
                    'Create account',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kWine,
                    side: const BorderSide(color: kWine),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                  child: const Text('Log in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
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
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
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
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        title: const Text('Daily Check-in', style: TextStyle(color: kWine, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kWine),
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
                final selected = mood == item;
                return ChoiceChip(
                  label: Text(item),
                  selected: selected,
                  selectedColor: kWine,
                  labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
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
                activeColor: kWine,
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWine,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: mood == null ? null : _saveCheckIn,
                child: const Text('Save Check-in', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}