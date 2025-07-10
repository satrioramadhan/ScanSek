import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/data/services/api_service.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:scan_sek/app/data/services/login_service.dart';
import 'package:scan_sek/app/data/services/register_service.dart';
import 'package:scan_sek/app/modules/auth/views/verify_otp_view.dart'
    as VerifyOtp;
import 'package:scan_sek/app/modules/auth/views/verify_reset_otp_view.dart'
    as VerifyResetOtp;
import 'package:scan_sek/app/modules/auth/views/set_new_password_view.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart';
import 'package:scan_sek/app/utils/device_helper.dart';
import 'package:dio/dio.dart' as dio;

class AuthController extends GetxController {
  var isLoggedIn = false.obs;

  void login(String email, String pass) async {
    try {
      final res = await LoginService.loginUser(email, pass);
      print('Login response: ${res.statusCode}, body: ${res.data}');

      if (res.statusCode == 200 && res.data['success'] == true) {
        // ✅ Login sukses
        final data = res.data['data'];
        await _saveLoginData(data);
        final deviceInfo = await DeviceHelper.getDeviceInfo();
        print("📤 Kirim log login: $deviceInfo");

        try {
          await ApiService.logLoginActivity(deviceInfo);
          print("✅ Log login terkirim!");
        } catch (e) {
          print("❌ Gagal kirim log login: $e");
        }
        SnackbarHelper.show(
            'Berhasil', res.data['message'] ?? 'Login berhasil!',
            type: 'success');
        Get.offAllNamed(Routes.HOME);
      } else if (res.data['otp_sent'] == true) {
        // ✅ Email belum diverifikasi, OTP dikirim
        final user = res.data['user'];
        final refreshToken = res.data['refresh_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('email', user['email']);
        await prefs.setString('username', user['username']);

        int resendCount = (prefs.getInt('otp_resend_count') ?? 0) + 1;
        prefs.setInt('otp_resend_count', resendCount);
        int interval = resendCount < 3 ? 15 : 300;
        await _saveOtpCountdown('otp_countdown_end', interval);

        SnackbarHelper.show(
            'Verifikasi', res.data['message'] ?? 'OTP dikirim ke email.',
            type: 'warning');
        Future.delayed(Duration(milliseconds: 300), () {
          Get.offAll(() => VerifyOtp.VerifyOtpView(email: user['email']));
        });
      } else if (res.statusCode == 400) {
        // ✅ Bad Request (input salah atau akun Google)
        SnackbarHelper.show(
            'Login Gagal', res.data['message'] ?? 'Permintaan tidak valid',
            type: 'error');
      } else if (res.statusCode == 401) {
        // ✅ Unauthorized (password salah)
        SnackbarHelper.show(
            'Password Salah', res.data['message'] ?? 'Password Anda salah',
            type: 'error');
      } else if (res.statusCode == 403) {
        // ✅ Forbidden (verifikasi gagal)
        SnackbarHelper.show(
            'Akses Ditolak', res.data['message'] ?? 'Akses ditolak',
            type: 'error');
      } else if (res.statusCode == 404) {
        // ✅ Not Found (email tidak terdaftar)
        SnackbarHelper.show('Email Tidak Terdaftar',
            res.data['message'] ?? 'Email belum terdaftar',
            type: 'error');
      } else {
        // ✅ Lainnya
        SnackbarHelper.show(
            'Login Gagal', res.data['message'] ?? 'Terjadi kesalahan',
            type: 'error');
      }
    } on dio.DioException catch (e) {
      print('Dio error: ${e.response?.statusCode}, data: ${e.response?.data}');
      if (e.response?.data != null && e.response?.data['otp_sent'] == true) {
        final user = e.response?.data['user'];
        final refreshToken = e.response?.data['refresh_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('email', user['email']);
        await prefs.setString('username', user['username']);

        int resendCount = (prefs.getInt('otp_resend_count') ?? 0) + 1;
        prefs.setInt('otp_resend_count', resendCount);
        int interval = resendCount < 3 ? 15 : 300;
        await _saveOtpCountdown('otp_countdown_end', interval);

        SnackbarHelper.show('Verifikasi',
            e.response?.data['message'] ?? 'OTP dikirim ke email.',
            type: 'warning');
        Future.delayed(Duration(milliseconds: 300), () {
          Get.offAll(() => VerifyOtp.VerifyOtpView(email: user['email']));
        });
      } else {
        // ✅ Error jaringan/server
        String message = e.response?.data['message'] ??
            e.message ??
            'Terjadi kesalahan jaringan';
        SnackbarHelper.show('Error', message, type: 'error');
      }
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> verifikasiOtp(String email, String otp) async {
    if (otp.length < 6) {
      SnackbarHelper.show('Error', 'Masukkan OTP lengkap', type: 'warning');
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      final res = await ApiService.dioClient.post(
        '/auth/verify-otp',
        data: {'email': email, 'otp': otp, 'refresh_token': refreshToken},
      );

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        await _saveLoginData(data);
        SnackbarHelper.show(
            'Berhasil', 'Email berhasil diverifikasi & auto-login!',
            type: 'success');
        await _resetOtpState();
        Get.offAllNamed(Routes.HOME);
      } else {
        SnackbarHelper.show('Gagal', res.data['message'] ?? 'OTP tidak valid',
            type: 'error');
      }
    } on dio.DioException catch (e) {
      String message =
          e.response?.data['message'] ?? 'Terjadi kesalahan pada server.';
      SnackbarHelper.show('Error', message, type: 'error');
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  Future<void> _saveLoginData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sudahLogin', true);
    await prefs.setString('token', data['token']);
    await prefs.setString('refresh_token', data['refresh_token']);
    final user = data['user'];
    await prefs.setString('username', user['username']);
    await prefs.setString('email', user['email']);
    ApiService.dioClient.options.headers['Authorization'] =
        'Bearer ${data['token']}';
    isLoggedIn.value = true;

    await _resetOtpState();
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        Get.back();
        SnackbarHelper.show('Info', 'Login Google dibatalkan.', type: 'info');
        return;
      }

      final idToken = (await googleUser.authentication).idToken;

      dio.Response res;
      try {
        res = await ApiService.dioClient
            .post('/auth/google-login', data: {'id_token': idToken});
      } on dio.DioException catch (e) {
        res = e.response!;
      }

      if (res.statusCode == 200 && res.data['success'] == true) {
        await _saveLoginData(res.data['data']);
        Get.back();
        SnackbarHelper.show('Berhasil', 'Login Google berhasil',
            type: 'success');
        Get.offAllNamed(Routes.HOME);
      } else if (res.statusCode == 403 &&
          res.data['message']?.contains('Email belum diverifikasi') == true) {
        final user = res.data['user'];
        final userEmail = user != null ? user['email'] : googleUser.email;
        Get.back();
        SnackbarHelper.show('Verifikasi',
            'Akun Google Anda belum diverifikasi. Cek email Anda.',
            type: 'warning');
        Future.delayed(Duration(milliseconds: 300), () {
          Get.offAll(() => VerifyOtp.VerifyOtpView(email: userEmail));
        });
      } else {
        Get.back();
        SnackbarHelper.show(
            'Gagal', res.data['message'] ?? 'Gagal login Google',
            type: 'error');
      }
    } catch (e) {
      Get.back();
      SnackbarHelper.show('Error', 'Gagal login Google: $e', type: 'error');
    }
  }

  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final refreshToken = prefs.getString('refresh_token');
    if (token != null && refreshToken != null) {
      ApiService.dioClient.options.headers['Authorization'] = 'Bearer $token';
      isLoggedIn.value = true;
    } else {
      isLoggedIn.value = false;
    }
  }

  Future<void> _resetOtpState() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('otp_resend_count');
    prefs.remove('otp_countdown_end');
    prefs.remove('reset_otp_resend_count');
    prefs.remove('reset_otp_countdown_end');
  }

