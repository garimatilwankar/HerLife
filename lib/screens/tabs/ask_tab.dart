import 'package:flutter/material.dart';
import 'package:herlife/models/api_models.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/services/ask_service.dart';

class _AskMessage {
  final String text;
  final bool fromUser;
  final String? intent;
  final String? safetyLevel;
  final String? disclaimer;
  final bool isError;

  const _AskMessage({
    required this.text,
    required this.fromUser,
    this.intent,
    this.safetyLevel,
    this.disclaimer,
    this.isError = false,
  });
}

class AskTab extends StatefulWidget {
  const AskTab({super.key});

  @override
  State<AskTab> createState() => _AskTabState();
}

class _AskTabState extends State<AskTab> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<_AskMessage> _msgs = [];
  bool _busy = false;

  static const _suggestions = [
    'What is a normal cycle length?',
    'Why is my period late?',
    'How can I ease cramps?',
    'What counts as a heavy period?',
  ];

  @override
  void initState() {
    super.initState();
    _msgs.add(
      const _AskMessage(
        text: 'Hi! Ask me about cycles, health, or symptoms.',
        fromUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;

    _ctrl.clear();

    // Construct recent conversation history (max 10 items) to send to backend
    final recentHistory = _msgs
        .where((m) => !m.isError)
        .toList()
        .reversed
        .take(10)
        .toList()
        .reversed
        .map((m) => ChatMessageItem(
              role: m.fromUser ? 'user' : 'assistant',
              content: m.text,
            ))
        .toList();

    setState(() {
      _msgs.add(_AskMessage(text: t, fromUser: true));
      _busy = true;
    });
    _toEnd();

    try {
      final res = await AskService.askQuestion(t, history: recentHistory);
      if (!mounted) return;
      if (res != null) {
        setState(() {
          _msgs.add(
            _AskMessage(
              text: res.answer,
              fromUser: false,
              intent: res.intent,
              safetyLevel: res.safetyLevel,
              disclaimer: res.disclaimer,
            ),
          );
          _busy = false;
        });
      } else {
        setState(() {
          _msgs.add(
            const _AskMessage(
              text:
                  "I'm having a little trouble responding right now. Please try again in a moment.",
              fromUser: false,
              isError: true,
            ),
          );
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceAll('Exception: ', '');
      final isTechnical = rawError.contains('DioException') ||
          rawError.contains('SocketException') ||
          rawError.contains('HttpException') ||
          rawError.contains('connectTimeout');
      final userMessage = isTechnical
          ? "I'm having a little trouble responding right now. Please try again in a moment."
          : rawError;

      setState(() {
        _msgs.add(
          _AskMessage(
            text: userMessage,
            fromUser: false,
            isError: true,
          ),
        );
        _busy = false;
      });
    }
    _toEnd();
  }

  Widget _bubble(_AskMessage m) {
    final isUrgent = m.safetyLevel == 'URGENT';
    final isCaution = m.safetyLevel == 'CAUTION';

    final bg = m.fromUser
        ? kWine
        : m.isError || isUrgent
            ? const Color(0xFFFFDAD6)
            : isCaution
                ? const Color(0xFFFFF8E1)
                : Colors.white;

    final fg = m.fromUser ? Colors.white : Colors.black87;

    // Ensure raw markdown syntax like ** is cleaned up for display
    final cleanText = m.text.replaceAll('**', '');

    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (!m.fromUser)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!m.fromUser && isUrgent)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 6),
                    Text(
                      'Get help now',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            if (!m.fromUser && isCaution)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.amber.shade900),
                    const SizedBox(width: 6),
                    Text(
                      'Important Information',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ],
                ),
              ),
            Text(cleanText, style: TextStyle(color: fg, height: 1.35, fontSize: 15)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: ScreenTitle(
                'Ask',
                showLogo: true,
                trailing: const Pill(
                  'Info only',
                  icon: Icons.verified_user_outlined,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final m in _msgs) _bubble(m),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_msgs.length <= 1)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final s in _suggestions)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Pill(s, onTap: () => _send(s)),
                      ),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 13, color: Colors.black45),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HerLife provides health information for education and awareness, not medical diagnosis or treatment.',
                      style: TextStyle(fontSize: 10.5, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask about your health',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: kWine),
                    onPressed: _busy ? null : () => _send(_ctrl.text),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
