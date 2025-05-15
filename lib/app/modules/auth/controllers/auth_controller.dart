import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:scan_sek/app/data/services/login_service.dart';
import 'package:scan_sek/app/data/services/register_service.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;

  void login(String email, String pass) async {
    try {
      final res = await LoginService.loginUser(email, pass);

      if (res.statusCode == 200 && res.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final data = res.data['data'];
        final user = data['user'];

        await prefs.setBool('sudahLogin', true);
        await prefs.setString('token', data['token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('username', user['username']);
        await prefs.setString('email', user['email']);

        isLoggedIn.value = true;
        Get.snackbar('Berhasil', 'Login berhasil!');
        Get.offAllNamed(Routes.HOME);
      } else {
        final message = res.data['message'] ?? 'Gagal login.';
        if (kDebugMode) print("Login gagal: $message");
        Get.snackbar('Gagal Login', message);
      }
    } on DioException catch (e) {
      final response = e.response;
      final message =
          response?.data['message'] ?? 'Terjadi kesalahan saat login.';
      if (kDebugMode) print("Dio error login: $message");
      Get.snackbar('Error', message);
    } catch (e) {
      if (kDebugMode) print("Error umum login: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat login: $e');
    }
  }

  void register(String user, String email, String pass) async {
    try {
      final res = await RegisterService.registerUser(user, email, pass);

      if (res.statusCode == 201 && res.data['success'] == true) {
        if (kDebugMode) print("Registrasi berhasil: ${res.data}");
        Get.snackbar('Registrasi Berhasil', 'Silakan login.');
        Get.toNamed(Routes.LOGIN);
      } else {
        final message = res.data['message'] ?? 'Gagal registrasi.';
        if (kDebugMode) print("Registrasi gagal: $message");
        Get.snackbar('Gagal Registrasi', message);
      }
    } on DioException catch (e) {
      final response = e.response;
      final message =
          response?.data['message'] ?? 'Terjadi kesalahan saat registrasi.';
      if (kDebugMode) print("Dio error register: $message");
      Get.snackbar('Error', message);
    } catch (e) {
      if (kDebugMode) print("Error umum register: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat registrasi: $e');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn.value = false;
    Get.offAllNamed(Routes.LOGIN);
    Get.snackbar('Berhasil Logout', 'Kamu telah keluar dari akun');
  }
}
