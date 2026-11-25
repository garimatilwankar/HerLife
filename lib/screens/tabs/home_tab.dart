import 'package:flutter/material.dart';
import 'package:herlife/core/health_facts.dart';
import 'package:herlife/core/tab_nav.dart';
import 'package:herlife/main.dart' show CheckInScreen;
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_header.dart';

/// Where she is in her cycle, with a gentle tip for each area.
/// Phases are estimates from logged dates, never a diagnosis.
class _Phase {
  final String label;
  final IconData icon;
  final String move;
  final String eat;
  final String calm;
  const _Phase(this.label, this.icon, this.move, this.eat, this.calm);
}

const _pPeriod = _Phase(
  'Period days',
  Icons.water_drop_outlined,
  'Gentle stretching or a slow walk can ease cramps. Rest is fine too.',
  'Add iron-rich foods like lentils, chickpeas and leafy greens.',
  'Warmth on your lower belly and an earlier night can help.',
);
const _pFollicular = _Phase(
  'Energy rising (estimated)',
  Icons.trending_up,
  'Energy often picks up now. A good time for strength work or something new.',
  'Protein and colourful vegetables keep energy steady.',
  'A short walk outside is a nice way to reset your mind.',
);
const _pMid = _Phase(
  'Mid-cycle (estimated)',
  Icons.wb_sunny_outlined,
  'Steady cardio like brisk walking or cycling often feels good now.',
  'Stay hydrated and include fibre-rich foods.',
  'Try a 3-minute breathing break between tasks.',
);
const _pLuteal = _Phase(
  'Winding down (estimated)',
  Icons.nights_stay_outlined,
  'Restorative yoga or a gentle walk can feel better as energy dips.',
  'Magnesium-rich foods like banana, pumpkin seeds and whole grains may ease PMS.',
  'Wind down earlier and go easy on evening caffeine.',
);
const _pLate = _Phase(
  'Past your usual length',
  Icons.schedule,
  'Keep moving in whatever way feels comfortable.',
  'Regular meals and plenty of water help.',
  'Stress, sleep and travel can shift a cycle. That can happen.',
);
const _pNone = _Phase(
  'Getting started',
  Icons.auto_awesome_outlined,
  'Short walks and stretching are a gentle place to start.',
  'A balanced plate with iron and calcium sources is a good base.',
  'Try a short breathing exercise in the Wellness tab.',
);

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  HerData? d;
  bool _failed = false;

  static const _short = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  static const _letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _load();
    TabNav.index.addListener(_onTab);
  }

  @override
  void dispose() {
    TabNav.index.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (TabNav.index.value == 0) _load();
  }

  Future<void> _load() async {
    try {
      final data = await HerData.load();
      if (!mounted) return;
      setState(() {
        d = data;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (d == null) {
        setState(() => _failed = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't refresh. Showing saved data.")),
        );
      }
    }
  }

  Future<void> _logPeriod() async {
    final data = d;
    if (data == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: data.today,
      firstDate: DateTime(2000),
      lastDate: data.today,
    );
    if (picked == null) return;
    await HerData.addPeriod(picked);
    _load();
  }

  Future<void> _checkIn() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
    _load();
  }

  void _openAsk() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AskTab()),
    );
  }

  // ---------- helpers ----------
  String _day(DateTime x) => '${x.day} ${_short[x.month - 1]}';
  String _key(DateTime x) => DateTime(x.year, x.month, x.day).toIso8601String();

  /// End of a period. If she hasn't set one, assume 5 days (same as before).
  DateTime _end(HerData d, DateTime s) =>
      d.ends[s.toIso8601String()] ?? DateTime(s.year, s.month, s.day + 4);

  int? _periodDay(HerData d) {
    final last = d.last;
    if (last == null) return null;
    final end = _end(d, last);
    if (!d.today.isBefore(last) && !d.today.isAfter(end)) {
      return d.today.difference(last).inDays + 1;
    }
    return null;
  }

  _Phase _phase(HerData d, int? periodDay, int cycle) {
    if (periodDay != null) return _pPeriod;
    if (d.cycleDay <= 0) return _pNone;
    if (d.cycleDay > cycle) return _pLate;
    final f = d.cycleDay / cycle;
    if (f < 0.45) return _pFollicular;
    if (f < 0.6) return _pMid;
    return _pLuteal;
  }

  // ---------- sections ----------
  Widget _hero(HerData d, int cycle, int? periodDay, _Phase phase) {
    final today = d.today;
    final has = d.cycleDay > 0;

    String headline;
    String sub;
    if (periodDay != null) {
      headline = 'Period day $periodDay';
      sub = 'Be gentle with yourself today';
    } else if (d.next != null) {
      final toNext = d.next!.difference(today).inDays;
      if (toNext > 0) {
        headline = 'Next period around ${_day(d.next!)}';
        sub = 'In about $toNext days';
      } else if (toNext == 0) {
        headline = 'Next period around today';
        sub = 'It can arrive a day or two either side';
      } else {
        headline = 'Period may be a little late';
        sub = 'Predicted ${-toNext} days ago. That can happen.';
      }
    } else {
      headline = 'Log your first period';
      sub = 'Tap Log period to get started';
    }

    final progress = has ? (d.cycleDay / cycle).clamp(0.0, 1.0).toDouble() : 0.0;

    return _Card(
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFFFE9EC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: kBlush,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(phase.icon, size: 14, color: kWine),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              phase.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: kWine,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: kWine,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 92,
                height: 92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => CircularProgressIndicator(
                          value: v,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Colors.white,
                          color: kWine,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          has ? 'Day ${d.cycleDay}' : '--',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: kWine,
                          ),
                        ),
                        if (has)
                          Text(
                            d.cycleDay > cycle ? 'usual $cycle' : 'of $cycle',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.black54),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline, color: kWine, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  HealthFacts.forToday(d.stage, today),
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quick(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: _Card(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: kBlush,
              child: Icon(icon, color: kWine, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickRow() => Row(
        children: [
          _quick(Icons.water_drop_outlined, 'Log period', _logPeriod),
          const SizedBox(width: 10),
          _quick(Icons.edit_calendar_outlined, 'Check-in', _checkIn),
          const SizedBox(width: 10),
          _quick(Icons.spa_outlined, 'Calm', () => TabNav.index.value = 2),
          const SizedBox(width: 10),
          _quick(Icons.calendar_month_outlined, 'Calendar',
              () => TabNav.index.value = 1),
        ],
      );

  Widget _checkInCard(HerData d) {
    return _Card(
      onTap: _checkIn,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: kBlush,
            child: Icon(Icons.mood_outlined, color: kWine),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's check-in",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  d.mood ?? 'Not logged yet. Takes 10 seconds.',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kWine),
        ],
      ),
    );
  }

  /// This week, Monday to Sunday: period days, predicted range, today.
  Widget _week(HerData d) {
    final today = d.today;
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));

    final periodDays = <String>{};
    for (final s in d.periods) {
      var c = DateTime(s.year, s.month, s.day);
      final e = _end(d, s);
      while (!c.isAfter(e)) {
        periodDays.add(_key(c));
        c = DateTime(c.year, c.month, c.day + 1);
      }
    }
    final next = d.next == null
        ? null
        : DateTime(d.next!.year, d.next!.month, d.next!.day);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your week',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final x = DateTime(monday.year, monday.month, monday.day + i);
              final isPeriod = periodDays.contains(_key(x));
              final isPred = !isPeriod &&
                  next != null &&
                  x.difference(next).inDays.abs() <= 2;
              final isToday = x == today;
              return Column(
                children: [
                  Text(_letters[i],
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPeriod
                          ? kWine
                          : (isPred ? kBlush : const Color(0xFFF7F2F2)),
                      border: isToday
                          ? Border.all(color: kWine, width: 2)
                          : null,
                    ),
                    child: Text(
                      '${x.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.normal,
                        color: isPeriod ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: kWine),
              SizedBox(width: 6),
              Text('Period', style: TextStyle(fontSize: 12)),
              SizedBox(width: 16),
              Icon(Icons.circle, size: 10, color: kBlush),
              SizedBox(width: 6),
              Text('Predicted range', style: TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _insight(HerData d) {
    final lengths = d.lengths;
    if (lengths.length < 3) {
      final left = 3 - lengths.length;
      return _InsightCard(
        title: 'Your pattern',
        text: 'Log $left more ${left == 1 ? 'cycle' : 'cycles'} to unlock '
            'your pattern insights.',
        progress: lengths.length / 3,
        why: 'We need at least 3 cycles before calling anything a pattern. '
            'With fewer, the numbers can mislead.',
      );
    }
    final lo = lengths.reduce((a, b) => a < b ? a : b);
    final hi = lengths.reduce((a, b) => a > b ? a : b);
    final spread = hi - lo;
    final text = spread <= 7
        ? 'Your last ${lengths.length} cycles ranged from $lo to $hi days. '
            'That is fairly consistent.'
        : 'Your cycles ranged from $lo to $hi days. They vary quite a bit, '
            'and logging a few more will help us see your pattern.';
    return _InsightCard(
      title: 'Your pattern',
      text: text,
      why: 'This comes only from the period dates you logged. It is not a '
          'diagnosis. If something worries you, talk to a doctor.',
    );
  }

  Widget _feelingOff() {
    return _Card(
      onTap: _openAsk,
      color: kBlush,
      child: Row(
        children: [
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.favorite_border, color: kWine),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Feeling off?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 3),
                Text('Tell us what is going on. Information, not a diagnosis.',
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kWine),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: _Card(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: kWine),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(HerData d) {
    final cycle = d.avg > 0 ? d.avg.round() : 28;
    final periodDay = _periodDay(d);
    final phase = _phase(d, periodDay, cycle);
    const gap = SizedBox(height: 14);

    return [
      _hero(d, cycle, periodDay, phase),
      gap,
      _quickRow(),
      gap,
      _checkInCard(d),
      gap,
      _week(d),
      gap,
      _TipCard(phase: phase, onAsk: _openAsk),
      gap,
      _insight(d),
      gap,
      _feelingOff(),
      if (d.last != null) ...[
        gap,
        Row(
          children: [
            _stat('Last period', _day(d.last!)),
            const SizedBox(width: 10),
            _stat('Cycles', '${d.lengths.length}'),
            const SizedBox(width: 10),
            _stat('Average',
                d.lengths.isEmpty ? '--' : '${d.avg.round()} d'),
          ],
        ),
      ],
      const SizedBox(height: 18),
      const Center(
        child: Text(
          'Every entry helps your predictions get better.\n'
          'Awareness only, not a diagnosis.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.black45, height: 1.4),
        ),
      ),
    ];
  }

  List<Widget> _loading() => const [
        _Pulse(height: 190),
        SizedBox(height: 14),
        _Pulse(height: 90),
        SizedBox(height: 14),
        _Pulse(height: 80),
        SizedBox(height: 14),
        _Pulse(height: 130),
      ];

  List<Widget> _error() => [
        _Card(
          color: const Color(0xFFFFF4E5),
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: kWine),
              const SizedBox(width: 12),
              const Expanded(
                child: Text("Couldn't load your data. Check the server and try again."),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _failed = false);
                  _load();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final data = d;
    final List<Widget> body = data != null
        ? _content(data)
        : (_failed ? _error() : _loading());

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              const HerLifeHeader(),
              const SizedBox(height: 16),
              ...body,
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================================
// Small widgets used only on Home
// =====================================================================

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsets padding;

  const _Card({
    required this.child,
    this.onTap,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? Colors.white) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kWine.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: padding,
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      ),
    );
  }
}

/// Today's tip with Move / Eat / Calm switcher and an Ask button.
class _TipCard extends StatefulWidget {
  final _Phase phase;
  final VoidCallback onAsk;
  const _TipCard({required this.phase, required this.onAsk});

  @override
  State<_TipCard> createState() => _TipCardState();
}

class _TipCardState extends State<_TipCard> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.phase;
    final tips = [p.move, p.eat, p.calm];
    const names = ['Move', 'Eat', 'Calm'];
    const icons = [
      Icons.self_improvement,
      Icons.restaurant_outlined,
      Icons.spa_outlined
    ];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tips_and_updates_outlined, color: kWine),
              SizedBox(width: 8),
              Text("Today's tip",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (i) {
              final on = i == _i;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _i = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: on ? kWine : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: on ? kWine : const Color(0xFFF1D6DA)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icons[i],
                            size: 15, color: on ? Colors.white : kWine),
                        const SizedBox(width: 5),
                        Text(
                          names[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: on ? Colors.white : kWine,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              tips[_i],
              key: ValueKey(_i),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onAsk,
            icon: const Icon(Icons.chat_bubble_outline, size: 18),
            label: const Text('Ask about this'),
            style: TextButton.styleFrom(
              foregroundColor: kWine,
              backgroundColor: kBlush,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}

/// One insight with an optional progress bar and a "Why am I seeing this?" panel.
class _InsightCard extends StatefulWidget {
  final String title;
  final String text;
  final String why;
  final double? progress;
  const _InsightCard({
    required this.title,
    required this.text,
    required this.why,
    this.progress,
  });

  @override
  State<_InsightCard> createState() => _InsightCardState();
}

class _InsightCardState extends State<_InsightCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: () => setState(() => _open = !_open),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined, color: kWine),
              const SizedBox(width: 8),
              Text(widget.title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Text(widget.text, style: const TextStyle(fontSize: 14, height: 1.4)),
          if (widget.progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: widget.progress,
                minHeight: 8,
                backgroundColor: kBlush,
                color: kWine,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Why am I seeing this?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kWine.withValues(alpha: 0.9),
                ),
              ),
              Icon(_open ? Icons.expand_less : Icons.expand_more,
                  size: 18, color: kWine),
            ],
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(widget.why,
                  style: const TextStyle(fontSize: 12.5, color: Colors.black54)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing grey placeholder while Home loads (no extra package).
class _Pulse extends StatefulWidget {
  final double height;
  const _Pulse({required this.height});

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Color.lerp(
              const Color(0xFFF0E8E8), const Color(0xFFFBF5F5), _c.value),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}