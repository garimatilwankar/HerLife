import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';

class TrackTab extends StatefulWidget {
  const TrackTab({super.key});

  @override
  State<TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<TrackTab> {
  HerData? d;
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await HerData.load();
    if (mounted) setState(() => d = data);
  }

  Future<void> _add() async {
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

  Future<void> _end(DateTime start) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start,
      lastDate: d!.today,
    );
    if (picked == null) return;
    await HerData.setEnd(start, picked);
    _load();
  }

  bool _isPeriod(HerData d, DateTime x) => d.periods.any((s) {
        final e = d.ends[s.toIso8601String()] ?? s;
        return !x.isBefore(s) && !x.isAfter(e);
      });

  Widget _calendar(HerData d) {
    final now = d.today;
    final offset = DateTime(now.year, now.month, 1).weekday - 1;
    final count = DateTime(now.year, now.month + 1, 0).day;
    final next = d.next;

    final cells = <Widget>[
      for (final l in ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
            child: Text(l,
                style: const TextStyle(fontSize: 12, color: Colors.black54))),
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var day = 1; day <= count; day++)
        Builder(builder: (_) {
          final x = DateTime(now.year, now.month, day);
          final period = _isPeriod(d, x);
          final predicted = next != null && x == next;
          final isToday = x == now;
          return Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: period ? kWine : (predicted ? kBlush : null),
                border: isToday ? Border.all(color: kWine, width: 1.5) : null,
              ),
              child: Text('$day',
                  style: TextStyle(
                      fontSize: 13,
                      color: period ? Colors.white : Colors.black87)),
            ),
          );
        }),
    ];

    return AppCard(
      child: Column(children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('${_months[now.month - 1]} ${now.year}',
              style:
                  const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
        const SizedBox(height: 8),
        const Row(children: [
          Icon(Icons.circle, size: 10, color: kWine),
          SizedBox(width: 6),
          Text('Period', style: TextStyle(fontSize: 12)),
          SizedBox(width: 16),
          Icon(Icons.circle, size: 10, color: kBlush),
          SizedBox(width: 6),
          Text('Predicted', style: TextStyle(fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _stat(String label, String value) => Expanded(
        child: AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: kWine)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final data = d;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      backgroundColor: kBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        backgroundColor: kWine,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log period'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
          children: [
            const ScreenTitle('Track'),
            const SizedBox(height: 16),
            Row(children: [
              _stat('Cycle day', data.cycleDay > 0 ? '${data.cycleDay}' : '--'),
              const SizedBox(width: 10),
              _stat('Next',
                  data.next == null ? '--' : '${data.next!.day}/${data.next!.month}'),
              const SizedBox(width: 10),
              _stat('Average', '${data.avg.round()} d'),
            ]),
            const SizedBox(height: 14),
            _calendar(data),
            const SizedBox(height: 18),
            const Text('History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (data.periods.isEmpty)
              const AppCard(child: Text('No periods logged')),
            for (final s in data.periods)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(children: [
                    const Icon(Icons.water_drop_outlined, color: kWine),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(data.fmt(s),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600))),
                    if (data.ends[s.toIso8601String()] != null)
                      Pill(
                          '${data.ends[s.toIso8601String()]!.difference(s).inDays + 1} days')
                    else
                      TextButton(
                          onPressed: () => _end(s),
                          child: const Text('Add end')),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
