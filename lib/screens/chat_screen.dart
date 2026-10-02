import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

enum ReplyKind { urgent, careful, info, noMatch }

class ChatReply {
  final String text;
  final ReplyKind kind;
  final List<String> sources;

  const ChatReply({
    required this.text,
    required this.kind,
    this.sources = const [],
  });
}

class ChatMessage {
  final String text;
  final bool fromUser;
  final ReplyKind? kind;
  final List<String> sources;

  const ChatMessage({
    required this.text,
    required this.fromUser,
    this.kind,
    this.sources = const [],
  });
}

class KnowledgeEntry {
  final String title;
  final String body;
  final String source;
  final List<String> keywords;
  final Set<String> stages; // empty set means relevant to every stage

  const KnowledgeEntry({
    required this.title,
    required this.body,
    required this.source,
    required this.keywords,
    this.stages = const {},
  });
}

class _SafetyRule {
  final RegExp pattern;
  final String message;
  final Set<String>? stages; // null means the rule applies to every stage

  _SafetyRule(String source, this.message, {this.stages})
      : pattern = RegExp(source, caseSensitive: false);
}

// ---------------------------------------------------------------------------
// Curated knowledge base. Every entry needs clinician review before release.
// ---------------------------------------------------------------------------

const List<KnowledgeEntry> _knowledge = [
  KnowledgeEntry(
    title: 'How cycle length is counted',
    body:
        'Cycle length runs from the first day of one period to the first day '
        'of the next. In adults a cycle is commonly between 21 and 35 days, '
        'and a period usually lasts about 2 to 7 days. Small month-to-month '
        'changes are normal.',
    source: 'ACOG, NHS',
    keywords: ['cycle length', 'how long', 'normal cycle', 'regular', 'cycle'],
  ),
  KnowledgeEntry(
    title: 'Irregular periods',
    body:
        'Cycles that change in length are common, especially in the first '
        'years after periods begin and in the years before menopause. '
        'Stress, sleep, weight changes, illness and some medicines can also '
        'play a part. Missing several periods in a row, or a sudden major '
        'change in your pattern, is worth discussing with a clinician.',
    source: 'ACOG, NHS',
    keywords: ['irregular', 'late period', 'missed period', 'skipped', 'delayed'],
  ),
  KnowledgeEntry(
    title: 'Period cramps',
    body:
        'Mild to moderate cramps are common. Heat, gentle movement and rest '
        'help many people. Pain that is severe, getting worse over time, or '
        'stopping you from doing your normal activities should be '
        'discussed with a clinician.',
    source: 'ACOG, NHS',
    keywords: ['cramp', 'period pain', 'pain during period', 'dysmenorrhea'],
  ),
  KnowledgeEntry(
    title: 'Heavy periods',
    body:
        'A period may be considered heavy if you soak through a pad or '
        'tampon every hour for several hours, pass clots larger than a coin, '
        'or bleed for more than 7 days. Heavy periods can cause tiredness '
        'from low iron, so they are worth discussing with a clinician.',
    source: 'ACOG, CDC',
    keywords: ['heavy period', 'heavy flow', 'clots', 'too much bleeding'],
  ),
  KnowledgeEntry(
    title: 'Before your period (PMS)',
    body:
        'Mood changes, bloating, breast tenderness and tiredness in the days '
        'before a period are common and usually ease once bleeding starts. '
        'If mood symptoms are severe or disrupt your daily life, a '
        'clinician can help.',
    source: 'ACOG, NHS',
    keywords: ['pms', 'mood swings', 'bloating', 'before period', 'irritable'],
  ),
  KnowledgeEntry(
    title: 'Starting periods',
    body:
        'Periods usually begin somewhere between about 9 and 15 years old, '
        'and the first few years are often irregular. Tracking your dates '
        'helps you see your own pattern. If you have not had a period by '
        '15, or you have questions, a clinician can help.',
    source: 'ACOG, NHS',
    keywords: ['first period', 'puberty', 'start period', 'no period yet'],
    stages: {'Adolescence'},
  ),
  KnowledgeEntry(
    title: 'Nausea in pregnancy',
    body:
        'Nausea and vomiting are common in early pregnancy. Small frequent '
        'meals, rest and sipping fluids often help. If you cannot keep '
        'fluids down, or feel very weak or dizzy, contact your healthcare '
        'provider.',
    source: 'ACOG, NHS',
    keywords: ['nausea', 'vomiting', 'morning sickness', 'sick'],
    stages: {'Pregnancy'},
  ),
  KnowledgeEntry(
    title: 'Pregnancy warning signs',
    body:
        'Contact your provider promptly for severe headache, vision '
        'changes, fever, swelling of the face or hands, belly pain, '
        'bleeding, or less movement from the baby. Regular antenatal '
        'check-ups are an important part of pregnancy care.',
    source: 'CDC, NHS',
    keywords: ['warning sign', 'when to call', 'danger sign', 'worried', 'check-up'],
    stages: {'Pregnancy'},
  ),
  KnowledgeEntry(
    title: 'Baby blues and postpartum depression',
    body:
        'Feeling tearful or overwhelmed in the first week or two after birth '
        'is common and is often called the baby blues. If low mood, anxiety '
        'or difficulty coping lasts longer, or feels heavy and constant, '
        'please talk to a healthcare professional. Support works well.',
    source: 'ACOG, NHS',
    keywords: ['baby blues', 'postpartum depression', 'sad', 'crying', 'anxious', 'overwhelmed', 'low mood'],
    stages: {'Postpartum'},
  ),
  KnowledgeEntry(
    title: 'Bleeding after birth',
    body:
        'Vaginal bleeding after birth is normal and usually gets lighter '
        'over several weeks. Soaking a pad in an hour, passing large clots, '
        'or bleeding that suddenly gets heavier needs urgent medical '
        'attention.',
    source: 'ACOG, NHS',
    keywords: ['postpartum bleeding', 'lochia', 'bleeding after birth', 'bleeding after delivery'],
    stages: {'Postpartum'},
  ),
  KnowledgeEntry(
    title: 'Perimenopause',
    body:
        'Perimenopause is the transition before menopause, often starting in '
        'the 40s. Cycles may become shorter, longer or less predictable, and '
        'hot flashes, sleep changes and mood changes can appear. Tracking '
        'your cycle and symptoms gives a clinician a clearer picture.',
    source: 'ACOG, NHS',
    keywords: ['perimenopause', 'hot flash', 'night sweat', 'sleep', 'mood', 'irregular'],
    stages: {'Perimenopause', 'Menopause'},
  ),
  KnowledgeEntry(
    title: 'Menopause',
    body:
        'Menopause is confirmed after 12 months without a period. Hot '
        'flashes, sleep problems and mood changes are common, and there are '
        'ways to ease them. Any bleeding after menopause should be checked '
        'by a clinician.',
    source: 'ACOG, NHS',
    keywords: ['menopause', 'hot flash', 'hot flush', 'bone', 'after menopause'],
    stages: {'Menopause', 'Perimenopause'},
  ),
  KnowledgeEntry(
    title: 'Tracking that helps',
    body:
        'Noting period start and end dates, flow, symptoms and mood gives you '
        'and your clinician a clearer picture. Patterns matter more than '
        'any single day.',
    source: 'ACOG',
    keywords: ['track', 'tracking', 'log', 'app', 'record'],
  ),
];

