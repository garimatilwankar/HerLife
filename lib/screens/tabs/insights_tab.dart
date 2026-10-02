import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';

class InsightsTab extends StatefulWidget {
  const InsightsTab({super.key});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  HerData? d;

  @override
  void initState() {
    super.initState();
    HerData.load().then((v) {
      if (mounted) setState(() => d = v);
    });
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
                    fontSize: 20, fontWeight: FontWeight.bold, color: kWine)),
          ]),
        ),
      );

  Widget _bars(List<int> lengths) {
    final shown = lengths.length > 6
        ? lengths.sublist(lengths.length - 6)
        : lengths;
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

  @override
  Widget build(BuildContext context) {
    final data = d;
    if (data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final lengths = data.lengths;
    final all = {...data.symptoms, ...data.checkInSymptoms}.toList();
    final spread = lengths.isEmpty
        ? 0
        : lengths.reduce((a, b) => a > b ? a : b) -
            lengths.reduce((a, b) => a < b ? a : b);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const ScreenTitle('Insights'),
          const SizedBox(height: 16),
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
              _stat('Shortest',
                  '${lengths.reduce((a, b) => a < b ? a : b)} d'),
              const SizedBox(width: 10),
              _stat('Longest',
                  '${lengths.reduce((a, b) => a > b ? a : b)} d'),
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
          const SizedBox(height: 18),
          const Center(
            child: Text('Awareness only, not a diagnosis',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ),
        ]),
      ),
    );
  }
}
