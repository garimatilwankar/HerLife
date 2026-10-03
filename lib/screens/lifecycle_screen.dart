import 'package:herlife/main.dart' show MainNavigation;
import 'package:flutter/material.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LifecycleScreen extends StatefulWidget {
  const LifecycleScreen({super.key});

  @override
  State<LifecycleScreen> createState() => _LifecycleScreenState();
}

class _LifecycleScreenState extends State<LifecycleScreen> {
  String? selectedStage;
  bool saving = false;

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
    final profile = await ProfileService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    final savedStage = profile?.lifecycleStage ?? prefs.getString('lifecycle_stage');

    if (!mounted) return;

    setState(() {
      selectedStage = savedStage;
    });
  }

  Future<void> _saveLifecycleStage() async {
    if (selectedStage == null || saving) return;

    setState(() => saving = true);

    final result = await ProfileService.updateProfile(
      lifecycleStage: selectedStage,
    );

    if (!mounted) return;

    if (!result.ok) {
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Failed to save health stage.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Health Stage')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which stage best describes you?',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'This helps HerLife provide more relevant information.',
                style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: stages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.9,
                  ),
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    final isSelected = selectedStage == stage;

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedStage = stage;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        margin: EdgeInsets.zero,
                        elevation: isSelected ? 2 : 0,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              stage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                          ),
                        ),
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
                  onPressed: selectedStage == null || saving ? null : _saveLifecycleStage,
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}