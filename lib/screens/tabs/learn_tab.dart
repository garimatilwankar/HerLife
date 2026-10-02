import 'package:flutter/material.dart';
import 'package:herlife/screens/tabs/ui.dart';

class _Topic {
  final String title, tag, hint;
  final IconData icon;
  final List<String> points;
  const _Topic(this.title, this.tag, this.hint, this.icon, this.points);
}

const _topics = [
  _Topic('Cycle basics', 'Cycle', 'How cycles are counted', Icons.loop, [
    'Count from day 1 of one period to day 1 of the next',
    'Most adult cycles are 21 to 35 days',
    'Periods usually last 2 to 7 days',
    'Small changes month to month are normal',
  ]),
  _Topic('Cycle phases', 'Cycle', 'Four phases explained', Icons.spa_outlined, [
    'Menstrual: bleeding days',
    'Follicular: body prepares an egg',
    'Ovulation: egg is released',
    'Luteal: body prepares for next period',
  ]),
  _Topic('Irregular periods', 'Cycle', 'Common causes', Icons.shuffle, [
    'Stress, sleep and weight changes',
    'Illness or some medicines',
    'Common in the first years and near menopause',
    'See a clinician if several periods are missed',
  ]),
  _Topic('Cramps', 'Symptoms', 'What helps', Icons.healing_outlined, [
    'Mild to moderate cramps are common',
    'Heat, rest and gentle movement help many people',
    'Severe or worsening pain needs a clinician',
  ]),
  _Topic('Heavy periods', 'Symptoms', 'When to get checked', Icons.water_drop_outlined, [
    'Soaking a pad or tampon every hour for hours',
    'Clots larger than a coin',
    'Bleeding longer than 7 days',
    'Can cause low iron and tiredness',
  ]),
  _Topic('PMS', 'Symptoms', 'Before your period', Icons.mood_outlined, [
    'Mood changes, bloating, tender breasts',
    'Usually ease once bleeding starts',
    'Severe mood symptoms deserve support',
  ]),
  _Topic('Pregnancy care', 'Life stages', 'Warning signs', Icons.pregnant_woman, [
    'Severe headache or vision changes',
    'Bleeding or belly pain',
    'Less movement from the baby',
    'Contact your provider promptly',
  ]),
  _Topic('Perimenopause', 'Life stages', 'The transition', Icons.timelapse, [
    'Often starts in the 40s',
    'Cycles become less predictable',
    'Hot flashes, sleep and mood changes',
    'Tracking helps your clinician',
  ]),
];

class LearnTab extends StatefulWidget {
  const LearnTab({super.key});

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  String _tag = 'All';
  String _query = '';

  void _open(_Topic t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: kWine)),
            const SizedBox(height: 14),
            for (final p in t.points)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(Icons.circle, size: 7, color: kWine),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(p)),
                    ]),
              ),
            const SizedBox(height: 4),
            const Text('Information only, not a diagnosis',
                style: TextStyle(fontSize: 12, color: Colors.black45)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shown = _topics.where((t) {
      final tagOk = _tag == 'All' || t.tag == _tag;
      final q = _query.toLowerCase();
      return tagOk && (q.isEmpty || t.title.toLowerCase().contains(q));
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const ScreenTitle('Learn'),
          const SizedBox(height: 14),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search topics',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final tag in ['All', 'Cycle', 'Symptoms', 'Life stages'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Pill(tag,
                      selected: _tag == tag,
                      onTap: () => setState(() => _tag = tag)),
                ),
            ]),
          ),
          const SizedBox(height: 14),
          if (shown.isEmpty) const Center(child: Text('No topics found')),
          for (final t in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => _open(t),
                child: Row(children: [
                  CircleAvatar(
                      backgroundColor: kBlush,
                      child: Icon(t.icon, color: kWine, size: 20)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(t.hint,
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black54)),
                        ]),
                  ),
                  const Icon(Icons.chevron_right),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
