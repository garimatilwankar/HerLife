import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:herlife/core/wellness_data.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_header.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class WellnessTab extends StatelessWidget {
  const WellnessTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: HerLifeHeader(subtitle: 'Wellness'),
              ),
              const TabBar(
                labelColor: kWine,
                indicatorColor: kWine,
                unselectedLabelColor: Colors.black54,
                tabs: [
                  Tab(text: 'Move'),
                  Tab(text: 'Eat'),
                  Tab(text: 'Calm'),
                ],
              ),
              const Expanded(
                child: TabBarView(
                  children: [_MovePage(), _EatPage(), _CalmPage()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================= MOVE =======================

class _MovePage extends StatefulWidget {
  const _MovePage();

  @override
  State<_MovePage> createState() => _MovePageState();
}

class _MovePageState extends State<_MovePage> {
  String _tag = 'All';

  Future<void> _open(MoveRoutine r) async {
    final url = Uri.parse(
      'https://www.youtube.com/results?search_query='
      '${Uri.encodeQueryComponent(r.query)}',
    );
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open YouTube.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shown = WellnessData.routines
        .where((r) => _tag == 'All' || r.tag == _tag)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in WellnessData.moveTags)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pill(t, selected: _tag == t, onTap: () => setState(() => _tag = t)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final r in shown)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              onTap: () => _open(r),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: kBlush,
                    child: Icon(Icons.play_arrow_rounded, color: kWine),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(r.blurb,
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 6),
                        Pill('${r.minutes} min', icon: Icons.timer_outlined),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, size: 18, color: Colors.black38),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'Move in a way that feels good. Stop if something hurts. '
          'Pain that stops you from daily activities is worth telling a doctor or a trusted adult.',
          style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
        ),
      ],
    );
  }
}

// ======================= EAT =======================

class _EatPage extends StatefulWidget {
  const _EatPage();

  @override
  State<_EatPage> createState() => _EatPageState();
}

