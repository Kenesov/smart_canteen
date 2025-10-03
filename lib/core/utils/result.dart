/// Result type for better error handling
/// Success yoki Error bo'lishi mumkin
class Result<T, E> {
  final T? _value;
  final E? _error;
  final bool isSuccess;

  const Result._success(this._value)
      : _error = null,
        isSuccess = true;

  const Result._failure(this._error)
      : _value = null,
        isSuccess = false;

  factory Result.success(T value) => Result._success(value);
  factory Result.failure(E error) => Result._failure(error);

  bool get isFailure => !isSuccess;

  T get value {
    if (!isSuccess) {
      throw Exception('Cannot get value from failure result');
    }
    return _value!;
  }

  E get error {
    if (isSuccess) {
      throw Exception('Cannot get error from success result');
    }
    return _error!;
  }

  /// Pattern matching
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) {
    if (isSuccess) {
      return success(_value as T);
    } else {
      return failure(_error as E);
    }
  }
}

/// API xatolari uchun class
class ApiError {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final dynamic details;

  const ApiError({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.details,
  });

  factory ApiError.fromResponse(dynamic response, int? statusCode) {
    String message = 'Xatolik yuz berdi';
    String? errorCode;

    if (response is Map<String, dynamic>) {
      // Backend message ni olish
      if (response.containsKey('message')) {
        message = response['message'].toString();
      } else if (response.containsKey('error')) {
        message = response['error'].toString();
      } else if (response.containsKey('detail')) {
        message = response['detail'].toString();
      }

      // Error code
      if (response.containsKey('code')) {
        errorCode = response['code'].toString();
      }
    }

    return ApiError(
      message: message,
      statusCode: statusCode,
      errorCode: errorCode,
      details: response,
    );
  }

  factory ApiError.network(String message) {
    return ApiError(message: message, statusCode: null);
  }

  factory ApiError.timeout() {
    return const ApiError(
      message: 'Serverga ulanishda vaqt tugadi',
      statusCode: 408,
    );
  }

  factory ApiError.unauthorized() {
    return const ApiError(
      message: 'Iltimos qaytadan kiring',
      statusCode: 401,
    );
  }

  factory ApiError.notFound() {
    return const ApiError(
      message: 'Ma\'lumot topilmadi',
      statusCode: 404,
    );
  }

  factory ApiError.serverError() {
    return const ApiError(
      message: 'Server xatosi',
      statusCode: 500,
    );
  }

  @override
  String toString() => 'ApiError($message, code: $statusCode)';
}