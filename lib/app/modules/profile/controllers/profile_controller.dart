import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/data/services/api_service.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart'; // 🔥 Import SnackbarHelper

class ProfileController extends GetxController {
  var username = ''.obs;
  var email = ''.obs;
  var reminder = ''.obs;
  var isLoading = true.obs;
  var newUsername = ''.obs;
  var newEmail = ''.obs;
  var newPassword = ''.obs;
  var confirmPassword = ''.obs;
  var currentPassword = ''.obs;
  var showPasswordFields = false.obs;
  var obscureNewPassword = true.obs;
  var obscureConfirmPassword = true.obs;
  var obscureCurrentPassword = true.obs;
  var hasExistingPassword = false.obs;
  var isCreatingPassword = false.obs;
  var isSavingChanges = false.obs;
  final loginHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      isLoading.value = true;
      final res = await ApiService.dioClient.get('/auth/user/info');

      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        username.value = data['username'] ?? 'Tidak Diketahui';
        email.value = data['email'] ?? 'Tidak Diketahui';
        reminder.value = data['reminder'] ?? '';
        hasExistingPassword.value = data['has_password'] ?? false;
        newUsername.value = username.value;
        newEmail.value = email.value;
        _resetPasswordFields();
      }
    } catch (e) {
      // error handling...
    } finally {
      isLoading.value = false;
    }
  }

  // 🔥 Dipanggil saat user ngetik di field password
  void onPasswordChanged(String value) {
    newPassword.value = value;

    // Show additional fields only if user is typing password
    showPasswordFields.value = value.isNotEmpty;
  }

  void _resetPasswordFields() {
    newPassword.value = '';
    confirmPassword.value = '';
    currentPassword.value = '';
    showPasswordFields.value = false;
    obscureNewPassword.value = true;
    obscureConfirmPassword.value = true;
    obscureCurrentPassword.value = true;
  }

  bool _validatePasswordFields() {
    if (newPassword.value.isEmpty) {
      SnackbarHelper.show(
        'Error',
        'Password baru tidak boleh kosong',
        type: 'error',
      );
      return false;
    }

    if (confirmPassword.value.isEmpty) {
      SnackbarHelper.show(
        'Error',
        'Konfirmasi password tidak boleh kosong',
        type: 'error',
      );
      return false;
    }

    if (newPassword.value != confirmPassword.value) {
      SnackbarHelper.show(
        'Error',
        'Password dan konfirmasi password tidak cocok',
        type: 'error',
      );
      return false;
    }

    // Validasi password strength
    if (newPassword.value.length < 6) {
      SnackbarHelper.show(
        'Error',
        'Password minimal 6 karakter',
        type: 'error',
      );
      return false;
    }

    // Jika user sudah punya password, wajib isi password saat ini
    if (hasExistingPassword.value && currentPassword.value.isEmpty) {
      SnackbarHelper.show(
        'Error',
        'Password saat ini wajib diisi',
        type: 'error',
      );
      return false;
    }

    return true;
  }

  // 🔥 Check if there are any changes made
  bool _hasChanges() {
    // Check username changes
    bool usernameChanged =
        newUsername.value.isNotEmpty && newUsername.value != username.value;

    // Check email changes (although email field is locked, we still check for completeness)
    bool emailChanged =
        newEmail.value.isNotEmpty && newEmail.value != email.value;

    // Check password changes
    bool passwordChanged = newPassword.value.isNotEmpty;

    return usernameChanged || emailChanged || passwordChanged;
  }

  Future<void> saveProfile() async {
    try {
      if (!_hasChanges()) {
        SnackbarHelper.show(
          'Info',
          'Tidak ada perubahan yang dilakukan',
          type: 'info',
        );
        return;
      }

      final isPasswordAction = newPassword.value.isNotEmpty;

      if (isPasswordAction) {
        if (!_validatePasswordFields()) return;

        if (hasExistingPassword.value) {
          isSavingChanges.value = true;
        } else {
          isCreatingPassword.value = true;
        }
      } else {
        isSavingChanges.value = true;
      }

      final updates = {};

      if (newUsername.value.isNotEmpty && newUsername.value != username.value) {
        updates['username'] = newUsername.value;
      }

      if (isPasswordAction) {
        if (hasExistingPassword.value) {
          updates['password'] = {
            'new': newPassword.value,
            'current': currentPassword.value,
          };
        } else {
          updates['password'] = newPassword.value;
        }
      }

      print("🔥 FINAL UPDATES: $updates"); // DEBUG

      final res = await ApiService.dioClient.put(
        '/auth/update-profile',
        data: updates,
        options: dio.Options(contentType: 'application/json'),
      );

      print("🔥 RESPONSE STATUS: ${res.statusCode}");
      print("🔥 RESPONSE DATA: ${res.data}");

      if (res.statusCode == 200 && res.data['success'] == true) {
        String message = 'Profil berhasil diperbarui';

        if (isPasswordAction && !hasExistingPassword.value) {
          message =
              'Password berhasil dibuat! Sekarang Anda bisa login manual.';
        }

        SnackbarHelper.show(
          'Sukses',
          message,
          type: 'success',
          duration: Duration(seconds: 2),
        );

        _resetPasswordFields();
        await fetchUserInfo();

        await Future.delayed(Duration(milliseconds: 2300));
        print("🔥 CAN POP? ${Navigator.canPop(Get.context!)}");
        print("🔥 CURRENT ROUTE: ${Get.currentRoute}");

        Get.offAllNamed(Routes.PROFILE);
      } else {
        SnackbarHelper.show(
          'Gagal',
          res.data['message'] ?? 'Gagal memperbarui profil',
          type: 'error',
        );
      }
    } catch (e) {
      if (e is dio.DioException) {
        final resData = e.response?.data;
        final msg = resData?['message'] ?? 'Terjadi kesalahan tidak diketahui';
        print("🔥 ERROR DETAIL: $msg");
        SnackbarHelper.show(
          'Gagal',
          msg,
          type: 'error',
        );
      } else {
        print("🔥 UNKNOWN ERROR: $e");
        SnackbarHelper.show(
          'Error',
          'Gagal terhubung ke server',
          type: 'error',
        );
      }
    } finally {
      isSavingChanges.value = false;
      isCreatingPassword.value = false;
    }
  }

  // 🔥 Getter untuk label password field
  String get passwordFieldLabel {
    return hasExistingPassword.value ? "Ubah Password" : "Buat Password Baru";
  }

  // 🔥 Getter untuk label button
  String get buttonLabel {
    return hasExistingPassword.value ? "Simpan Perubahan" : "Buat Password";
  }

  // 🔥 Getter untuk icon button
  IconData get buttonIcon {
    return hasExistingPassword.value
        ? Icons.save_outlined
        : Icons.lock_outlined;
  }

  // 🔥 Getter untuk show current password field
  bool get shouldShowCurrentPasswordField {
    return hasExistingPassword.value && showPasswordFields.value;
  }

  Future<void> fetchLoginHistory() async {
    try {
      final res = await ApiService.dioClient.get('/auth/login-history');
      if (res.statusCode == 200 && res.data['success'] == true) {
        loginHistory.value = List<Map<String, dynamic>>.from(res.data['data']);
      }
    } catch (e) {
      print("Gagal mengambil riwayat login: $e");
    }
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAllNamed(Routes.LOGIN);
      SnackbarHelper.show(
        'Berhasil Logout',
        'Anda telah keluar dari akun',
        type: 'success',
      );
    } catch (e) {
      print("Error saat logout: $e");
    }
  }

  Future<void> logoutAndGoToForgotPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAllNamed(Routes.FORGOT_PASSWORD);
    } catch (e) {
      print("Error saat logout: $e");
    }
  }
}
