import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scan_sek/app/routes/app_pages.dart';

class ProfileController extends GetxController {
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // atau bisa pake remove('token'), dll
    Get.offAllNamed(Routes.LOGIN);
    Get.snackbar('Berhasil Logout', 'Kamu telah keluar dari akun');
  }
}
