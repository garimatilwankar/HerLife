import 'package:dio/dio.dart';
import 'package:herlife/core/network/api_client.dart';
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

  static String pcosLabel(String? value) =>
      pcosOptions[value] ?? 'Not set';

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
  /// Only the values you pass are sent, so nothing else gets wiped.
  static Future<AuthResult> updateProfile({
    DateTime? dateOfBirth,
    String? biologicalAssignment,
    String? lifecycleStage,
    String? pcosStatus,
  }) async {
    try {
      final dio = ApiClient().dio;

      final payload = <String, dynamic>{
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        'biological_assignment': ?biologicalAssignment,
        if (lifecycleStage != null) 'lifecycle_stage': lifecycleStage,
        if (pcosStatus != null) 'pcos_status': pcosStatus,
      };

      final response = await dio.put(
        '/api/profile/me',
        data: payload,
      );

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
}