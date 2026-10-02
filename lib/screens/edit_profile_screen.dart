import 'package:flutter/material.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const wine = Color(0xFF7B2946);
  static const blush = Color(0xFFF3DDE5);
  static const background = Color(0xFFFAF7F8);

  final nameController = TextEditingController();
  final emailController = TextEditingController();

  DateTime? dateOfBirth;
  String? biologicalAssignment;
  String? lifecycleStage;

  bool saving = false;

  final lifecycleStages = const [
    'Adolescence',
    'Menstruation',
    'Reproductive Health',
    'Pregnancy',
    'Postpartum',
    'Perimenopause',
    'Menopause',
  ];

  final biologicalOptions = const [
    'Female',
    'Male',
    'Intersex',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final savedName = await AuthService.currentName();
    final savedEmail = await AuthService.currentEmail();

    final savedDob = prefs.getString('date_of_birth');

    if (!mounted) return;

    setState(() {
      nameController.text = savedName ?? '';
      emailController.text = savedEmail ?? '';
      biologicalAssignment =
          prefs.getString('biological_assignment');
      lifecycleStage = prefs.getString('lifecycle_stage');

      if (savedDob != null) {
        dateOfBirth = DateTime.tryParse(savedDob);
      }
    });
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: dateOfBirth ?? DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (selected != null) {
      setState(() {
        dateOfBirth = selected;
      });
    }
  }

  Future<void> _saveProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name and email cannot be empty.'),
        ),
      );
      return;
    }

    setState(() => saving = true);

    final result = await AuthService.updateProfile(
      name: name,
      email: email,
    );

    if (!result.ok) {
      if (!mounted) return;

      setState(() => saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Unable to save profile.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    if (dateOfBirth != null) {
      await prefs.setString(
        'date_of_birth',
        dateOfBirth!.toIso8601String(),
      );
    } else {
      await prefs.remove('date_of_birth');
    }

    if (biologicalAssignment != null) {
      await prefs.setString(
        'biological_assignment',
        biologicalAssignment!,
      );
    }

    if (lifecycleStage != null) {
      await prefs.setString(
        'lifecycle_stage',
        lifecycleStage!,
      );
    }

    if (!mounted) return;

    setState(() => saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully.'),
      ),
    );

    Navigator.pop(context);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not added';

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : _saveProfile,
            child: const Text(
              'Save',
              style: TextStyle(
                color: wine,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: blush,
                          child: Text(
                            nameController.text.isEmpty
                                ? 'H'
                                : nameController.text
                                    .substring(0, 1)
                                    .toUpperCase(),
                            style: const TextStyle(
                              color: wine,
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: wine,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Profile photo',
                      style: TextStyle(
                        color: wine,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _sectionTitle('PERSONAL INFORMATION'),

              _field(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 14),

              _field(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 14),

              _dateField(),

              const SizedBox(height: 28),

              _sectionTitle('LIFECYCLE INFORMATION'),

              _dropdown(
                label: 'Biological Assignment at Birth',
                value: biologicalAssignment,
                items: biologicalOptions,
                onChanged: (value) {
                  setState(() {
                    biologicalAssignment = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              _dropdown(
                label: 'Lifecycle Stage',
                value: lifecycleStage,
                items: lifecycleStages,
                onChanged: (value) {
                  setState(() {
                    lifecycleStage = value;
                  });
                },
              ),

              const SizedBox(height: 26),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: blush.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: wine,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your profile information helps personalize '
                        'your HerLife experience. We will connect this '
                        'to your secure account when the backend is added.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: saving ? null : _saveProfile,
                  style: FilledButton.styleFrom(
                    backgroundColor: wine,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Discard Changes',
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: wine),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _dateField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date of Birth',
          prefixIcon: const Icon(
            Icons.cake_outlined,
            color: wine,
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
        child: Text(
          _formatDate(dateOfBirth),
          style: TextStyle(
            color: dateOfBirth == null
                ? Colors.black54
                : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: items.contains(value) ? value : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(item),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}