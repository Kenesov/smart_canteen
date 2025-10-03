import 'package:flutter/foundation.dart';

/// Production-safe logger
/// Debug mode da faqat log chiqaradi
class Logger {
  static const bool _isDebug = kDebugMode;
  static const bool _enableApiLogs = true; // API loglarni alohida boshqarish

  static void log(String message, {String tag = 'APP'}) {
    if (_isDebug) {
      debugPrint('[$tag] $message');
    }
  }

  static void error(String message, {String tag = 'ERROR'}) {
    if (_isDebug) {
      debugPrint('❌ [$tag] $message');
    }
  }

  static void success(String message, {String tag = 'SUCCESS'}) {
    if (_isDebug) {
      debugPrint('✅ [$tag] $message');
    }
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    if (_isDebug) {
      debugPrint('⚠️ [$tag] $message');
    }
  }

  static void info(String message, {String tag = 'INFO'}) {
    if (_isDebug) {
      debugPrint('ℹ️ [$tag] $message');
    }
  }

  static void api(String method, String url, {int? statusCode, dynamic data}) {
    if (_isDebug && _enableApiLogs) {
      final buffer = StringBuffer();
      buffer.write('🌐 API: $method $url');

      if (statusCode != null) {
        final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
        buffer.write(' $emoji $statusCode');
      }

      if (data != null) {
        buffer.write('\n   Data: $data');
      }

      debugPrint(buffer.toString());
    }
  }

  static void faceDetection(String message) {
    if (_isDebug) {
      debugPrint('👤 [FACE] $message');
    }
  }

  static void audio(String message) {
    if (_isDebug) {
      debugPrint('🔊 [AUDIO] $message');
    }
  }

  /// Critical errorlar uchun - production da ham log chiqaradi
  static void critical(String message, {String tag = 'CRITICAL', Object? error}) {
    final buffer = StringBuffer();
    buffer.write('🚨 [$tag] $message');

    if (error != null) {
      buffer.write('\n   Error: $error');
    }

    // Production da ham chiqarish
    debugPrint(buffer.toString());
  }
}