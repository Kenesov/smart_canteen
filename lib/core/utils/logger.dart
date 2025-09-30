class Logger {
  static void log(String message, {String tag = 'APP'}) {
    print('[$tag] $message');
  }

  static void error(String message, {String tag = 'ERROR'}) {
    print('[$tag] $message');
  }

  static void success(String message, {String tag = 'SUCCESS'}) {
    print('[$tag] $message');
  }

  static void warning(String message, {String tag = 'WARNING'}) {
    print('[$tag] $message');
  }

  static void info(String message, {String tag = 'INFO'}) {
    print('[$tag] $message');
  }

  static void api(String method, String url, {int? statusCode, dynamic data}) {
    print('API REQUEST: $method $url');
    if (statusCode != null) {
      print('Status Code: $statusCode');
    }
    if (data != null) {
      print('Data: $data');
    }
  }

  static void faceDetection(String message) {
    print('[FACE] $message');
  }

  static void audio(String message) {
    print('[AUDIO] $message');
  }
}