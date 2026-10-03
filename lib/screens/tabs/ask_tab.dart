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
  final List<AskSourceResponse> sources;
  final bool isError;

  const _AskMessage({
    required this.text,
    required this.fromUser,
    this.intent,
    this.safetyLevel,
    this.disclaimer,
    this.sources = const [],
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
    setState(() {
      _msgs.add(_AskMessage(text: t, fromUser: true));
      _busy = true;
    });
    _toEnd();

    try {
      final res = await AskService.askQuestion(t);
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
              sources: res.sources,
            ),
          );
          _busy = false;
        });
      } else {
        setState(() {
          _msgs.add(
            const _AskMessage(
              text: 'Unable to retrieve educational resources at this time.',
              fromUser: false,
              isError: true,
            ),
          );
          _busy = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.add(
          _AskMessage(
            text: e.toString().replaceAll('Exception: ', ''),
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
            Text(m.text, style: TextStyle(color: fg, height: 1.35, fontSize: 15)),
            if (m.sources.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Matching Educational Topics:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: kWine,
                ),
              ),
              const SizedBox(height: 6),
              for (final s in m.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: kBlush.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: kWine,
                          ),
                        ),
                        if (s.summary != null && s.summary!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            s.summary!,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                        if (s.sourceName != null && s.sourceName!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Source: ${s.sourceName}',
                            style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.black54),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
            if (m.disclaimer != null && m.disclaimer!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.black45),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      m.disclaimer!,
                      style: const TextStyle(fontSize: 11, color: Colors.black45),
                    ),
                  ),
                ],
              ),
            ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
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