  Future<void> _saveOtpCountdown(String key, int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    final endTimestamp =
        DateTime.now().add(Duration(seconds: seconds)).millisecondsSinceEpoch;
    await prefs.setInt(key, endTimestamp);
  }

  Future<int> getRemainingOtpCountdown(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final endTimestamp = prefs.getInt(key) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return ((endTimestamp - now) / 1000).ceil();
  }

  void register(String user, String email, String pass) async {
    try {
      final res = await RegisterService.registerUser(user, email, pass);
      if (res.statusCode == 201 && res.data['success'] == true) {
        await _resetOtpState(); // ✅ Reset awal
        await ApiService.resendOtp(email, 'verifikasi');
        SnackbarHelper.show('Registrasi Berhasil', 'Silakan verifikasi email',
            type: 'success');
        Get.to(() => VerifyOtp.VerifyOtpView(email: email));
      } else {
        // Tangani response yang gagal dengan message backend
        SnackbarHelper.show('Gagal Registrasi', res.data['message'] ?? 'Gagal',
            type: 'error');
      }
    } on dio.DioException catch (e) {
      // Tangkap error dari Dio (contoh error 400, 500)
      String message = 'Terjadi kesalahan';
      if (e.response?.data != null && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      } else if (e.message != null) {
        message = e.message!;
      }
      SnackbarHelper.show('Error', message, type: 'error');
    } catch (e) {
      // Tangkap error selain Dio (contoh parsing error, dll)
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    isLoggedIn.value = false;
    Get.offAllNamed(Routes.LOGIN);
  }

  Future<void> sendResetOtp(String email) async {
    try {
      await _resetOtpState(); // ✅ Reset awal
      final res = await ApiService.resendOtp(email, 'reset');

      // 🌟 Tangani response sesuai backend
      if (res.statusCode == 200 && res.data['success'] == true) {
        SnackbarHelper.show(
            'Sukses', res.data['message'] ?? 'OTP berhasil dikirim',
            type: 'success');
        Get.to(() => VerifyResetOtp.VerifyResetOtpView(email: email));
      } else if (res.statusCode == 404) {
        // 🌟 Email ga ketemu (dari backend)
        SnackbarHelper.show('Email Tidak Ditemukan',
            res.data['message'] ?? 'Email tidak terdaftar',
            type: 'warning');
      } else if (res.statusCode == 400) {
        // 🌟 Validasi input salah (misal email kosong/invalid)
        SnackbarHelper.show('Input Tidak Valid',
            res.data['message'] ?? 'Periksa kembali input Anda',
            type: 'warning');
      } else if (res.statusCode == 429) {
        // 🌟 Limit request OTP
        SnackbarHelper.show(
            'Limit Tercapai',
            res.data['message'] ??
                'Terlalu banyak permintaan. Coba lagi nanti.',
            type: 'warning');
      } else {
        // 🌟 Default tangkapan response
        SnackbarHelper.show('Error', res.data['message'] ?? 'Terjadi kesalahan',
            type: 'error');
      }
    } on dio.DioException catch (e) {
      // 🌟 Tangkap error jaringan/server
      String message =
          e.response?.data['message'] ?? e.message ?? 'Terjadi kesalahan';
      SnackbarHelper.show('Error', message, type: 'error');
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  Future<void> verifyResetOtp(String email, String otp) async {
    if (otp.length < 6) {
      SnackbarHelper.show(
        'Error',
        'Masukkan OTP lengkap',
        type: 'error',
      );
      return;
    }

    try {
      final res = await ApiService.verifyResetOtp(email, otp);

      if (res.statusCode == 200 && res.data['success'] == true) {
        SnackbarHelper.show(
          'Sukses',
          res.data['message'] ?? 'OTP terverifikasi',
          type: 'success',
        );
        await _resetOtpState();
        Get.to(() => SetNewPasswordView(email: email, otp: otp));
      } else if (res.statusCode == 400) {
        SnackbarHelper.show(
          'OTP Salah',
          res.data['message'] ?? 'Kode OTP salah atau kadaluarsa',
          type: 'error',
        );
      } else if (res.statusCode == 404) {
        SnackbarHelper.show(
          'Email Tidak Ditemukan',
          res.data['message'] ?? 'Email tidak terdaftar',
          type: 'warning',
        );
      } else {
        SnackbarHelper.show(
          'Error',
          res.data['message'] ?? 'Terjadi kesalahan',
          type: 'error',
        );
      }
    } on dio.DioException catch (e) {
      String message = e.response?.data['message'] ??
          e.message ??
          'Terjadi kesalahan jaringan';
      SnackbarHelper.show(
        'Error',
        message,
        type: 'error',
      );
    } catch (e) {
      SnackbarHelper.show(
        'Error',
        e.toString(),
        type: 'error',
      );
    }
  }

  Future<void> setNewPassword(
      String email, String otp, String newPassword) async {
    try {
      final res = await ApiService.resetPassword(email, otp, newPassword);
      if (res.statusCode == 200 && res.data['success'] == true) {
        SnackbarHelper.show('Berhasil', 'Password berhasil direset',
            type: 'success');
        Get.offAllNamed(Routes.LOGIN);
      } else {
        // Tangkap message spesifik dari backend
        String message = res.data['message'] ?? 'Reset password gagal';
        SnackbarHelper.show('Gagal', message, type: 'error');
      }
    } on dio.DioException catch (e) {
      // Tangkap error spesifik dari backend
      String message =
          e.response?.data['message'] ?? e.message ?? 'Terjadi kesalahan';
      SnackbarHelper.show('Error', message, type: 'error');
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  Future<void> resendOtp(String email) async {
    await resendOtpHandler(
        email, 'verifikasi', 'otp_resend_count', 'otp_countdown_end');
  }

  Future<void> resendResetOtp(String email) async {
    await resendOtpHandler(
        email, 'reset', 'reset_otp_resend_count', 'reset_otp_countdown_end');
  }

  Future<void> resendOtpHandler(
      String email, String type, String countKey, String endKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int count = (prefs.getInt(countKey) ?? 0) + 1;
      prefs.setInt(countKey, count);

      int interval = count < 3 ? 15 : 300;
      await _saveOtpCountdown(endKey, interval);

      final res = await ApiService.resendOtp(email, type);
      if (res.statusCode == 200) {
        SnackbarHelper.show('Sukses', 'OTP baru telah dikirim ke email',
            type: 'success');
      } else if (res.statusCode == 429) {
        SnackbarHelper.show('Limit Tercapai',
            'Terlalu banyak permintaan OTP. Coba lagi dalam 5 menit.',
            type: 'warning');
      } else {
        SnackbarHelper.show(
            'Gagal', res.data['message'] ?? 'Gagal kirim ulang OTP',
            type: 'error');
      }
    } on dio.DioException catch (e) {
      String message =
          e.response?.data['message'] ?? e.message ?? 'Terjadi kesalahan';
      SnackbarHelper.show('Error', message, type: 'error');
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }
}
