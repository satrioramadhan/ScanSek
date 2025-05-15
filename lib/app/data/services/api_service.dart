import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://164.92.109.4/api';
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  )..interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');

          if (refreshToken != null) {
            try {
              final response = await dio.post('/auth/refresh',
                  options: Options(headers: {
                    'Authorization': 'Bearer $refreshToken',
                  }));

              final newToken = response.data['token'];
              await prefs.setString('token', newToken);

              // Retry original request
              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer $newToken';
              final clonedResponse = await dio.fetch(req);
              return handler.resolve(clonedResponse);
            } catch (e) {
              await prefs.remove('token');
              await prefs.remove('refresh_token');
              await prefs.setBool('sudahLogin', false);
              Get.offAllNamed('/login');
              return handler.next(error);
            }
          } else {
            await prefs.remove('token');
            await prefs.setBool('sudahLogin', false);
            Get.offAllNamed('/login');
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
}
