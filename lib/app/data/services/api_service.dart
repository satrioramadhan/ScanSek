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
          print(
              "📤 [Request] ${options.method} ${options.path} pakai token: $token");
        } else {
          print("⚠️ [Request] Tanpa token: ${options.method} ${options.path}");
        }
        options.headers['Content-Type'] = 'application/json';
        return handler.next(options);
      },
      onError: (error, handler) async {
        // 🔍 DEBUG LOG: untuk tau interceptor kepanggil
        print("🪵 Interceptor Error Handler");
        print("➡️ Error status: ${error.response?.statusCode}");
        print("➡️ Path: ${error.requestOptions.path}");

        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/refresh')) {
          print("⚠️ 401 Unauthorized terdeteksi → coba refresh token...");

          final prefs = await SharedPreferences.getInstance();
          final refreshToken = prefs.getString('refresh_token');

          if (refreshToken != null) {
            print("🔁 Kirim refresh token: $refreshToken");

            try {
              final refreshDio = Dio(BaseOptions(baseUrl: baseUrl));
              final response = await refreshDio.post(
                '/auth/refresh',
                options: Options(headers: {
                  'Authorization': 'Bearer $refreshToken',
                  'Content-Type': 'application/json',
                }),
              );

              final newToken = response.data['token'];
              print("✅ Refresh sukses. New token: $newToken");

              await prefs.setString('token', newToken);

              final req = error.requestOptions;
              req.headers['Authorization'] = 'Bearer $newToken';

              print("🔄 Ulang request ke: ${req.method} ${req.path}");
              final clonedResponse = await dio.fetch(req);
              return handler.resolve(clonedResponse);
            } catch (e) {
              print("❌ Refresh gagal: $e");
              await prefs.remove('token');
              await prefs.remove('refresh_token');
              await prefs.setBool('sudahLogin', false);
              Get.offAllNamed('/login');
              return handler.next(error);
            }
          } else {
            print("❌ Tidak ada refresh token di local storage");
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
