import 'package:flutter/material.dart';
import 'package:herlife/core/tab_nav.dart';
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Home card for users who answered Yes or Not sure to PCOS / PCOD.
/// Shows nothing for everyone else. Information only, never a diagnosis.
class PcosCard extends StatefulWidget {
  const PcosCard({super.key});

  @override
  State<PcosCard> createState() => _PcosCardState();
}

class _PcosCardState extends State<PcosCard> {
  String? _status;
  int _tab = 0;

  static const _names = ['Move', 'Eat', 'Calm', 'Track'];
  static const _icons = [
    Icons.self_improvement,
    Icons.restaurant_outlined,
    Icons.spa_outlined,
    Icons.edit_calendar_outlined,
  ];
  static const _tips = [
    'Regular movement you enjoy, like brisk walks, yoga or light strength '
        'work, can help your body use insulin better. Start small and keep '
        'it kind.',
    'Pairing carbs with protein and fibre, for example roti with dal and '
        'sabzi, tends to keep blood sugar steadier through the day.',
    'Poor sleep and high stress can affect hormones. A few slow breaths or '
        'an earlier night is a good place to begin.',
    'Cycles can be longer or less predictable with PCOS / PCOD. Logging '
        'period dates and symptoms gives your doctor a clearer picture.',
  ];

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
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _status = prefs.getString('pcos_status'));
  }

  void _openAsk() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AskTab()),
    );
  }

  Widget _shell(Widget child) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kBlush, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: kWine.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _askButton() {
    return TextButton.icon(
      onPressed: _openAsk,
      icon: const Icon(Icons.chat_bubble_outline, size: 18),
      label: const Text('Ask about this'),
      style: TextButton.styleFrom(
        foregroundColor: kWine,
        backgroundColor: kBlush,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_status == 'not_sure') {
      return _shell(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: kWine),
                SizedBox(width: 8),
                Text('Wondering about PCOS / PCOD?',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Irregular periods, acne and extra hair growth are things many '
              'people ask a doctor about. Only a doctor can tell what is going '
              'on, so keep logging and bring your notes along.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            _askButton(),
          ],
        ),
      );
    }

    if (_status != 'yes') return const SizedBox.shrink();

    return _shell(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_border, color: kWine),
              SizedBox(width: 8),
              Text('Your PCOS / PCOD space',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(4, (i) {
              final on = i == _tab;
              return GestureDetector(
                onTap: () => setState(() => _tab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: on ? kWine : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: on ? kWine : const Color(0xFFF1D6DA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_icons[i],
                          size: 15, color: on ? Colors.white : kWine),
                      const SizedBox(width: 5),
                      Text(
                        _names[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: on ? Colors.white : kWine,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              _tips[_tab],
              key: ValueKey(_tab),
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Talk to a doctor if your periods stop for 3 months or more, or '
            'bleeding is very heavy. Information only, not a diagnosis.',
            style: TextStyle(fontSize: 12, color: Colors.black54, height: 1.4),
          ),
          const SizedBox(height: 12),
          _askButton(),
        ],
      ),
    );
  }
}