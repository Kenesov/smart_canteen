import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart' show MediaType;
import '../../core/constants/app_constants.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../../core/utils/secure_storage.dart';
import '../models/meal_log.dart';

class ApiService {
  late Dio _dio;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectionTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      validateStatus: (status) => status != null && status < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await SecureStorage.getAccessToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        Logger.api(options.method, options.path);
        return handler.next(options);
      },
      onResponse: (response, handler) {
        Logger.api(
          response.requestOptions.method,
          response.requestOptions.path,
          statusCode: response.statusCode,
        );
        return handler.next(response);
      },
      onError: (error, handler) {
        Logger.error(
          'API Error: ${error.message}',
          tag: 'API [${error.requestOptions.path}]',
        );
        return handler.next(error);
      },
    ));
  }

  /// Login - Result pattern bilan
  Future<Result<Map<String, dynamic>, ApiError>> login(
      String username,
      String password,
      ) async {
    try {
      Logger.info('Login attempt: $username');

      final formData = FormData.fromMap({
        'username': username,
        'password': password,
      });

      final response = await _retryRequest(
            () => _dio.post(AppConstants.loginEndpoint, data: formData),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        if (data['access'] != null && data['refresh'] != null) {
          await SecureStorage.saveAccessToken(data['access']);
          await SecureStorage.saveRefreshToken(data['refresh']);
          await SecureStorage.setLoggedIn(true);

          Logger.success('Login successful');
          return Result.success(data);
        }
      }

      return Result.failure(
        ApiError.fromResponse(response.data, response.statusCode),
      );
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Unexpected login error: $e\n$stackTrace');
      return Result.failure(ApiError.network('Kutilmagan xatolik'));
    }
  }

  /// Face recognition bilan ovqat qaydi - Result pattern
  Future<Result<Map<String, dynamic>, ApiError>> logMealByFace(
      Uint8List imageBytes,
      String mealType,
      ) async {
    try {
      final startTime = DateTime.now();
      Logger.info('⏱️ Face recognition API call started: $mealType');

      final apiMealType = AppConstants.mealTypeMap[mealType] ?? 'LUNCH';

      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          imageBytes,
          filename: 'face.jpg',
          contentType: MediaType('image', 'jpeg'),
        ),
        'meal_type': apiMealType,
      });

      final uploadTime = DateTime.now().difference(startTime).inMilliseconds;
      Logger.info('⏱️ FormData prepared in ${uploadTime}ms');

      final token = await SecureStorage.getAccessToken();

      final response = await _retryRequest(
            () => _dio.post(
          AppConstants.logMealByFaceEndpoint,
          data: formData,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            contentType: 'multipart/form-data',
          ),
        ),
        maxAttempts: 2,
      );

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success('⏱️ Face recognition completed in ${totalTime}ms');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        return Result.success({
          'success': data['success'] ?? true,
          'message': data['message'] ?? AppConstants.errorMessages['SUCCESS'],
          'student_name': data['student']?['first_name'] ?? 'Student',
          'data': data,
        });
      }

      return Result.failure(
        ApiError.fromResponse(response.data, response.statusCode),
      );
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Unexpected face recognition error: $e\n$stackTrace');
      return Result.failure(ApiError.network('Kutilmagan xatolik'));
    }
  }

  /// QR kod bilan ovqat qaydi
  Future<Result<Map<String, dynamic>, ApiError>> logMealByQr(
      String qrToken,
      String mealType,
      ) async {
    try {
      final startTime = DateTime.now();
      Logger.info('⏱️ QR code API call started: $mealType');

      final apiMealType = AppConstants.mealTypeMap[mealType] ?? 'LUNCH';

      final token = await SecureStorage.getAccessToken();

      final response = await _retryRequest(
            () => _dio.post(
          AppConstants.logMealByQrEndpoint,
          data: {
            'qr_token': qrToken,
            'meal_type': apiMealType,
          },
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            contentType: 'application/json',
          ),
        ),
        maxAttempts: 2,
      );

      final totalTime = DateTime.now().difference(startTime).inMilliseconds;
      Logger.success('⏱️ QR code verification completed in ${totalTime}ms');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Student ma'lumotlarini olish
        final student = data['student'];
        final studentName = student != null
            ? '${student['first_name'] ?? ''} ${student['last_name'] ?? ''}'.trim()
            : 'Student';

        final studentImage = student?['image_url']?.toString() ??
            student?['image']?.toString();

        return Result.success({
          'success': data['success'] ?? true,
          'message': data['message'] ?? AppConstants.errorMessages['SUCCESS'],
          'student_name': studentName,
          'student_image': studentImage,
          'data': data,
        });
      }

      return Result.failure(
        ApiError.fromResponse(response.data, response.statusCode),
      );
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Unexpected QR code error: $e\n$stackTrace');
      return Result.failure(ApiError.network('Kutilmagan xatolik'));
    }
  }

  /// Bugungi ovqatlar ro'yxati
  Future<Result<List<MealLog>, ApiError>> getTodayMealLogs() async {
    try {
      Logger.info('Fetching today meal logs');

      final token = await SecureStorage.getAccessToken();

      final response = await _retryRequest(
            () => _dio.get(
          AppConstants.todayMealsEndpoint,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        ),
      );

      if (response.statusCode == 200 && response.data is List) {
        final logs = (response.data as List)
            .map((json) {
          try {
            return MealLog.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            Logger.error('Failed to parse meal log: $e');
            return null;
          }
        })
            .whereType<MealLog>()
            .toList();

        Logger.success('Fetched ${logs.length} meal logs');
        return Result.success(logs);
      }

      return Result.failure(
        ApiError.fromResponse(response.data, response.statusCode),
      );
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Unexpected error fetching meals: $e\n$stackTrace');
      return Result.failure(ApiError.network('Ma\'lumotlarni yuklashda xatolik'));
    }
  }

  /// Kun bo'yicha ovqatlar ro'yxati
  Future<Result<List<MealLog>, ApiError>> getMealsByDate({
    required DateTime date,
    String? mealType,
  }) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      Logger.info('Fetching meals for date: $dateStr');

      final queryParams = <String, dynamic>{'date': dateStr};
      if (mealType != null) {
        queryParams['meal_type'] = mealType;
      }

      final token = await SecureStorage.getAccessToken();

      final response = await _retryRequest(
            () => _dio.get(
          AppConstants.mealsByDateEndpoint,
          queryParameters: queryParams,
          options: Options(
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data is List) {
          final logs = data
              .map((json) {
            try {
              return MealLog.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              Logger.error('Failed to parse meal log: $e');
              return null;
            }
          })
              .whereType<MealLog>()
              .toList();

          Logger.success('Fetched ${logs.length} meal logs for $dateStr');
          return Result.success(logs);
        }

        if (data is Map<String, dynamic>) {
          if (data.containsKey('meals') && data['meals'] is List) {
            final logs = (data['meals'] as List)
                .map((json) {
              try {
                return MealLog.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                Logger.error('Failed to parse meal log: $e');
                return null;
              }
            })
                .whereType<MealLog>()
                .toList();

            Logger.success('Fetched ${logs.length} meal logs for $dateStr');
            return Result.success(logs);
          }

          if (data.containsKey('results') && data['results'] is List) {
            final logs = (data['results'] as List)
                .map((json) {
              try {
                return MealLog.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                Logger.error('Failed to parse meal log: $e');
                return null;
              }
            })
                .whereType<MealLog>()
                .toList();

            Logger.success('Fetched ${logs.length} meal logs for $dateStr');
            return Result.success(logs);
          }

          if (data.isEmpty) {
            Logger.info('No meals found for $dateStr');
            return Result.success([]);
          }

          try {
            final log = MealLog.fromJson(data);
            Logger.success('Fetched 1 meal log for $dateStr');
            return Result.success([log]);
          } catch (e) {
            Logger.error('Failed to parse single meal log: $e');
            return Result.success([]);
          }
        }

        if (data == null) {
          Logger.info('No meals found for $dateStr');
          return Result.success([]);
        }

        Logger.warning('Unexpected response format for meals by date: ${data.runtimeType}');
        return Result.success([]);
      }

      return Result.failure(
        ApiError.fromResponse(response.data, response.statusCode),
      );
    } on DioException catch (e) {
      return Result.failure(_handleDioError(e));
    } catch (e, stackTrace) {
      Logger.error('Unexpected error: $e\n$stackTrace');
      return Result.failure(ApiError.network('Ma\'lumotlarni yuklashda xatolik'));
    }
  }

  /// Logout
  Future<void> logout() async {
    await SecureStorage.deleteAllTokens();
    Logger.info('Logged out');
  }

  /// Login status
  Future<bool> isLoggedIn() async {
    return await SecureStorage.isLoggedIn();
  }

  /// Retry logic - network xatoliklari uchun
  Future<Response> _retryRequest(
      Future<Response> Function() request, {
        int maxAttempts = AppConstants.maxRetryAttempts,
      }) async {
    int attempts = 0;

    while (attempts < maxAttempts) {
      try {
        return await request();
      } on DioException catch (e) {
        attempts++;

        final shouldRetry = _shouldRetry(e, attempts, maxAttempts);

        if (!shouldRetry) {
          rethrow;
        }

        Logger.warning(
          'Request failed, retrying... (${attempts}/$maxAttempts)',
        );

        await Future.delayed(AppConstants.retryDelay * attempts);
      }
    }

    throw DioException(
      requestOptions: RequestOptions(path: ''),
      error: 'Max retry attempts reached',
    );
  }

  /// Retry qilish kerakmi?
  bool _shouldRetry(DioException error, int attempts, int maxAttempts) {
    if (attempts >= maxAttempts) return false;

    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// DioException ni ApiError ga o'zgartirish
  ApiError _handleDioError(DioException e) {
    Logger.error('DioException: ${e.type} - ${e.message}');

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout();

      case DioExceptionType.connectionError:
        return ApiError.network('Internetga ulanishda xatolik');

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;

        if (statusCode == 401) {
          return ApiError.unauthorized();
        } else if (statusCode == 404) {
          return ApiError.fromResponse(e.response?.data, statusCode);
        } else if (statusCode == 409) {
          return ApiError.fromResponse(e.response?.data, statusCode);
        } else if (statusCode == 400) {
          return ApiError.fromResponse(e.response?.data, statusCode);
        }

        return ApiError.fromResponse(e.response?.data, statusCode);

      default:
        return ApiError.network('Serverga ulanishda xatolik');
    }
  }
}