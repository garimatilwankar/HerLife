import 'package:dio/dio.dart';
import 'package:herlife/core/network/api_client.dart';
import 'package:herlife/models/api_models.dart';
import 'package:herlife/services/token_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthResult {
  final bool ok;
  final String? error;

  const AuthResult.success()
      : ok = true,
        error = null;

  const AuthResult.failure(String message)
      : ok = false,
        error = message;
}

/// Authentication service connected to FastAPI backend APIs.
class AuthService {
  static const _sessionEmailKey = 'auth_session_email';
  static const _sessionNameKey = 'auth_session_name';

  static const _userDataKeys = [
    'lifecycle_stage',
    'period_history',
    'period_end_dates',
    'symptoms',
    'checkin_mood',
    'checkin_symptoms',
    'consent_at',
  ];

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String _normalize(String email) => email.trim().toLowerCase();

  static String? _cachedName;
  static String? _cachedEmail;

  // -------------------------
  // SIGN UP
  // -------------------------

  static Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = _normalize(email);

    if (cleanName.isEmpty) {
      return const AuthResult.failure('Please enter your name.');
    }

    if (!_emailPattern.hasMatch(cleanEmail)) {
      return const AuthResult.failure('Please enter a valid email address.');
    }

    if (password.length < 8) {
      return const AuthResult.failure(
        'Your password needs at least 8 characters.',
      );
    }

    try {
      final dio = ApiClient().dio;

      // 1. Register account
      await dio.post(
        '/api/auth/register',
        data: {
          'name': cleanName,
          'email': cleanEmail,
          'password': password,
        },
      );

      // Clear previous local tracking data for fresh user startup
      final prefs = await SharedPreferences.getInstance();
      for (final key in _userDataKeys) {
        await prefs.remove(key);
      }
      await prefs.setString(
        'consent_at',
        DateTime.now().toIso8601String(),
      );

      // 2. Automatically log in after registration to obtain JWT token
      return await logIn(email: cleanEmail, password: password);
    } on DioException catch (e) {
      return AuthResult.failure(ApiClient.formatError(e));
    } catch (e) {
      return AuthResult.failure('Registration failed. Please try again.');
    }
  }

  // -------------------------
  // LOGIN
  // -------------------------

  static Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = _normalize(email);

    if (cleanEmail.isEmpty || password.isEmpty) {
      return const AuthResult.failure('Please enter email and password.');
    }

    try {
      final dio = ApiClient().dio;

      // Form data format expected by OAuth2PasswordRequestForm
      final formData = FormData.fromMap({
        'username': cleanEmail,
        'password': password,
      });

      final response = await dio.post(
        '/api/auth/login',
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      final tokenData = TokenResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      // Save token securely
      await TokenStorageService.saveToken(tokenData.accessToken);

      // Validate session & populate user metadata
      final isValid = await validateSession();

      if (!isValid) {
        return const AuthResult.failure('Could not retrieve user session.');
      }

      return const AuthResult.success();
    } on DioException catch (e) {
      return AuthResult.failure(ApiClient.formatError(e));
    } catch (e) {
      return AuthResult.failure('Login failed. Please try again.');
    }
  }

  // -------------------------
  // LOGOUT
  // -------------------------

  static Future<void> logOut() async {
    await TokenStorageService.clearToken();
    _cachedName = null;
    _cachedEmail = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionEmailKey);
    await prefs.remove(_sessionNameKey);
  }

  // -------------------------
  // SESSION CHECK & VALIDATION
  // -------------------------

  /// Quick local check if a token exists.
  static Future<bool> isLoggedIn() async {
    return await TokenStorageService.hasToken();
  }

  /// Single-pass session validation on app startup via GET /api/auth/me.
  /// If valid, caches user information. If 401/invalid, purges token and returns false.
  static Future<bool> validateSession() async {
    final hasToken = await TokenStorageService.hasToken();
    if (!hasToken) {
      await logOut();
      return false;
    }

    try {
      final dio = ApiClient().dio;
      final response = await dio.get('/api/auth/me');

      final user = UserResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      _cachedName = user.name;
      _cachedEmail = user.email;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionNameKey, user.name);
      await prefs.setString(_sessionEmailKey, user.email);

      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await logOut();
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // -------------------------
  // CURRENT USER NAME
  // -------------------------

  static Future<String?> currentName() async {
    if (_cachedName != null) return _cachedName;

    final prefs = await SharedPreferences.getInstance();
    _cachedName = prefs.getString(_sessionNameKey);

    return _cachedName;
  }

  // -------------------------
  // CURRENT USER EMAIL
  // -------------------------

  static Future<String?> currentEmail() async {
    if (_cachedEmail != null) return _cachedEmail;

    final prefs = await SharedPreferences.getInstance();
    _cachedEmail = prefs.getString(_sessionEmailKey);

    return _cachedEmail;
  }

  // -------------------------
  // UPDATE PROFILE
  // -------------------------

  static Future<AuthResult> updateProfile({
    required String name,
    required String email,
  }) async {
    final cleanName = name.trim();
    final cleanEmail = _normalize(email);

    if (cleanName.isEmpty) {
      return const AuthResult.failure('Please enter your name.');
    }

    if (!_emailPattern.hasMatch(cleanEmail)) {
      return const AuthResult.failure('Please enter a valid email address.');
    }

    _cachedName = cleanName;
    _cachedEmail = cleanEmail;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionNameKey, cleanName);
    await prefs.setString(_sessionEmailKey, cleanEmail);

    return const AuthResult.success();
  }
}