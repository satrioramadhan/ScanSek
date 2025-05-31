import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import 'verify_reset_otp_view.dart';
import 'package:scan_sek/app/modules/auth/controllers/auth_controller.dart';
import '../../../routes/app_pages.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart'; // Import SnackbarHelper

class ForgotPasswordView extends StatelessWidget {
  final controller = Get.find<AuthController>();
  final TextEditingController emailController = TextEditingController();

  void kirimOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      SnackbarHelper.show('Error', 'Email wajib diisi', type: 'warningr');
      return;
    }

    try {
      await controller.sendResetOtp(email);
    } catch (e) {
      SnackbarHelper.show('Error', e.toString(), type: 'error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Lupa Kata Sandi",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Masukkan Alamat Email',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: kirimOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: StadiumBorder(),
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('Kirim', style: TextStyle(fontSize: 16)),
            ),
            SizedBox(height: 16),
            Text("Atau", style: TextStyle(color: Colors.grey)),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                Get.dialog(Center(child: CircularProgressIndicator()),
                    barrierDismissible: false);
                await controller.signInWithGoogle();
                Get.back();
              },
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Image.asset('assets/icons/google.png', height: 30),
              ),
            ),
            SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.toNamed(Routes.LOGIN),
              child: Text('Kembali ke Login',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }
}
