import 'package:dio/dio.dart' as dio;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://172.184.197.28/api';

  static final dio.Dio dioClient = dio.Dio(
    dio.BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
    ),
  )..interceptors.add(dio.InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print(
              "📤 [Request] ${options.method} ${options.path} pakai token: $token");
        } else {
          print("⚠️ [Request] Tanpa token: ${options.method} ${options.path}");
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/refresh')) {
          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');
          if (refreshToken != null) {
            try {
              final refreshDio = dio.Dio(dio.BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                options: dio.Options(headers: {
                  'Authorization': 'Bearer $refreshToken',
                  'Content-Type': 'application/json',
                }),
              );
              final newToken = response.data['token'];
              await prefs.setString('token', newToken);
              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer $newToken';
              final clonedResponse = await dioClient.fetch(req);
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

  // 🔥 Tambahan function OTP pakai dio.Response
  static Future<dio.Response> verifyOtp(String email, String otp) {
    return dioClient
        .post('/auth/verify-otp', data: {'email': email, 'otp': otp});
  }

  static Future<dio.Response> resendOtp(String email, String purpose) {
    return dioClient
        .post('/auth/resend-otp', data: {'email': email, 'purpose': purpose});
  }

  static Future<dio.Response> resetPassword(
      String email, String otp, String newPassword) {
    return dioClient.post('/auth/reset-password',
        data: {'email': email, 'otp': otp, 'new_password': newPassword});
  }

  static Future<dio.Response> verifyResetOtp(String email, String otp) {
    return dioClient.post('/auth/verify-otp',
        data: {'email': email, 'otp': otp, 'purpose': 'reset'});
  }

  static Future<void> logLoginActivity(Map<String, dynamic> deviceInfo) async {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final body = {
      "timestamp": timestamp,
      "device": deviceInfo,
    };

    print("📤 Mengirim log login ke backend: $body");

    final res = await dioClient.post('/auth/log-login', data: body);

    print("✅ Response dari backend: ${res.statusCode} ${res.data}");
  }
}
