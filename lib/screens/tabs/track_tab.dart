import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_header.dart';

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

  // ---------- Calendar ----------
  Widget _calendar(HerData d) {
    final now = d.today;
    final offset = DateTime(now.year, now.month, 1).weekday - 1;
    final count = DateTime(now.year, now.month + 1, 0).day;
    final next = d.next;

    final Set<String> periodIsoDates = {};
    for (final s in d.periods) {
      final e = d.ends[s.toIso8601String()] ?? s;
      var curr = s;
      while (!curr.isAfter(e)) {
        periodIsoDates
            .add(DateTime(curr.year, curr.month, curr.day).toIso8601String());
        curr = curr.add(const Duration(days: 1));
      }
    }

    final cells = <Widget>[
      for (final l in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
        Center(
            child: Text(l,
                style: const TextStyle(fontSize: 12, color: Colors.black54))),
      for (var i = 0; i < offset; i++) const SizedBox.shrink(),
      for (var day = 1; day <= count; day++)
        Builder(builder: (_) {
          final x = DateTime(now.year, now.month, day);
          final period = periodIsoDates.contains(x.toIso8601String());
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

  // ---------- Small pieces ----------
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

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  Widget _bars(List<int> lengths) {
    final shown =
        lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    final maxLen = shown.reduce((a, b) => a > b ? a : b);
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Cycle length',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final l in shown)
                Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text('$l', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 90 * l / maxLen,
                    decoration: BoxDecoration(
                      color: kWine,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ]),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _chips(String title, IconData icon, List<String> items, String empty) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: kWine, size: 20),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(empty, style: const TextStyle(color: Colors.black54))
        else
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in items) Pill(s, selected: true),
          ]),
      ]),
    );
  }

  // ---------- Sections ----------
  Widget _history(HerData data) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('History'),
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
                      style: const TextStyle(fontWeight: FontWeight.w600))),
              if (data.ends[s.toIso8601String()] != null)
                Pill(
                    '${data.ends[s.toIso8601String()]!.difference(s).inDays + 1} days')
              else
                TextButton(
                    onPressed: () => _end(s), child: const Text('Add end')),
            ]),
          ),
        ),
    ]);
  }

  Widget _patterns(HerData data) {
    final lengths = data.lengths;
    final all = {...data.symptoms, ...data.checkInSymptoms}.toList();
    final spread = lengths.isEmpty
        ? 0
        : lengths.reduce((a, b) => a > b ? a : b) -
            lengths.reduce((a, b) => a < b ? a : b);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionTitle('Your patterns'),
      if (lengths.isEmpty)
        const AppCard(
          child: Row(children: [
            Icon(Icons.insights_outlined, color: kWine, size: 32),
            SizedBox(width: 14),
            Expanded(child: Text('Log 2 periods to see patterns')),
          ]),
        )
      else ...[
        Row(children: [
          _stat('Average', '${data.avg.round()} d'),
          const SizedBox(width: 10),
          _stat('Shortest', '${lengths.reduce((a, b) => a < b ? a : b)} d'),
          const SizedBox(width: 10),
          _stat('Longest', '${lengths.reduce((a, b) => a > b ? a : b)} d'),
        ]),
        const SizedBox(height: 14),
        _bars(lengths),
        const SizedBox(height: 14),
        AppCard(
          child: Row(children: [
            Icon(spread <= 7 ? Icons.check_circle_outline : Icons.info_outline,
                color: kWine),
            const SizedBox(width: 12),
            Expanded(
                child: Text(spread <= 7
                    ? 'Fairly consistent'
                    : 'Varies by $spread days')),
          ]),
        ),
      ],
      const SizedBox(height: 14),
      _chips('Symptoms', Icons.monitor_heart_outlined, all, 'None logged'),
      const SizedBox(height: 14),
      _chips('Latest mood', Icons.mood_outlined,
          data.mood == null ? [] : [data.mood!], 'No check-in yet'),
    ]);
  }

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
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
            children: [
              const HerLifeHeader(subtitle: 'Track'),
              const SizedBox(height: 16),
              Row(children: [
                _stat('Cycle day',
                    data.cycleDay > 0 ? '${data.cycleDay}' : '--'),
                const SizedBox(width: 10),
                _stat(
                    'Next',
                    data.next == null
                        ? '--'
                        : '${data.next!.day}/${data.next!.month}'),
                const SizedBox(width: 10),
                _stat('Average', '${data.avg.round()} d'),
              ]),
              const SizedBox(height: 14),
              _calendar(data),
              const SizedBox(height: 18),
              _history(data),
              const SizedBox(height: 18),
              _patterns(data),
              const SizedBox(height: 18),
              const Center(
                child: Text('Awareness only, not a diagnosis',
                    style: TextStyle(fontSize: 12, color: Colors.black45)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}