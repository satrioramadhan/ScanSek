import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/data/services/api_service.dart';
import 'package:scan_sek/app/routes/app_pages.dart';

class ProfileController extends GetxController {
  var username = ''.obs;
  var email = ''.obs;
  var reminder = ''.obs;
  var isLoading = true.obs;
  var newUsername = ''.obs;
  var newEmail = ''.obs;
  var newPassword = ''.obs;
  var currentPassword = ''.obs;
  var showCurrentPasswordField = false.obs;
  var obscureNewPassword = true.obs;
  var obscureCurrentPassword = true.obs;
  final loginHistory = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserInfo();
  }

  Future<void> fetchUserInfo() async {
    try {
      final res = await ApiService.dioClient.get('/auth/user/info');
      if (res.statusCode == 200 && res.data['success'] == true) {
        final data = res.data['data'];
        username.value = data['username'] ?? 'Tidak Diketahui';
        email.value = data['email'] ?? 'Tidak Diketahui';
        reminder.value = data['reminder'] ?? '';

        // Default buat edit form
        newUsername.value = username.value;
        newEmail.value = email.value;
      } else {
        Get.snackbar('Error', res.data['message'] ?? 'Gagal ambil data profil');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void checkPasswordField(String val) {
    newPassword.value = val;
    showCurrentPasswordField.value = val.isNotEmpty;
  }

  Future<void> saveChanges() async {
    try {
      final updates = {};
      if (newUsername.value.isNotEmpty) updates['username'] = newUsername.value;
      if (newEmail.value.isNotEmpty) updates['email'] = newEmail.value;
      if (newPassword.value.isNotEmpty) {
        if (currentPassword.value.isEmpty) {
          Get.snackbar('Error', 'Harap masukkan password saat ini');
          return;
        }
        updates['password'] = {
          'new': newPassword.value,
          'current': currentPassword.value,
        };
      }

      if (updates.isEmpty) {
        Get.snackbar('Info', 'Tidak ada perubahan');
        return;
      }

      final res =
          await ApiService.dioClient.put('/auth/update-profile', data: updates);
      if (res.statusCode == 200 && res.data['success'] == true) {
        Get.snackbar('Sukses', 'Profil diperbarui');
        fetchUserInfo();
        Get.back();
      } else {
        Get.snackbar('Gagal', res.data['message'] ?? 'Update gagal');
      }
    } catch (e) {
      Get.snackbar('Error', e.toString());
    }
  }

  Future<void> fetchLoginHistory() async {
    try {
      final res = await ApiService.dioClient.get('/auth/login-history');
      if (res.statusCode == 200 && res.data['success'] == true) {
        loginHistory.value = List<Map<String, dynamic>>.from(res.data['data']);
      }
    } catch (e) {
      print("Gagal ambil login history: $e");
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed(Routes.LOGIN);
    Get.snackbar('Berhasil Logout', 'Kamu telah keluar dari akun');
  }

  Future<void> logoutAndGoToForgotPassword() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAllNamed(Routes.FORGOT_PASSWORD);
  }
}