// ---------------------------------------------------------------------------
// Engine: safety rules first, then retrieval. No LLM involved yet.
// ---------------------------------------------------------------------------

class ChatEngine {
  static const String _emergencyMessage =
      'What you describe can be serious and should be checked urgently. '
      'Please call your local emergency number (112 in India) or go to the '
      'nearest emergency department now. If you can, ask someone to stay '
      'with you.';

  static const String _crisisMessage =
      'I am really sorry you are going through this. You deserve support '
      'right now. Please reach out to your local emergency number (112 in '
      'India) or a crisis helpline, or tell someone you trust so you are '
      'not alone with it. If you might act on these thoughts, call '
      'emergency services now.';

  static const String _pregnancyMessage =
      'Bleeding, severe pain or other warning signs during pregnancy need '
      'to be assessed promptly. Please contact your maternity provider or '
      'go to an emergency department now, and call your local emergency '
      'number if you cannot get there safely.';

  static const String _postpartumMessage =
      'Fever, very heavy bleeding or thoughts of harming yourself or your '
      'baby after birth need prompt medical care. Please contact your '
      'healthcare provider or go to an emergency department now, and call '
      'your local emergency number if you cannot get there safely.';

  static final List<_SafetyRule> _urgentRules = [
    _SafetyRule(
      r"suicid|kill myself|end my life|want to die|hurt myself|self.?harm",
      _crisisMessage,
    ),
    _SafetyRule(
      r"chest pain|can.?t breathe|trouble breathing|short(ness)? of breath|"
      r"fainted|passed out|seizure",
      _emergencyMessage,
    ),
    _SafetyRule(
      r"soak(ing|ed)? (through )?(a |one )?(pad|tampon)|"
      r"(pad|tampon)s? (every|each) (hour|hr)",
      _emergencyMessage,
    ),
    _SafetyRule(
      r"bleed|spotting|blood|severe (headache|pain|belly|abdominal|stomach)|"
      r"blurred vision|vision changes|fever|swelling (of|in) (my )?(face|hands)|"
      r"(baby|movements?).*(not|isn.?t|less|reduced).*mov|less movement|"
      r"reduced movement",
      _pregnancyMessage,
      stages: {'Pregnancy'},
    ),
    _SafetyRule(
      r"fever|heavy bleeding|bleeding (a lot|heavily)|large clots|"
      r"harm (my )?baby|hurt (my )?baby|hearing voices",
      _postpartumMessage,
      stages: {'Postpartum'},
    ),
    _SafetyRule(
      r"severe (pelvic |abdominal |belly )?pain|unbearable pain|worst pain",
      _emergencyMessage,
    ),
  ];

