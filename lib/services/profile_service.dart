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

  static ProfileResponse? _cachedProfile;

  /// Current cached profile in memory.
  static ProfileResponse? get cachedProfile => _cachedProfile;

  /// Fetches profile details from GET /api/profile/me.
  static Future<ProfileResponse?> getProfile() async {
    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/profile/me');

      if (response.data == null) {
        return null;
      }

      final profile = ProfileResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

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

      return profile;
    } catch (_) {
      return null;
    }
  }

  /// Updates profile details via PUT /api/profile/me.
  static Future<AuthResult> updateProfile({
    DateTime? dateOfBirth,
    String? biologicalAssignment,
    String? lifecycleStage,
  }) async {
    try {
      final dio = ApiClient().dio;

      final payload = <String, dynamic>{
        'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        'biological_assignment': biologicalAssignment,
        'lifecycle_stage': lifecycleStage,
      };

      final response = await dio.put(
        '/api/profile/me',
        data: payload,
      );

      final profile = ProfileResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

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

      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(ApiClient.formatError(e));
    } catch (e) {
      return const AuthResult.failure('Failed to update profile.');
    }
  }
}
