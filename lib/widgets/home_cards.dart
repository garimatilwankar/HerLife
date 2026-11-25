import 'package:flutter/material.dart';
import '../core/design_tokens.dart';
import 'her_components.dart';

/// Gradient hero card for the top of Home (wrap your existing ring + fact in it).
class HeroCard extends StatelessWidget {
  final Widget child;
  const HeroCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => HerCard(
        gradient: const LinearGradient(
          colors: [Colors.white, HL.blushSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: child,
      );
}

/// "Your week at a glance": 7 dots, one per day.
/// moods: 7 values, 0 = not logged, 1 (low) to 5 (great). Oldest first.
class WeekGlance extends StatelessWidget {
  final List<int> moods;
  final List<String> dayLetters; // e.g. ['M','T','W','T','F','S','S']
  const WeekGlance({super.key, required this.moods, required this.dayLetters});

  Color _dot(int m) {
    if (m == 0) return HL.line;
    if (m <= 2) return const Color(0xFFE8A5B0);
    if (m == 3) return const Color(0xFFD1687E);
    return HL.wine;
  }

  @override
  Widget build(BuildContext context) => HerCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Your week at a glance', style: HL.section),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final m = i < moods.length ? moods[i] : 0;
              return Column(children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration:
                      BoxDecoration(color: _dot(m), shape: BoxShape.circle),
                ),
                const SizedBox(height: 6),
                Text(i < dayLetters.length ? dayLetters[i] : '',
                    style: HL.caption),
              ]);
            }),
          ),
          const SizedBox(height: 8),
          const Text('Darker means a better mood day. Empty means not logged.',
              style: HL.caption),
        ]),
      );
}

/// Today's tip with an "Ask about this" button.
class TipCard extends StatelessWidget {
  final String tip;
  final VoidCallback onAsk;
  const TipCard({super.key, required this.tip, required this.onAsk});

  @override
  Widget build(BuildContext context) => HerCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: const [
            Icon(Icons.lightbulb_outline, color: HL.wine),
            SizedBox(width: 8),
            Text("Today's tip", style: HL.section),
          ]),
          const SizedBox(height: 8),
          Text(tip, style: HL.body),
          const SizedBox(height: 12),
          HerButton(
              label: 'Ask about this',
              icon: Icons.chat_bubble_outline,
              soft: true,
              onPressed: onAsk),
        ]),
      );
}

/// "Feeling off?" shortcut (opens symptom guide later; for now Ask or Learn).
class FeelingOffCard extends StatelessWidget {
  final VoidCallback onTap;
  const FeelingOffCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) => HerCard(
        onTap: onTap,
        color: HL.blush,
        child: Row(children: const [
          CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.healing, color: HL.wine)),
          SizedBox(width: 12),
          Expanded(
              child: Text('Feeling off today?\nTell us what is going on.',
                  style: HL.body)),
          Icon(Icons.chevron_right, color: HL.wine),
        ]),
      );
}

/* ------------------------------------------------------------------
HOW TO WIRE EACH TAB (replace your current header block)

HOME
  HerTabScaffold(
    header: HerLifeHeader.home(name: user.name, stage: stageLabel, onAsk: openAsk),
    body: ListView(padding: const EdgeInsets.all(HL.pad), children: [
      HeroCard(child: /* your existing period day + ring + fact */),
      const SizedBox(height: HL.gap),
      /* Log Period + Daily Check-in row (HerCard each) */
      const SizedBox(height: HL.gap),
      WeekGlance(moods: last7Moods, dayLetters: letters),
      const SizedBox(height: HL.gap),
      TipCard(tip: todaysTip, onAsk: openAsk),
      const SizedBox(height: HL.gap),
      FeelingOffCard(onTap: openLearnOrAsk),
      const SizedBox(height: 90), // clear the bottom bar
    ]),
  )

TRACK     header: HerLifeHeader(title: 'Track',    stage: stageLabel, onAsk: openAsk)
WELLNESS  header: HerLifeHeader(title: 'Wellness', stage: stageLabel, onAsk: openAsk)
LEARN     header: HerLifeHeader(title: 'Learn',    stage: stageLabel, onAsk: openAsk)
SETTINGS  header: HerLifeHeader(title: 'Settings', stage: stageLabel)

TRACK: give the ListView bottom padding of 100 so the floating
"Log period" button never covers the last card.

BOTTOM BAR (fixes clipped "Settings"): in your NavigationBar theme use
  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
  and labelTextStyle with fontSize 11, maxLines 1.
------------------------------------------------------------------- */