  static final RegExp _diagnosisPattern = RegExp(
    r"do i have|am i (pregnant|sick|ill)|is it (pcos|cancer|endometriosis)|"
    r"diagnos|what disease|what.?s wrong with me",
    caseSensitive: false,
  );

  static final RegExp _dosingPattern = RegExp(
    r"\bdose\b|dosage|how many (mg|tablets|pills)|"
    r"how much (ibuprofen|paracetamol|medicine|medication|tablet)|\bmg\b|"
    r"what (medicine|medication|drug|pill|tablet)",
    caseSensitive: false,
  );

  static Future<ChatReply> reply(String query, String? stage) async {
    final q = query.toLowerCase();

    // 1. Deterministic red-flag rules run before anything else.
    for (final rule in _urgentRules) {
      final applies =
          rule.stages == null || (stage != null && rule.stages!.contains(stage));
      if (applies && rule.pattern.hasMatch(q)) {
        return ChatReply(text: rule.message, kind: ReplyKind.urgent);
      }
    }

    // 2. Never diagnose or give medicine advice.
    if (_diagnosisPattern.hasMatch(q)) {
      return const ChatReply(
        kind: ReplyKind.careful,
        text:
            'I cannot tell you what condition you have. I can share general '
            'information, and if something is worrying you, a clinician can '
            'examine you and run the right tests. Your logged symptoms and '
            'cycle dates are useful to bring along.',
      );
    }
    if (_dosingPattern.hasMatch(q)) {
      return const ChatReply(
        kind: ReplyKind.careful,
        text:
            'I cannot recommend medicines or doses. A doctor or pharmacist '
            'can advise what is safe for you, especially if you are '
            'pregnant, breastfeeding or take other medicines.',
      );
    }

    // 3. Retrieve curated content, ranked by stage relevance.
    final matches = _retrieve(q, stage);
    if (matches.isEmpty) {
      return const ChatReply(
        kind: ReplyKind.noMatch,
        text:
            'I do not have reviewed information on that yet. You can browse '
            'the Learn tab, or ask a healthcare professional if it is '
            'bothering you. Try asking about cycles, cramps, irregular '
            'periods or symptoms for your stage.',
      );
    }

    final buffer = StringBuffer();
    for (final entry in matches) {
      buffer.writeln(entry.title);
      buffer.writeln(entry.body);
      buffer.writeln();
    }

    final context = await _cycleContext(q);
    if (context != null) buffer.writeln(context);

    return ChatReply(
      kind: ReplyKind.info,
      text: buffer.toString().trim(),
      sources: matches.map((e) => e.source).toSet().toList(),
    );
  }

