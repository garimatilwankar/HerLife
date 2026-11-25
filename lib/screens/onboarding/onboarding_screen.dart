import 'package:flutter/material.dart';
import 'package:herlife/core/onboarding_questions.dart';
import 'package:herlife/core/onboarding_store.dart';
import 'package:herlife/screens/onboarding/tutorial_screen.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_logo.dart';

/// One question per page, every question skippable.
///
/// After sign up:  OnboardingScreen(onComplete: ...)  -> then the tutorial.
/// From Settings:  OnboardingScreen(editing: true, onComplete: ...) -> no tutorial.
class OnboardingScreen extends StatefulWidget {
  /// Called when everything is finished (after the tutorial, or right after
  /// the last question when [editing] is true).
  final VoidCallback onComplete;
  final bool editing;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    this.editing = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  Map<String, dynamic> _a = {};
  int _i = 0;
  bool _ready = false;
  bool _saving = false;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    // Only prefill when she is editing. A new sign up starts fresh.
    final saved = widget.editing ? await OnboardingStore.loadAnswers() : <String, dynamic>{};
    if (!mounted) return;
    setState(() {
      _a = saved;
      _ready = true;
    });
  }

  List<OnboardingQuestion> get _qs => visibleQuestions(_a);

  bool _answered(OnboardingQuestion q) {
    final v = _a[q.id];
    if (q.type == QType.multi) return v is List && v.isNotEmpty;
    return v is String && v.isNotEmpty;
  }

  void _pick(OnboardingQuestion q, String option) {
    setState(() => _a[q.id] = option);
  }

  void _toggle(OnboardingQuestion q, String option) {
    final cur = List<String>.from((_a[q.id] as List?) ?? const []);
    if (cur.contains(option)) {
      cur.remove(option);
    } else if (q.exclusive.contains(option)) {
      cur
        ..clear()
        ..add(option);
    } else {
      cur.removeWhere(q.exclusive.contains);
      cur.add(option);
    }
    setState(() => _a[q.id] = cur);
  }

  Future<void> _pickDate(OnboardingQuestion q) async {
    final now = DateTime.now();
    final existing = DateTime.tryParse((_a[q.id] as String?) ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: existing ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (picked == null) return;
    final iso =
        '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    setState(() => _a[q.id] = iso);
  }

  String _prettyDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return 'Select date';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  void _next() {
    if (_i < _qs.length - 1) {
      setState(() => _i++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_i > 0) setState(() => _i--);
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    // Drop answers for questions that were hidden by a later change.
    for (final q in onboardingQuestions) {
      if (q.hideWhen?.call(_a) == true) _a.remove(q.id);
    }
    await OnboardingStore.saveAnswers(_a);
    await OnboardingStore.markOnboardingDone();
    if (!mounted) return;
    if (widget.editing) {
      widget.onComplete();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => TutorialScreen(onDone: widget.onComplete),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: kBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final qs = _qs;
    final q = qs[_i];
    final isLast = _i == qs.length - 1;

    return PopScope(
      canPop: widget.editing && _i == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const HerLifeLogoMark(size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Question ${_i + 1} of ${qs.length}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kWine,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _saving ? null : _next,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (_i + 1) / qs.length),
                  duration: const Duration(milliseconds: 300),
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 6,
                      backgroundColor: kBlush,
                      color: kWine,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'This helps personalise HerLife. You can change it later.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    children: [
                      Text(
                        q.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: kWine,
                          height: 1.25,
                        ),
                      ),
                      if (q.type == QType.multi) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Select all that apply.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (q.type == QType.date)
                        _OptionTile(
                          label: _prettyDate((_a[q.id] as String?) ?? ''),
                          selected: _answered(q),
                          leading: Icons.calendar_month_outlined,
                          onTap: () => _pickDate(q),
                        )
                      else
                        for (final o in q.options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OptionTile(
                              label: o,
                              selected: q.type == QType.multi
                                  ? ((_a[q.id] as List?)?.contains(o) ?? false)
                                  : _a[q.id] == o,
                              multi: q.type == QType.multi,
                              onTap: () => q.type == QType.multi
                                  ? _toggle(q, o)
                                  : _pick(q, o),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_i > 0) ...[
                      OutlinedButton(
                        onPressed: _saving ? null : _back,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kWine,
                          minimumSize: const Size(80, 52),
                          side: const BorderSide(color: kWine),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (_answered(q) && !_saving) ? _next : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kWine,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: kBlush,
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(26)),
                          textStyle: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : Text(isLast ? 'Finish' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool multi;
  final IconData? leading;
  final VoidCallback onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.multi = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final IconData trailing = multi
        ? (selected ? Icons.check_box : Icons.check_box_outline_blank)
        : (selected ? Icons.check_circle : Icons.circle_outlined);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? kBlush : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? kWine : const Color(0xFFF1D6DA),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(leading, color: kWine),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            if (leading == null)
              Icon(trailing, color: selected ? kWine : Colors.black38),
          ],
        ),
      ),
    );
  }
}