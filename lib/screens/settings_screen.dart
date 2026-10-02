import 'package:flutter/material.dart';
import 'package:herlife/screens/edit_profile_screen.dart';
import 'package:herlife/screens/lifecycle_screen.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herlife/main.dart' show AppGate;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? name;
  String? email;
  String? lifecycleStage;
  bool notifications = true;
  bool anonymousTelemetry = false;

  static const wine = Color(0xFF7B2946);
  static const blush = Color(0xFFF3DDE5);
  static const background = Color(0xFFFAF7F8);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = await AuthService.currentName();
    final savedEmail = await AuthService.currentEmail();

    if (!mounted) return;

    setState(() {
      name = savedName;
      email = savedEmail;
      lifecycleStage = prefs.getString('lifecycle_stage');
      notifications = prefs.getBool('notifications_enabled') ?? true;
      anonymousTelemetry =
          prefs.getBool('anonymous_telemetry_enabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _changeLifecycleStage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LifecycleScreen(),
      ),
    );

    _loadProfile();
  }

  Future<void> _clearHealthData() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear health data?'),
          content: const Text(
            'This will remove your locally stored period, symptom, '
            'mood and check-in data. Your account will remain active.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: wine),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear data'),
            ),
          ],
        );
      },
    );

    if (shouldClear != true) return;

    final prefs = await SharedPreferences.getInstance();

    const healthKeys = [
      'period_start',
      'period_history',
      'period_end_dates',
      'symptoms',
      'checkin_mood',
      'checkin_symptoms',
    ];

    for (final key in healthKeys) {
      await prefs.remove(key);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health data cleared from this device.'),
      ),
    );
  }

  Future<void> _logout() async {
    await AuthService.logOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppGate()),
      (route) => false,
    );
  }

  void _showComingSoon(String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title will be available in a future update.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = name ?? 'HerLife user';
    final displayEmail = email ?? 'No email available';
    final stage = lifecycleStage ?? 'Not selected';

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _profileCard(displayName, displayEmail),
            const SizedBox(height: 24),

            _sectionTitle('ACCOUNT'),
            _settingCard(
              children: [
                _settingTile(
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  subtitle: 'Update your personal information',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                    _loadProfile();
                  },
                ),
                _divider(),
                _settingTile(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Lifecycle Stage',
                  subtitle: stage,
                  onTap: _changeLifecycleStage,
                ),
                _divider(),
                _settingTile(
                  icon: Icons.favorite_outline,
                  title: 'Personal Vitals',
                  subtitle: 'Date of birth and health profile',
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                    _loadProfile();
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('PREFERENCES'),
            _settingCard(
              children: [
                _switchTile(
                  icon: Icons.notifications_none,
                  title: 'Notifications',
                  subtitle: 'Health reminders and updates',
                  value: notifications,
                  onChanged: (value) {
                    setState(() => notifications = value);
                    _saveSetting('notifications_enabled', value);
                  },
                ),
                _divider(),
                _settingTile(
                  icon: Icons.palette_outlined,
                  title: 'App Appearance',
                  subtitle: 'Light appearance',
                  onTap: () => _showComingSoon('App appearance'),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.language_outlined,
                  title: 'Language & Units',
                  subtitle: 'English • Metric',
                  onTap: () => _showComingSoon('Language and units'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('PRIVACY & SECURITY'),
            _settingCard(
              children: [
                _settingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy & Data',
                  subtitle: 'Manage your locally stored health data',
                  onTap: _clearHealthData,
                ),
                _divider(),
                _settingTile(
                  icon: Icons.lock_outline,
                  title: 'App Lock',
                  subtitle: 'Biometric protection will be available later',
                  trailing: const Text(
                    'Soon',
                    style: TextStyle(
                      color: wine,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () => _showComingSoon('App lock'),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.description_outlined,
                  title: 'Export Clinical Summary',
                  subtitle: 'Prepare a summary of your tracked information',
                  onTap: () => _showComingSoon('Clinical summary export'),
                ),
                _divider(),
                _switchTile(
                  icon: Icons.analytics_outlined,
                  title: 'Anonymous Telemetry',
                  subtitle: 'Help improve HerLife without sharing health data',
                  value: anonymousTelemetry,
                  onChanged: (value) {
                    setState(() => anonymousTelemetry = value);
                    _saveSetting('anonymous_telemetry_enabled', value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            _sectionTitle('SUPPORT'),
            _settingCard(
              children: [
                _settingTile(
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help using HerLife',
                  onTap: () => _showComingSoon('Help and support'),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.info_outline,
                  title: 'About HerLife',
                  subtitle: 'Version 1.0.0',
                  onTap: () => _showComingSoon('About HerLife'),
                ),
                _divider(),
                _settingTile(
                  icon: Icons.policy_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How HerLife handles your information',
                  onTap: () => _showComingSoon('Privacy policy'),
                ),
              ],
            ),

            const SizedBox(height: 28),

            OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: wine,
                side: const BorderSide(color: wine),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                'HerLife • Your health, your data, your journey.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(String displayName, String displayEmail) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: blush),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: blush,
            child: Text(
              displayName.isEmpty
                  ? 'H'
                  : displayName.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: wine,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  displayEmail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit profile',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
              _loadProfile();
            },
            icon: const Icon(Icons.edit_outlined, color: wine),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: wine,
        ),
      ),
    );
  }

  Widget _settingCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE5E9)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: blush,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: wine, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ),
      trailing: trailing ??
          const Icon(
            Icons.chevron_right,
            color: Colors.black38,
          ),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 6,
      ),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: blush,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: wine, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: wine,
      ),
    );
  }

  Widget _divider() {
    return const Divider(
      height: 1,
      indent: 74,
      endIndent: 16,
    );
  }
}