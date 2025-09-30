import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../models/meal_log.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        Logger.error('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.accessTokenKey);
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.accessTokenKey, accessToken);
    await prefs.setString(AppConstants.refreshTokenKey, refreshToken);
    await prefs.setBool(AppConstants.isLoggedInKey, true);
    Logger.success('Tokens saved');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.isLoggedInKey) ?? false;
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      Logger.info('Login attempt: $username');

      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _dio.post(AppConstants.loginEndpoint, data: formData);

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['access'] != null && response.data['refresh'] != null) {
          await _saveTokens(response.data['access'], response.data['refresh']);
          Logger.success('Login successful');
          return {'success': true, 'data': response.data};
        }
      }

      return {'success': false, 'message': 'Login yoki parol xato'};
    } catch (e) {
      Logger.error('Login error: $e');
      return {'success': false, 'message': 'Serverga ulanishda xatolik'};
    }
  }

  Future<Map<String, dynamic>> logMealByFace(
      Uint8List imageBytes,
      String mealType,
      ) async {
    try {
      Logger.info('Face recognition started: $mealType');

      final apiMealType = AppConstants.mealTypeMap[mealType] ?? 'LUNCH';

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'meal_type': apiMealType,
      });

      final response = await _dio.post(
        AppConstants.logMealByFaceEndpoint,
        data: formData,
        options: Options(
          headers: {'Accept': 'application/json'},
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200) {
        Logger.success('Face recognition successful');
        return {
          'success': response.data['success'] ?? true,
          'message': response.data['message'] ?? 'Muvaffaqiyatli',
          'student_name': response.data['student']?['first_name'] ?? 'Student',
          'data': response.data,
        };
      }

      return {'success': false, 'message': 'Xatolik yuz berdi'};
    } on DioException catch (e) {
      Logger.error('Face recognition error: ${e.response?.statusCode}');

      if (e.response?.statusCode == 401) {
        return {'success': false, 'message': 'Iltimos qaytadan kiring'};
      } else if (e.response?.statusCode == 404) {
        return {'success': false, 'message': 'Student topilmadi'};
      } else if (e.response?.statusCode == 409) {
        return {'success': false, 'message': 'Bugun allaqachon ovqat olgan'};
      } else if (e.response?.statusCode == 400) {
        return {'success': false, 'message': 'Yuz aniqlanmadi'};
      }

      return {'success': false, 'message': 'Serverga ulanishda xatolik'};
    } catch (e) {
      Logger.error('Unexpected error: $e');
      return {'success': false, 'message': 'Kutilmagan xatolik'};
    }
  }

  Future<List<MealLog>> getTodayMealLogs() async {
    try {
      Logger.info('Fetching today meal logs');

      final response = await _dio.get(AppConstants.todayMealsEndpoint);

      if (response.statusCode == 200 && response.data is List) {
        final logs = (response.data as List)
            .map((json) => MealLog.fromJson(json))
            .toList();

        Logger.success('Fetched ${logs.length} meal logs');
        return logs;
      }
      return [];
    } catch (e) {
      Logger.error('Today meals error: $e');
      return [];
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.accessTokenKey);
    await prefs.remove(AppConstants.refreshTokenKey);
    await prefs.setBool(AppConstants.isLoggedInKey, false);
    Logger.info('Logged out');
  }
}