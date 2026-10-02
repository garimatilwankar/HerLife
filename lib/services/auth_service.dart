import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
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

/// Local stand-in for the real backend. When FastAPI + Firebase Auth are
/// ready, keep these method signatures and replace the bodies.
class AuthService {
  static const _accountsKey = 'auth_accounts';
  static const _sessionKey = 'auth_session_email';

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

  static String _newSalt() {
    final random = Random.secure();
    return base64Url.encode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String _hash(String password, String salt) {
    List<int> bytes = utf8.encode('$salt:$password');
    for (var i = 0; i < 1000; i++) {
      bytes = sha256.convert(bytes).bytes;
    }
    return base64Url.encode(bytes);
  }

  static Map<String, dynamic> _readAccounts(SharedPreferences prefs) {
    final raw = prefs.getString(_accountsKey);
    if (raw == null) return {};
    return Map<String, dynamic>.from(jsonDecode(raw) as Map);
  }

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

    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);

    if (accounts.containsKey(cleanEmail)) {
      return const AuthResult.failure(
        'An account with this email already exists. Try logging in.',
      );
    }

    final salt = _newSalt();
    accounts[cleanEmail] = {
      'name': cleanName,
      'salt': salt,
      'hash': _hash(password, salt),
    };

    await prefs.setString(_accountsKey, jsonEncode(accounts));

    // A new account starts fresh so it goes through stage selection.
    for (final key in _userDataKeys) {
      await prefs.remove(key);
    }
    await prefs.setString('consent_at', DateTime.now().toIso8601String());
    await prefs.setString(_sessionKey, cleanEmail);

    return const AuthResult.success();
  }

  static Future<AuthResult> logIn({
    required String email,
    required String password,
  }) async {
    final cleanEmail = _normalize(email);
    final prefs = await SharedPreferences.getInstance();
    final accounts = _readAccounts(prefs);
    final account = accounts[cleanEmail];

    const failure = AuthResult.failure('Email or password is incorrect.');

    if (account == null) return failure;

    final salt = account['salt'] as String;
    if (_hash(password, salt) != account['hash']) return failure;

    await prefs.setString(_sessionKey, cleanEmail);
    return const AuthResult.success();
  }

  static Future<void> logOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return false;
    return _readAccounts(prefs).containsKey(email);
  }

  static Future<String?> currentName() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_sessionKey);
    if (email == null) return null;
    final account = _readAccounts(prefs)[email];
    return account == null ? null : account['name'] as String?;
  }
}