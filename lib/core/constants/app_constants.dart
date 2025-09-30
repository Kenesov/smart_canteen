import 'package:flutter/material.dart';

class AppConstants {
  // API
  static const String baseUrl = 'http://62.113.58.131:8000';
  static const String loginEndpoint = '/api/login/';
  static const String logMealByFaceEndpoint = '/api/meals/log-by-face/';
  static const String todayMealsEndpoint = '/api/meals/today/';

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

  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String isLoggedInKey = 'is_logged_in';

  // Assets
  static const String logoPath = 'assets/logo/img.png';
  static const String successSoundPath = 'sound/successed-295058.mp3';
  static const String failedSoundPath = 'sound/failed-295059.mp3';

  // Timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration captureCooldown = Duration(seconds: 3);

  // Face Detection Thresholds
  static const double minFaceRatio = 0.10;
  static const double maxFaceRatio = 0.60;
  static const double centerThreshold = 0.35;
  static const double maxHeadAngleX = 25.0;
  static const double maxHeadAngleY = 30.0;
  static const double maxHeadAngleZ = 25.0;
  static const double minEyeOpenProbability = 0.5;
}