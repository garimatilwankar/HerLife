import 'package:flutter/material.dart';
import 'package:herlife/core/onboarding_store.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/widgets/herlife_logo.dart';

/// Six swipeable cards that show a first-time user around the app.
/// Shown once after the onboarding questions. [onDone] runs on finish or skip.
class TutorialScreen extends StatefulWidget {
  final VoidCallback onDone;
  const TutorialScreen({super.key, required this.onDone});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialCard {
  final IconData icon;
  final String title;
  final String text;
  final Widget? visual;
  const _TutorialCard({
    required this.icon,
    required this.title,
    required this.text,
    this.visual,
  });
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// A small copy of the header with the Ask button highlighted.
  Widget _askMock() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: kWine.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const HerLifeLogoMark(size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Home',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kWine,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kBlush,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kWine, width: 2),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: kWine),
          ),
        ],
      ),
    );
  }

  List<_TutorialCard> _cards() => [
        const _TutorialCard(
          icon: Icons.home_outlined,
          title: 'Your day at a glance',
          text: 'Home shows where you are in your cycle, a tip for today and '
              'quick buttons to log your period or check in.',
        ),
        const _TutorialCard(
          icon: Icons.calendar_month_outlined,
          title: 'Track and see your patterns',
          text: 'Log periods and symptoms on the calendar. Your patterns '
              'build up here as you log more cycles.',
        ),
        const _TutorialCard(
          icon: Icons.self_improvement,
          title: 'Move, eat and calm',
          text: 'Wellness has workout videos, a food quiz that suits your '
              'allergies and preferences, and soothing breathing exercises.',
        ),
        const _TutorialCard(
          icon: Icons.menu_book_outlined,
          title: 'Read about your stage or a problem',
          text: 'Want to read about your life stage or something you are '
              'dealing with? Open the Learn tab to find articles for you.',
        ),
        _TutorialCard(
          icon: Icons.chat_bubble_outline,
          title: 'Ask is at the top right',
          text: 'Tap the chat icon on any screen to ask a question. '
              'Answers are information, not a diagnosis.',
          visual: _askMock(),
        ),
        const _TutorialCard(
          icon: Icons.settings_outlined,
          title: 'Make it yours',
          text: 'Change your life stage and update your preferences any '
              'time from Settings.',
        ),
      ];

  Future<void> _finish() async {
    await OnboardingStore.markTutorialDone();
    if (!mounted) return;
    widget.onDone();
  }

  void _next(int total) {
    if (_page >= total - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _cards();
    final isLast = _page == cards.length - 1;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Row(
                children: [
                  const HerLifeLogoMark(size: 28),
                  const Spacer(),
                  if (!isLast)
                    TextButton(onPressed: _finish, child: const Text('Skip')),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: cards.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final c = cards[i];
                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (c.visual != null)
                            c.visual!
                          else
                            Container(
                              width: 130,
                              height: 130,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [Colors.white, kBlush],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(c.icon, size: 60, color: kWine),
                            ),
                          const SizedBox(height: 32),
                          Text(
                            c.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: kWine,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            c.text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(cards.length, (i) {
                final on = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: on ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: on ? kWine : kBlush,
                    borderRadius: BorderRadius.circular(8),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: ElevatedButton(
                onPressed: () => _next(cards.length),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kWine,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26)),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: Text(isLast ? 'Get started' : 'Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}