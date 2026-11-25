import 'package:flutter/material.dart';
import 'package:herlife/core/stages.dart';
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:herlife/widgets/herlife_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one header used by every tab, all on ONE line:
/// [HL logo] [title ........] [stage chip] [Ask button]
///
/// Home:   const HerLifeHeader()                      -> "Hi, Garima"
/// Others: const HerLifeHeader(title: 'Track')        -> "Track"
class HerLifeHeader extends StatefulWidget {
  /// null means Home: shows "Hi, <name>".
  final String? title;

  /// Old parameter, kept so screens you haven't updated yet still compile.
  /// It is treated as the title. Switch these to `title:` when you can.
  final String? subtitle;

  final bool showAsk;

  /// Add 1 to this number to make every header reload the name and stage.
  static final ValueNotifier<int> reload = ValueNotifier<int>(0);

  const HerLifeHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showAsk = true,
  });

  @override
  State<HerLifeHeader> createState() => _HerLifeHeaderState();
}

class _HerLifeHeaderState extends State<HerLifeHeader> {
  String? _name;
  String? _stage;

  @override
  void initState() {
    super.initState();
    _load();
    HerLifeHeader.reload.addListener(_load);
  }

  @override
  void dispose() {
    HerLifeHeader.reload.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final name = await AuthService.currentName();
    final profile = await ProfileService.getProfile();
    final prefs = await SharedPreferences.getInstance();
    final stage = LifeStages.normalize(
      profile?.lifecycleStage ?? prefs.getString('lifecycle_stage'),
    );

    if (!mounted) return;
    setState(() {
      _name = name;
      _stage = stage;
    });
  }

  void _openAsk() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AskTab()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.title ?? widget.subtitle ?? 'Hi, ${_name ?? 'there'}';

    return Row(
      children: [
        const HerLifeLogoMark(size: 32),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: kWine,
            ),
          ),
        ),
        if (_stage != null) ...[
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 112),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kBlush,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _stage!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: kWine,
                ),
              ),
            ),
          ),
        ],
        if (widget.showAsk) ...[
          const SizedBox(width: 8),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openAsk,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.chat_bubble_outline, color: kWine, size: 22),
              ),
            ),
          ),
        ],
      ],
    );
  }
}