  static List<KnowledgeEntry> _retrieve(String q, String? stage) {
    final scored = <MapEntry<KnowledgeEntry, int>>[];

    for (final entry in _knowledge) {
      final hits = entry.keywords.where(q.contains).length;
      if (hits == 0) continue;

      var score = hits * 2;
      if (entry.stages.isNotEmpty && stage != null) {
        score += entry.stages.contains(stage) ? 1 : -1;
      }
      if (score >= 2) scored.add(MapEntry(entry, score));
    }

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(2).map((e) => e.key).toList();
  }

  static Future<String?> _cycleContext(String q) async {
    if (!RegExp(r'cycle|period|late|irregular|regular').hasMatch(q)) {
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    final dates = (prefs.getStringList('period_history') ?? [])
        .map(DateTime.tryParse)
        .whereType<DateTime>()
        .toList()
      ..sort();

    if (dates.length < 3) return null;

    final lengths = <int>[
      for (var i = 1; i < dates.length; i++)
        dates[i].difference(dates[i - 1]).inDays,
    ];

    final average = lengths.reduce((a, b) => a + b) / lengths.length;
    final shortest = lengths.reduce((a, b) => a < b ? a : b);
    final longest = lengths.reduce((a, b) => a > b ? a : b);

    return 'From your own log: ${lengths.length} recorded cycles, averaging '
        '${average.round()} days (shortest $shortest, longest $longest).';
  }
}

// ---------------------------------------------------------------------------
// UI
// ---------------------------------------------------------------------------

const Map<String, List<String>> _suggestionsByStage = {
  'Adolescence': ['When do periods usually start?', 'Is an irregular period normal?'],
  'Menstruation': ['What is a normal cycle length?', 'How can I ease cramps?'],
  'Reproductive Health': ['Why is my period late?', 'What counts as a heavy period?'],
  'Pregnancy': ['What helps with nausea?', 'What are pregnancy warning signs?'],
  'Postpartum': ['What are the baby blues?', 'Is bleeding after birth normal?'],
  'Perimenopause': ['What is perimenopause?', 'Why are my periods irregular?'],
  'Menopause': ['What causes hot flashes?', 'What is menopause?'],
};

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final List<ChatMessage> _messages = [];
  String? _stage;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final stage = prefs.getString('lifecycle_stage');

    if (!mounted) return;

    setState(() {
      _stage = stage;
      _messages.add(
        ChatMessage(
          fromUser: false,
          kind: ReplyKind.info,
          text: stage == null
              ? 'Hi, I am the HerLife assistant. I share reviewed health '
                  'information, I do not diagnose. What would you like to know?'
              : 'Hi, I am the HerLife assistant. Your stage is $stage, so I '
                  'will focus on what fits it. I share reviewed information, '
                  'I do not diagnose. What would you like to know?',
        ),
      );
    });
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _busy) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: trimmed, fromUser: true));
      _busy = true;
    });
    _scrollToEnd();

    final reply = await ChatEngine.reply(trimmed, _stage);

    if (!mounted) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: reply.text,
          fromUser: false,
          kind: reply.kind,
          sources: reply.sources,
        ),
      );
      _busy = false;
    });
    _scrollToEnd();
  }

  Widget _bubble(ChatMessage message) {
    final scheme = Theme.of(context).colorScheme;
    final isUrgent = message.kind == ReplyKind.urgent;

    final Color background;
    final Color foreground;

    if (message.fromUser) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isUrgent) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    }

    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUrgent)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: foreground),
                    const SizedBox(width: 6),
                    Text(
                      'Please get help now',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            Text(message.text, style: TextStyle(color: foreground, height: 1.4)),
            if (message.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Sources: ${message.sources.join(', ')}',
                style: TextStyle(
                  fontSize: 12,
                  color: foreground.withAlpha(170),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsByStage[_stage] ??
        const ['What is a normal cycle length?', 'Why is my period late?'];
    final showSuggestions = _messages.length <= 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Ask HerLife')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                ..._messages.map(_bubble),
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (showSuggestions)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: suggestions
                        .map(
                          (s) => ActionChip(label: Text(s), onPressed: () => _send(s)),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Text(
              'Information only, not a medical diagnosis.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: 'Ask about your health',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _busy ? null : () => _send(_controller.text),
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}