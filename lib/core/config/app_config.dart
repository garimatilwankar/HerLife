import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Global application environment configuration.
///
/// Base URL resolution:
/// 1. Run-time override set via [setBaseUrl].
/// 2. Dart define flag: `--dart-define=API_BASE_URL=http://192.168.x.x:8000`.
/// 3. Default platform fallback (Android emulator: 10.0.2.2, Web/Desktop/iOS: 127.0.0.1).
class AppConfig {
  static const String _envBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String? _overrideBaseUrl;

  /// Sets a manual base URL override (useful for testing on physical devices).
  static void setBaseUrl(String url) {
    _overrideBaseUrl = url.trim();
  }

  /// Returns the current active base URL.
  static String get baseUrl {
    if (_overrideBaseUrl != null && _overrideBaseUrl!.isNotEmpty) {
      return _overrideBaseUrl!;
    }

    if (_envBaseUrl.isNotEmpty) {
      return _envBaseUrl;
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
}
