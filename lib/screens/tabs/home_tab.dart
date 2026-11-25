import 'package:flutter/material.dart';
import 'package:herlife/core/health_facts.dart';
import 'package:herlife/core/tab_nav.dart';
import 'package:herlife/main.dart' show CheckInScreen;
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_header.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  HerData? d;

  static const _short = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _load();
    // Reload when the user comes back to this tab.
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
    final data = await HerData.load();
    if (mounted) setState(() => d = data);
  }

  Future<void> _logPeriod() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: d!.today,
      firstDate: DateTime(2000),
      lastDate: d!.today,
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

  String _day(DateTime x) => '${x.day} ${_short[x.month - 1]}';

  Widget _topCard(HerData d) {
    final today = d.today;
    final cycle = d.avg.round();
    final has = d.cycleDay > 0;
    final last = d.last;

    // Are we inside a period right now?
    int? periodDay;
    if (last != null) {
      final end =
          d.ends[last.toIso8601String()] ?? last.add(const Duration(days: 4));
      if (!today.isBefore(last) && !today.isAfter(end)) {
        periodDay = today.difference(last).inDays + 1;
      }
    }

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
      sub = 'Tap the calendar to get started';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Material(
                      color: kBlush,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => TabNav.index.value = 1,
                        borderRadius: BorderRadius.circular(14),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(
                            Icons.calendar_month_outlined,
                            color: kWine,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      headline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: kWine,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: has ? (d.cycleDay / cycle).clamp(0.0, 1.0) : 0,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                        backgroundColor: kBlush,
                        color: kWine,
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
                        Text(
                          has
                              ? (d.cycleDay > cycle
                                  ? 'usual $cycle'
                                  : 'of $cycle')
                              : '',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
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

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: kBlush,
              child: Icon(icon, color: kWine, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kWine,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = d;

    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const HerLifeHeader(subtitle: 'Home'),
              const SizedBox(height: 16),
              _topCard(data),
              const SizedBox(height: 14),
              Row(
                children: [
                  _action(Icons.water_drop_outlined, 'Log Period', _logPeriod),
                  const SizedBox(width: 10),
                  _action(
                    Icons.edit_calendar_outlined,
                    'Daily Check-in',
                    _checkIn,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                onTap: _checkIn,
                child: Row(
                  children: [
                    const Icon(Icons.mood_outlined, color: kWine, size: 32),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Today's check-in",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data.mood ?? 'Not logged yet',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
              if (data.last != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _stat('Last period', data.fmt(data.last!))),
                    const SizedBox(width: 10),
                    Expanded(child: _stat('Cycles', '${data.lengths.length}')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}