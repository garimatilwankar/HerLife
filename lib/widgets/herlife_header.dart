import 'package:flutter/material.dart';
import 'package:herlife/core/stages.dart';
import 'package:herlife/screens/tabs/ask_tab.dart';
import 'package:herlife/screens/tabs/ui.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:herlife/widgets/herlife_logo.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The one header used by every tab: logo, name, life stage and Ask button.
class HerLifeHeader extends StatefulWidget {
  /// Only shown if the user has no stage yet.
  final String? subtitle;
  final bool showAsk;

  /// Add 1 to this number to make every header reload the name and stage.
  static final ValueNotifier<int> reload = ValueNotifier<int>(0);

  const HerLifeHeader({super.key, this.subtitle, this.showAsk = true});

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
    final line = _stage ?? widget.subtitle;

    return Row(
      children: [
        const HerLifeLogoMark(size: 32),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi, ${_name ?? 'there'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kWine,
                ),
              ),
              if (line != null)
                Text(
                  line,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
            ],
          ),
        ),
        if (widget.showAsk)
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openAsk,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(11),
                child: Icon(Icons.chat_bubble_outline, color: kWine, size: 22),
              ),
            ),
          ),
      ],
    );
  }
}