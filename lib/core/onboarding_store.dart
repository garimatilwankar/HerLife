import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Saves onboarding answers and "already done" flags on the device.
/// Syncing to the backend profile comes later.
class OnboardingStore {
  static const _answersKey = 'onboarding_answers';
  static const _doneKey = 'onboarding_done';
  static const _tutorialKey = 'tutorial_done';

  static Future<Map<String, dynamic>> loadAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_answersKey);
    if (raw == null) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  static Future<void> saveAnswers(Map<String, dynamic> answers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_answersKey, jsonEncode(answers));
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_doneKey) ?? false;
  }

  static Future<void> markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_doneKey, true);
  }

  static Future<bool> isTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_tutorialKey) ?? false;
  }

  static Future<void> markTutorialDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }
}