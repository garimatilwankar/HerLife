import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

/// Global application environment configuration.
///
/// Base URL resolution:
/// 1. Run-time override set via [setBaseUrl] or loaded from SharedPreferences.
///    A saved override is discarded if it was saved under a different
///    `API_BASE_URL` build value (stale URL from an older APK).
/// 2. Dart define flag: `--dart-define=API_BASE_URL=http://192.168.x.x:8000`.
/// 3. Default platform fallback (Android emulator: 10.0.2.2, Web/Desktop/iOS: 127.0.0.1).
class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _prefKey = 'custom_api_base_url';
  static const String _prefBuildKey = 'custom_api_base_url_build';

  static String? _overrideBaseUrl;

  /// Strips whitespace and trailing slashes to prevent malformed URL concatenation.
  static String _sanitize(String url) {
    var clean = url.trim();
    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    return clean;
  }

  /// Loads persisted custom base URL from SharedPreferences if available.
  static Future<void> loadPersistedUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      if (saved == null || saved.trim().isEmpty) return;

      final env = _sanitize(_envBaseUrl);
      final savedForBuild = prefs.getString(_prefBuildKey) ?? '';
      if (env.isNotEmpty && savedForBuild != env) {
        // Stale override saved under a different build URL: drop it.
        _overrideBaseUrl = null;
        await prefs.remove(_prefKey);
        await prefs.remove(_prefBuildKey);
        return;
      }
      _overrideBaseUrl = _sanitize(saved);
    } catch (_) {}
  }

  /// Sets a manual base URL override and persists it.
  static Future<void> setBaseUrl(String url) async {
    final clean = _sanitize(url);
    _overrideBaseUrl = clean.isNotEmpty ? clean : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (clean.isEmpty) {
        await prefs.remove(_prefKey);
        await prefs.remove(_prefBuildKey);
      } else {
        await prefs.setString(_prefKey, clean);
        await prefs.setString(_prefBuildKey, _sanitize(_envBaseUrl));
      }
    } catch (_) {}
  }

  /// Returns the current active base URL.
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return _sanitize(_envBaseUrl);
    }

    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {
      // Fallback if Platform is unsupported
    }

    return 'http://127.0.0.1:8000';
  }

  /// Diagnostic check to know where the base URL came from.
  static String get baseUrlSource {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return 'Saved Override (SharedPreferences)';
    }
    if (_envBaseUrl.isNotEmpty) {
      return 'Build Config (--dart-define API_BASE_URL)';
    }
    return 'Default Fallback';
  }
}