class _EatPageState extends State<_EatPage> {
  bool _loaded = false;
  bool _editing = false;
  String? _diet;
  Set<String> _avoid = {};
  int _shift = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _diet = p.getString('eat_diet');
      _avoid = (p.getStringList('eat_allergens') ?? []).toSet();
      _editing = _diet == null;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('eat_diet', _diet!);
    await p.setStringList('eat_allergens', _avoid.toList());
    if (!mounted) return;
    setState(() {
      _editing = false;
      _shift = 0;
    });
  }

  void _openRecipe(Recipe r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kWine)),
            const SizedBox(height: 6),
            Text(r.why, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(r.ingredients, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 12),
            const Text('How to make it', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(r.how, style: const TextStyle(height: 1.4)),
            if (r.allergens.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Contains: ${r.allergens.join(', ')}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _questionnaire() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tell us how you eat',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('We will only show dishes that suit you. You can change this any time.',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
          const SizedBox(height: 14),
          const Text('1. Your food preference', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in WellnessData.diets)
                Pill(d, selected: _diet == d, onTap: () => setState(() => _diet = d)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('2. Anything you are allergic to or avoid?',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in WellnessData.allergens)
                Pill(
                  a,
                  selected: _avoid.contains(a),
                  onTap: () => setState(() {
                    _avoid.contains(a) ? _avoid.remove(a) : _avoid.add(a);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kWine),
              onPressed: _diet == null ? null : _save,
              child: const Text('Show my dishes'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    final list = WellnessData.filter(_diet, _avoid);
    final today = DateTime.now();
    final dayOfYear = today.difference(DateTime(today.year, 1, 1)).inDays;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_editing)
          _questionnaire()
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '$_diet${_avoid.isEmpty ? '' : '  •  avoiding ${_avoid.length}'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _editing = true),
                child: const Text('Change'),
              ),
            ],
          ),
          if (list.isEmpty)
            const AppCard(
              child: Text('No dishes match these choices yet. Try removing an allergen filter.'),
            )
          else ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: kWine, size: 20),
                      SizedBox(width: 8),
                      Text('Try something new today',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Builder(builder: (_) {
                    final pick = list[(dayOfYear + _shift) % list.length];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pick.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(pick.why,
                            style: const TextStyle(fontSize: 13, color: Colors.black54)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            TextButton(
                                onPressed: () => _openRecipe(pick),
                                child: const Text('See recipe')),
                            TextButton(
                                onPressed: () => setState(() => _shift++),
                                child: const Text('Show another')),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text('Dishes for you',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  onTap: () => _openRecipe(r),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: kBlush,
                        child: Icon(Icons.restaurant_outlined, color: kWine, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(r.why,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Text(r.time, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
              ),
          ],
        ],
        const SizedBox(height: 8),
        const Text(
          'Food ideas only. Every body is different, so listen to your hunger and fullness. '
          'If you have a food allergy, always check labels and ask a doctor.',
          style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
        ),
      ],
    );
  }
}

// ======================= CALM =======================

class _Pattern {
  final String name;
  final String note;
  final List<_Phase> phases;
  const _Pattern(this.name, this.note, this.phases);
}

class _Phase {
  final String label;
  final int seconds;
  final bool? grow; // true = circle grows, false = shrinks, null = hold
  const _Phase(this.label, this.seconds, this.grow);
}

class _CalmPage extends StatefulWidget {
  const _CalmPage();

  @override
  State<_CalmPage> createState() => _CalmPageState();
}

class _CalmPageState extends State<_CalmPage> with SingleTickerProviderStateMixin {
  static const _patterns = <_Pattern>[
    _Pattern('Calm breathing', 'In for 4, out for 6. Good any time.', [
      _Phase('Breathe in', 4, true),
      _Phase('Breathe out', 6, false),
    ]),
    _Pattern('Box breathing', 'Equal 4 counts. Good before exams.', [
      _Phase('Breathe in', 4, true),
      _Phase('Hold', 4, null),
      _Phase('Breathe out', 4, false),
      _Phase('Hold', 4, null),
    ]),
    _Pattern('4-7-8 for sleep', 'A slow pattern to wind down at night.', [
      _Phase('Breathe in', 4, true),
      _Phase('Hold', 7, null),
      _Phase('Breathe out', 8, false),
    ]),
  ];

  late final AnimationController _c;
  int _selected = 0;
  bool _running = false;
  String _label = 'Ready?';

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _running = false;
    _c.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _label = 'Get comfortable';
    });
    await Future.delayed(const Duration(seconds: 1));
    while (_running && mounted) {
      for (final p in _patterns[_selected].phases) {
        if (!_running || !mounted) return;
        setState(() => _label = p.label);
        HapticFeedback.lightImpact();
        if (p.grow == null) {
          await Future.delayed(Duration(seconds: p.seconds));
        } else {
          await _c.animateTo(
            p.grow! ? 1 : 0,
            duration: Duration(seconds: p.seconds),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  void _stop() {
    _c.stop();
    _c.animateTo(0, duration: const Duration(milliseconds: 600));
    setState(() {
      _running = false;
      _label = 'Ready?';
    });
  }

  @override
  Widget build(BuildContext context) {
    final pattern = _patterns[_selected];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _patterns.length; i++)
              Pill(
                _patterns[i].name,
                selected: _selected == i,
                onTap: _running ? null : () => setState(() => _selected = i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(pattern.note, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 20),
        SizedBox(
          height: 240,
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, __) {
                final size = 110 + 110 * _c.value;
                return Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kBlush,
                    border: Border.all(color: kWine, width: 3),
                  ),
                  child: Text(
                    _label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: kWine,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: kWine,
            minimumSize: const Size.fromHeight(50),
          ),
          onPressed: _running ? _stop : _start,
          icon: Icon(_running ? Icons.stop : Icons.play_arrow),
          label: Text(_running ? 'Stop' : 'Start'),
        ),
        const SizedBox(height: 20),
        const AppCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.favorite_border, color: kWine),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Feeling overwhelmed is normal, especially with exams, friends and '
                  'changing hormones. If sadness or worry lasts for weeks, please talk to '
                  'a parent, a teacher or a doctor. You do not have to handle it alone.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}