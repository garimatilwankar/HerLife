import 'package:flutter/material.dart';
import 'package:herlife/main.dart' show CheckInScreen;
import 'package:herlife/screens/lifecycle_screen.dart';
import 'package:herlife/screens/settings_screen.dart';
import 'package:herlife/screens/tabs/ui.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  HerData? d;

  @override
  void initState() {
    super.initState();
    _load();
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
      MaterialPageRoute(
        builder: (_) => const CheckInScreen(),
      ),
    );

    _load();
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SettingsScreen(),
      ),
    ).then((_) => _load());
  }

  Widget _ring(HerData d) {
    final has = d.cycleDay > 0;
    final cycle = d.avg.round();
    final toNext = d.next?.difference(d.today).inDays;

    return AppCard(
      child: Column(
        children: [
          SizedBox(
            width: 190,
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: has
                        ? (d.cycleDay / cycle).clamp(0.0, 1.0)
                        : 0,
                    strokeWidth: 12,
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
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: kWine,
                      ),
                    ),
                    Text(
                      has ? 'of $cycle' : 'Log a period',
                      style: const TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              Pill(
                d.phase,
                selected: true,
                icon: Icons.spa_outlined,
              ),
              if (toNext != null)
                Pill(
                  toNext >= 0
                      ? 'Next in $toNext d'
                      : 'Late by ${-toNext} d',
                  icon: Icons.event_outlined,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              backgroundColor: kBlush,
              child: Icon(
                icon,
                color: kWine,
                size: 20,
              ),
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

  @override
  Widget build(BuildContext context) {
    final data = d;

    if (data == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ScreenTitle(
                      'Hi, ${data.name ?? 'there'}',
                      trailing: Pill(
                        data.stage ?? 'Set stage',
                        icon: Icons.favorite_border,
                        onTap: () =>
                            Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LifecycleScreen(),
                          ),
                          (r) => false,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _openSettings,
                      borderRadius: BorderRadius.circular(14),
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(
                          Icons.settings_outlined,
                          color: kWine,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ring(data),
              const SizedBox(height: 14),
              Row(
                children: [
                  _action(
                    Icons.water_drop_outlined,
                    'Log period',
                    _logPeriod,
                  ),
                  const SizedBox(width: 10),
                  _action(
                    Icons.edit_calendar_outlined,
                    'Check-in',
                    _checkIn,
                  ),
                  const SizedBox(width: 10),
                  _action(
                    Icons.monitor_heart_outlined,
                    'Symptoms',
                    _checkIn,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              AppCard(
                onTap: _checkIn,
                child: Row(
                  children: [
                    const Icon(
                      Icons.mood_outlined,
                      color: kWine,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
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
                            style: const TextStyle(
                              color: Colors.black54,
                            ),
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
                    Expanded(
                      child: _stat(
                        'Last period',
                        data.fmt(data.last!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(
                        'Cycles',
                        '${data.lengths.length}',
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
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
}