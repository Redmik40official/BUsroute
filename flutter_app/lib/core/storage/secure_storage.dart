/// ─────────────────────────────────────────────────────────────────────────────
/// Secure Storage Service
///
/// Wraps flutter_secure_storage (AES-256 encrypted on Android via Keystore,
/// Keychain on iOS) for persisting JWT tokens.
///
/// Why not SharedPreferences? SharedPreferences writes plain text to disk and
/// is readable by anyone with ADB access on non-rooted devices. JWT tokens
/// must be stored securely.
/// ─────────────────────────────────────────────────────────────────────────────
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // ── Access Token ─────────────────────────────────────────────────────────────
  Future<void> setAccessToken(String token) async {
    await _storage.write(key: AppConstants.keyAccessToken, value: token);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: AppConstants.keyAccessToken);
  }

  // ── Refresh Token ────────────────────────────────────────────────────────────
  Future<void> setRefreshToken(String token) async {
    await _storage.write(key: AppConstants.keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: AppConstants.keyRefreshToken);
  }

  // ── User Data ────────────────────────────────────────────────────────────────
  Future<void> setUserData(String jsonString) async {
    await _storage.write(key: AppConstants.keyUserData, value: jsonString);
  }

  Future<String?> getUserData() async {
    return _storage.read(key: AppConstants.keyUserData);
  }

  // ── Session ──────────────────────────────────────────────────────────────────
  Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Clears all stored credentials — called on logout or token refresh failure.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
