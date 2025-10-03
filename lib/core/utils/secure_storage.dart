import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';

/// Xavfsiz ma'lumotlar saqlash servisi
/// Tokenlar va boshqa sensitive ma'lumotlar encrypt qilingan holda saqlanadi
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  /// Token saqlash
  static Future<void> saveToken(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      Logger.success('Token saved securely: $key');
    } catch (e) {
      Logger.error('Failed to save token: $e');
      rethrow;
    }
  }

  /// Token olish
  static Future<String?> getToken(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      Logger.error('Failed to read token: $e');
      return null;
    }
  }

  /// Access token saqlash
  static Future<void> saveAccessToken(String token) async {
    await saveToken(AppConstants.accessTokenKey, token);
  }

  /// Refresh token saqlash
  static Future<void> saveRefreshToken(String token) async {
    await saveToken(AppConstants.refreshTokenKey, token);
  }

  /// Access token olish
  static Future<String?> getAccessToken() async {
    return await getToken(AppConstants.accessTokenKey);
  }

  /// Refresh token olish
  static Future<String?> getRefreshToken() async {
    return await getToken(AppConstants.refreshTokenKey);
  }

  /// Login status saqlash (bu oddiy bool, secure bo'lishi shart emas)
  static Future<void> setLoggedIn(bool value) async {
    await _storage.write(
      key: AppConstants.isLoggedInKey,
      value: value.toString(),
    );
  }

  /// Login status tekshirish
  static Future<bool> isLoggedIn() async {
    final value = await _storage.read(key: AppConstants.isLoggedInKey);
    return value == 'true';
  }

  /// Barcha tokenlarni o'chirish
  static Future<void> deleteAllTokens() async {
    try {
      await _storage.delete(key: AppConstants.accessTokenKey);
      await _storage.delete(key: AppConstants.refreshTokenKey);
      await _storage.delete(key: AppConstants.isLoggedInKey);
      Logger.info('All tokens deleted');
    } catch (e) {
      Logger.error('Failed to delete tokens: $e');
      rethrow;
    }
  }

  /// Barcha ma'lumotlarni o'chirish
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      Logger.info('All secure storage cleared');
    } catch (e) {
      Logger.error('Failed to clear storage: $e');
      rethrow;
    }
  }
}