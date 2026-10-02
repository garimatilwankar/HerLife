import 'package:flutter/material.dart';
import 'package:herlife/screens/chat_screen.dart'
    show ChatEngine, ChatMessage, ReplyKind;
import 'package:herlife/screens/tabs/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AskTab extends StatefulWidget {
  const AskTab({super.key});

  @override
  State<AskTab> createState() => _AskTabState();
}

class _AskTabState extends State<AskTab> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _msgs = [];
  String? _stage;
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
    SharedPreferences.getInstance().then((p) {
      if (!mounted) return;
      setState(() {
        _stage = p.getString('lifecycle_stage');
        _msgs.add(const ChatMessage(
            text: 'Hi! Ask me about cycles or symptoms.',
            fromUser: false,
            kind: ReplyKind.info));
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
        }
      });

  Future<void> _send(String text) async {
    final t = text.trim();
    if (t.isEmpty || _busy) return;
    _ctrl.clear();
    setState(() {
      _msgs.add(ChatMessage(text: t, fromUser: true));
      _busy = true;
    });
    _toEnd();
    final r = await ChatEngine.reply(t, _stage);
    if (!mounted) return;
    setState(() {
      _msgs.add(ChatMessage(
          text: r.text, fromUser: false, kind: r.kind, sources: r.sources));
      _busy = false;
    });
    _toEnd();
  }

  Widget _bubble(ChatMessage m) {
    final urgent = m.kind == ReplyKind.urgent;
    final bg = m.fromUser
        ? kWine
        : urgent
            ? const Color(0xFFFFDAD6)
            : Colors.white;
    final fg = m.fromUser ? Colors.white : Colors.black87;
    return Align(
      alignment: m.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (urgent)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                SizedBox(width: 6),
                Text('Get help now',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.red)),
              ]),
            ),
          Text(m.text, style: TextStyle(color: fg, height: 1.35)),
          if (m.sources.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 6, children: [
              for (final s in m.sources)
                Pill(s, icon: Icons.verified_outlined),
            ]),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: ScreenTitle('Ask',
                trailing: const Pill('Info only',
                    icon: Icons.verified_user_outlined)),
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
                            child: CircularProgressIndicator(strokeWidth: 2))),
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
            child: Row(children: [
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
                        horizontal: 18, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: kWine),
                onPressed: _busy ? null : () => _send(_ctrl.text),
                icon: const Icon(Icons.arrow_upward),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
