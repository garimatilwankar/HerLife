import 'package:flutter/material.dart';
import 'package:herlife/models/api_models.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:herlife/services/profile_service.dart';
import 'package:herlife/services/tracking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:herlife/widgets/herlife_logo.dart';

const kWine = Color(0xFF7E2A3C);
const kBlush = Color(0xFFFFD9DE);
const kBg = Color(0xFFFBF9F6);

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const AppCard({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0.5,
      shadowColor: kWine.withAlpha(60),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }
}

class Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData? icon;
  final VoidCallback? onTap;
  const Pill(this.label,
      {super.key, this.selected = false, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kWine : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? kWine : kBlush),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
          ],
          Text(label, style: TextStyle(color: fg, fontSize: 13)),
        ]),
      ),
    );
  }
}

class ScreenTitle extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final bool showLogo;
  const ScreenTitle(this.title, {super.key, this.trailing, this.showLogo = false});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLogo) ...[
                const HerLifeLogoMark(size: 26),
                const SizedBox(width: 10),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: kWine,
                ),
              ),
            ],
          ),
          ?trailing,
        ],
      );
}

class HerData {
  List<DateTime> periods = []; // newest first
  Map<String, DateTime> ends = {};
  Map<String, int> periodIds = {};
  List<String> symptoms = [], checkInSymptoms = [];
  String? mood, stage, name;

  static Future<HerData> load() async {
    final d = HerData();

    // 1. Concurrently fetch all independent network requests & shared preferences
    final results = await Future.wait<dynamic>([
      TrackingService.getPeriods(),
      TrackingService.getSymptoms(),
      TrackingService.getCheckins(),
      ProfileService.getProfile(),
      AuthService.currentName(),
      SharedPreferences.getInstance(),
    ]);

    final backendPeriods = results[0] as List<PeriodResponse>;
    final backendSymptoms = results[1] as List<SymptomResponse>;
    final backendCheckins = results[2] as List<CheckinResponse>;
    final profile = results[3] as ProfileResponse?;
    d.name = results[4] as String?;
    final p = results[5] as SharedPreferences;

    // Process periods
    if (backendPeriods.isNotEmpty) {
      d.periods = backendPeriods
          .map((p) => DateTime(p.startDate.year, p.startDate.month, p.startDate.day))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      for (final p in backendPeriods) {
        final startKey = DateTime(p.startDate.year, p.startDate.month, p.startDate.day).toIso8601String();
        d.periodIds[startKey] = p.id;
        if (p.endDate != null) {
          d.ends[startKey] = DateTime(p.endDate!.year, p.endDate!.month, p.endDate!.day);
        }
      }
    } else {
      // Offline fallback for periods
      final savedHistory = p.getStringList('period_history') ?? [];
      d.periods = savedHistory
          .map((s) => DateTime.parse(s))
          .toList()
        ..sort((a, b) => b.compareTo(a));

      final savedEnds = p.getStringList('period_end_dates') ?? [];
      for (final item in savedEnds) {
        final parts = item.split('|');
        if (parts.length == 2) {
          d.ends[parts[0]] = DateTime.parse(parts[1]);
        }
      }
    }

    // Process symptoms
    if (backendSymptoms.isNotEmpty) {
      d.symptoms = backendSymptoms.map((s) => s.name).toSet().toList();
    } else {
      d.symptoms = p.getStringList('symptoms') ?? [];
    }

    // Process checkins
    if (backendCheckins.isNotEmpty) {
      d.mood = backendCheckins.first.mood;
      if (backendCheckins.first.notes != null) {
        d.checkInSymptoms = backendCheckins.first.notes!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    } else {
      d.mood = p.getString('checkin_mood');
      d.checkInSymptoms = p.getStringList('checkin_symptoms') ?? [];
    }

    // Process stage
    d.stage = profile?.lifecycleStage ?? p.getString('lifecycle_stage');

    // Sync SharedPreferences local cache non-blockingly
    _syncLocalCache(d, p);

    return d;
  }

  static void _syncLocalCache(HerData d, SharedPreferences p) {
    if (d.periods.isNotEmpty) {
      p.setStringList(
        'period_history',
        d.periods.map((date) => date.toIso8601String()).toList(),
      );
    }
    final endDateEntries = d.ends.entries
        .map((entry) => '${entry.key}|${entry.value.toIso8601String()}')
        .toList();
    p.setStringList('period_end_dates', endDateEntries);
    if (d.symptoms.isNotEmpty) {
      p.setStringList('symptoms', d.symptoms);
    }
    if (d.mood != null) {
      p.setString('checkin_mood', d.mood!);
    }
  }

  static Future<void> addPeriod(DateTime date) async {
    final cleanDate = DateTime(date.year, date.month, date.day);
    await TrackingService.createPeriod(cleanDate);

    final p = await SharedPreferences.getInstance();
    final list = p.getStringList('period_history') ?? [];
    final iso = cleanDate.toIso8601String();
    if (!list.contains(iso)) list.add(iso);
    await p.setStringList('period_history', list);
  }

  static Future<void> setEnd(DateTime start, DateTime end) async {
    final cleanStart = DateTime(start.year, start.month, start.day);
    final cleanEnd = DateTime(end.year, end.month, end.day);
    final startKey = cleanStart.toIso8601String();

    final backendPeriods = await TrackingService.getPeriods();
    final existing = backendPeriods.firstWhere(
      (p) =>
          p.startDate.year == cleanStart.year &&
          p.startDate.month == cleanStart.month &&
          p.startDate.day == cleanStart.day,
      orElse: () => PeriodResponse(id: -1, startDate: cleanStart),
    );

    if (existing.id != -1) {
      await TrackingService.updatePeriod(existing.id, cleanStart, endDate: cleanEnd);
    } else {
      await TrackingService.createPeriod(cleanStart, endDate: cleanEnd);
    }

    final p = await SharedPreferences.getInstance();
    final list = (p.getStringList('period_end_dates') ?? [])
        .where((e) => !e.startsWith('$startKey|'))
        .toList()
      ..add('$startKey|${cleanEnd.toIso8601String()}');
    await p.setStringList('period_end_dates', list);
  }

  DateTime get today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  DateTime? get last => periods.isEmpty ? null : periods.first;

  List<int> get lengths {
    final asc = [...periods]..sort();
    return [
      for (var i = 1; i < asc.length; i++)
        asc[i].difference(asc[i - 1]).inDays,
    ];
  }

  double get avg =>
      lengths.isEmpty ? 28 : lengths.reduce((a, b) => a + b) / lengths.length;

  int get cycleDay => last == null ? 0 : today.difference(last!).inDays + 1;

  DateTime? get next => last?.add(Duration(days: avg.round()));

  String get phase {
    final d = cycleDay;
    final ov = avg.round() - 14;
    if (d <= 0) return 'No data';
    if (d <= 5) return 'Menstrual';
    if (d < ov - 1) return 'Follicular';
    if (d <= ov + 1) return 'Ovulation';
    return 'Luteal';
  }

  String fmt(DateTime x) => '${x.day}/${x.month}/${x.year}';
}
