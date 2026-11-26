import 'package:dio/dio.dart';
import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/core/onboarding_store.dart';
import 'package:herlife/core/stages.dart';
import 'package:herlife/models/api_models.dart';
import 'package:herlife/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user profile and lifecycle stage via FastAPI backend.
class ProfileService {
  static const _lifecycleKey = 'lifecycle_stage';
  static const _biologicalKey = 'biological_assignment';
  static const _dobKey = 'date_of_birth';
  static const _pcosKey = 'pcos_status';

  static ProfileResponse? _cachedProfile;

  /// Current cached profile in memory.
  static ProfileResponse? get cachedProfile => _cachedProfile;

  /// The three PCOS/PCOD answers the backend accepts, and how to show them.
  static const pcosOptions = <String, String>{
    'yes': 'Yes',
    'no': 'No',
    'not_sure': 'Not sure',
  };

  static String pcosLabel(String? value) => pcosOptions[value] ?? 'Not set';

  /// Fetches profile details from GET /api/profile/me.
  static Future<ProfileResponse?> getProfile() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/profile/me');

      if (response.data == null) {
        return null;
      }

      final profileData = response.data as Map<String, dynamic>;
      final profile = ProfileResponse.fromJson(profileData);

      _cachedProfile = profile;

      // Sync local preferences for offline/UI caching
      final prefs = await SharedPreferences.getInstance();
      if (profile.lifecycleStage != null) {
        await prefs.setString(_lifecycleKey, profile.lifecycleStage!);
      }
      if (profile.biologicalAssignment != null) {
        await prefs.setString(_biologicalKey, profile.biologicalAssignment!);
      }
      if (profile.dateOfBirth != null) {
        await prefs.setString(_dobKey, profile.dateOfBirth!.toIso8601String());
      }
      final pcosStatus = profileData['pcos_status'] as String?;
      if (pcosStatus != null) {
        await prefs.setString(_pcosKey, pcosStatus);
      }

      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Updates profile details via PUT /api/profile/me.
  /// Only the values you pass are sent (nulls are left out), so nothing
  /// else gets wiped. Needs the backend fix: model_dump(exclude_unset=True).
  static Future<AuthResult> updateProfile({
    DateTime? dateOfBirth,
    String? biologicalAssignment,
    String? lifecycleStage,
    String? pcosStatus,
    DateTime? lastPeriodDate,
    int? cycleLength,
    int? periodLength,
    String? mainConcerns,
    bool? onboardingCompleted,
  }) async {
    try {
      final dio = ApiClient().dio;

      String dateOnly(DateTime d) => d.toIso8601String().split('T').first;

      final payload = <String, dynamic>{
        if (dateOfBirth != null) 'date_of_birth': dateOnly(dateOfBirth),
        if (biologicalAssignment != null)
          'biological_assignment': biologicalAssignment,
        if (lifecycleStage != null) 'lifecycle_stage': lifecycleStage,
        if (pcosStatus != null) 'pcos_status': pcosStatus,
        if (lastPeriodDate != null) 'last_period_date': dateOnly(lastPeriodDate),
        if (cycleLength != null) 'cycle_length': cycleLength,
        if (periodLength != null) 'period_length': periodLength,
        if (mainConcerns != null) 'main_concerns': mainConcerns,
        if (onboardingCompleted != null)
          'onboarding_completed': onboardingCompleted,
      };

      final response = await dio.put('/api/profile/me', data: payload);

      final profileData = response.data as Map<String, dynamic>;
      final profile = ProfileResponse.fromJson(profileData);

      _cachedProfile = profile;

      final prefs = await SharedPreferences.getInstance();
      if (lifecycleStage != null) {
        await prefs.setString(_lifecycleKey, lifecycleStage);
      }
      if (biologicalAssignment != null) {
        await prefs.setString(_biologicalKey, biologicalAssignment);
      }
      if (dateOfBirth != null) {
        await prefs.setString(_dobKey, dateOfBirth.toIso8601String());
      }
      final savedPcosStatus = profileData['pcos_status'] as String?;
      if (savedPcosStatus != null) {
        await prefs.setString(_pcosKey, savedPcosStatus);
      }

      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(ApiClient.formatError(e));
    } catch (e) {
      return const AuthResult.failure('Failed to update profile.');
    }
  }

  // ------------------------------------------------------------------
  // Onboarding
  // ------------------------------------------------------------------

  /// True when the questions should NOT be shown again.
  /// Checks the phone first, then the server. If the server cannot be
  /// reached we return true so a network problem never blocks the app.
  static Future<bool> isOnboardingDone() async {
    if (await OnboardingStore.isOnboardingDone()) return true;
    try {
      final response = await ApiClient().dio.get('/api/profile/me');
      final data = response.data;
      if (data is! Map) return false; // new user, no profile yet
      final done = data['onboarding_completed'] == true;
      if (done) await OnboardingStore.markOnboardingDone();
      return done;
    } catch (_) {
      return true;
    }
  }

  /// Saves the answers on the phone and sends the ones the backend has
  /// fields for. The other answers stay on the phone for now.
  static Future<AuthResult> saveOnboardingAnswers(
      Map<String, dynamic> a) async {
    await OnboardingStore.saveAnswers(a);
    await OnboardingStore.markOnboardingDone();

    final stage = LifeStages.normalize(_stageFromAnswer(a['life_stage']));

    return updateProfile(
      lifecycleStage: stage,
      pcosStatus: _pcosFromConditions(a['conditions']),
      lastPeriodDate: DateTime.tryParse((a['last_period'] as String?) ?? ''),
      cycleLength: _cycleLengths[a['cycle_length']],
      periodLength: _periodLengths[a['period_length']],
      mainConcerns: _concerns(a['goals']),
      onboardingCompleted: true,
    );
  }

  static String? _stageFromAnswer(dynamic answer) {
    switch (answer) {
      case 'Menstruation':
      case 'Reproductive years (not currently menstruating)':
        return 'Menstruation';
      case 'Pregnancy':
        return 'Pregnancy';
      case 'Postpartum':
        return 'Postpartum';
      case 'Perimenopause':
        return 'Perimenopause';
      case 'Menopause':
      case 'Postmenopause':
        return 'Menopause';
      default:
        return null; // "I'm not sure" or skipped: the stage picker asks next
    }
  }

  static String? _pcosFromConditions(dynamic conditions) {
    if (conditions is! List || conditions.isEmpty) return null;
    if (conditions.contains('PCOS / PCOD')) return 'yes';
    if (conditions.contains('Prefer not to say')) return 'not_sure';
    return 'no';
  }

  static const _cycleLengths = <String, int>{
    '21-24 days': 23,
    '25-28 days': 27,
    '29-32 days': 30,
    '33+ days': 35,
  };

  static const _periodLengths = <String, int>{
    '1-3 days': 2,
    '4-5 days': 5,
    '6-7 days': 6,
    'More than 7 days': 8,
  };

  static String? _concerns(dynamic goals) {
    if (goals is! List || goals.isEmpty) return null;
    final text = goals.join('; ');
    return text.length > 500 ? text.substring(0, 500) : text;
  }
}