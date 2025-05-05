import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://164.92.109.4/';
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(InterceptorsWrapper(
      onError: (DioError error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 401) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('token');
          await prefs.setBool('sudahLogin', false);

          Get.snackbar("Sesi Berakhir", "Silakan login ulang");
          Get.offAllNamed('/login'); // Ganti dengan route login kamu
        }
        return handler.next(error); // Teruskan error
      },
    ));
}
