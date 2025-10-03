import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // API - HTTPS ishlatiladi
  static final String baseUrl = dotenv.env['BASE_URL'] ?? 'https://default-url.com';
  static const String loginEndpoint = '/api/login/';
  static const String logMealByFaceEndpoint = '/api/meals/log-by-face/';
  static const String logMealByQrEndpoint = '/api/meals/log-by-qr/'; // QR endpoint
  static const String todayMealsEndpoint = '/api/meals/today/';
  static const String mealsByDateEndpoint = '/api/meals/by-date/';

  // Colors
  static const Color primaryColor = Color(0xFF2A9D8F);
  static const Color secondaryColor = Color(0xFF264653);
  static const Color breakfastColor = Color(0xFFF4A261);
  static const Color lunchColor = Color(0xFFE76F51);
  static const Color dinnerColor = Color(0xFF264653);

  // Meal Types
  static const Map<String, String> mealTypeMap = {
    'nonushta': 'BREAKFAST',
    'tushlik': 'LUNCH',
    'kechki_ovqat': 'DINNER',
  };

  // Display names for meal types
  static const Map<String, String> mealTypeDisplayNames = {
    'BREAKFAST': 'Nonushta',
    'LUNCH': 'Tushlik',
    'DINNER': 'Kechki ovqat',
  };

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String isLoggedInKey = 'is_logged_in';

  // Assets
  static const String logoPath = 'assets/logo/img.png';
  static const String successSoundPath = 'sound/ssss.mp3';
  static const String failedSoundPath = 'sound/failed-295059.mp3';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration captureCooldown = Duration(seconds: 3);

  // Network retry
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // 1️⃣ Distance Check
  static const double minFaceRatio = 0.10;
  static const double maxFaceRatio = 0.60;

  // 2️⃣ Pose Check (30 degrees for both X and Y)
  static const double maxHeadAngle = 30.0;

  // Backend error messages mapping
  static const Map<String, String> errorMessages = {
    'NO_FACE': 'Yuz aniqlanmadi',
    'NO_MATCH': 'Talaba topilmadi',
    'DB_ERROR': 'Tizim xatosi',
    'NOT_ACTIVE': 'Talaba faol emas',
    'NOT_ENROLLED': 'Ro\'yxatdan o\'tmagan',
    'ALREADY_LOGGED': 'Allaqachon belgilangan',
    'INVALID_QR': 'QR kod noto\'g\'ri',
    'QR_EXPIRED': 'QR kod muddati tugagan',
    'SUCCESS': 'Muvaffaqiyatli qayd qilindi',
    'ERROR': 'Xatolik yuz berdi',
  };
}