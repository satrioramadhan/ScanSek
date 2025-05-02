import 'package:get/get.dart';
import 'package:scan_sek/app/routes/app_pages.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthController extends GetxController {
  var isLoggedIn = false.obs;

  final username = ''.obs;
  final password = ''.obs;

  void login(String user, String pass) async {
    if (user == 'admin' && pass == '123') {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('sudahLogin', true); // ⬅️ SIMPAN STATUS LOGIN

      isLoggedIn.value = true;
      Get.offAllNamed(Routes.HOME);
    } else {
      Get.snackbar('Login Failed', 'Username atau password salah!');
    }
  }

  void register(String user, String email, String pass) {
    // Dummy registrasi
    print('Register: $user - $email');
    Get.snackbar('Register Berhasil', 'Silakan login.');
    Get.toNamed(Routes.LOGIN);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sudahLogin', false); // ⬅️ HAPUS STATUS LOGIN
    isLoggedIn.value = false;
    Get.offAllNamed(Routes.LOGIN);
  }
}
