import 'package:dio/dio.dart';

class AppDioFactory {
  const AppDioFactory._();

  static Dio create() {
    return Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 10),
        responseType: ResponseType.plain,
        validateStatus: (status) => status != null && status >= 200 && status < 500,
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36',
        },
      ),
    );
  }
}
