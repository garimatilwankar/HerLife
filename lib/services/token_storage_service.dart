import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure token storage service powered by [FlutterSecureStorage].
/// Encrypts JWT access tokens in Android Keystore / iOS Keychain.
class TokenStorageService {
  static const _tokenKey = 'jwt_access_token';

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Saves the JWT access token to secure storage.
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Retrieves the saved JWT access token, or null if none exists.
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Clears the saved JWT access token from secure storage.
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Checks whether a token is stored locally.
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
