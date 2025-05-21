import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/data/services/api_service.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:scan_sek/app/data/services/login_service.dart';
import 'package:scan_sek/app/data/services/register_service.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;

  void login(String email, String pass) async {
    try {
      final res = await LoginService.loginUser(email, pass);

      if (res.statusCode == 200 &&
          res.data is Map &&
          res.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final data = res.data['data'];
        final user = data['user'];

        await prefs.setBool('sudahLogin', true);
        await prefs.setString('token', data['token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('username', user['username']);
        await prefs.setString('email', user['email']);

        ApiService.dio.options.headers['Authorization'] =
            'Bearer ${data['token']}';

        isLoggedIn.value = true;
        print("✅ Login sukses. Token: ${data['token']}");
        Get.snackbar('Berhasil', 'Login berhasil!');
        Get.offAllNamed(Routes.HOME);
      } else {
        print("❌ Response login gak valid: ${res.data}");
        Get.snackbar('Gagal Login', 'Login gagal: response tidak sesuai');
      }
    } on DioException catch (e) {
      final response = e.response;
      final message =
          response?.data['message'] ?? 'Terjadi kesalahan saat login.';
      print("🔥 DioException: ${e.message}");
      if (response != null) {
        print("🔥 DioResponse: ${response.data}");
        print("🔥 Status code: ${response.statusCode}");
      }
      Get.snackbar('Error', message);
    } catch (e) {
      print("🚨 General Error login: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat login: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // 🔁 Logout Google biar bisa pilih akun
      await googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null) {
        Get.snackbar('Error', 'Gagal mendapatkan ID Token dari Google');
        return;
      }

      // 🚀 Kirim id_token ke backend Flask
      final res = await ApiService.dio.post('/auth/google-login', data: {
        'id_token': idToken,
      });

      if (res.statusCode == 200 && res.data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final data = res.data['data'];
        final user = data['user'];

        await prefs.setBool('sudahLogin', true);
        await prefs.setString('token', data['token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        await prefs.setString('username', user['username']);
        await prefs.setString('email', user['email']);

        ApiService.dio.options.headers['Authorization'] =
            'Bearer ${data['token']}';

        isLoggedIn.value = true;
        print("✅ Google Login sukses. Token: ${data['token']}");
        Get.snackbar('Berhasil', 'Login Google berhasil!');
        Get.offAllNamed(Routes.HOME);
      } else {
        final msg = res.data['message'] ?? 'Gagal login Google';
        Get.snackbar('Gagal', msg);
      }
    } catch (e) {
      print("❌ Error Google Login: $e");
      Get.snackbar('Error', 'Terjadi kesalahan saat login Google');
    }
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');

    print("🔐 Saved token: $token");
    print("🔐 Saved refresh token: $refreshToken");

    if (token != null && refreshToken != null) {
      ApiService.dio.options.headers['Authorization'] = 'Bearer $token';
      isLoggedIn.value = true;
      print("🔄 AutoLogin: token tersedia, user masih login.");
    } else {
      print("⚠️ AutoLogin gagal: token/refresh_token kosong.");
      isLoggedIn.value = false;
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
