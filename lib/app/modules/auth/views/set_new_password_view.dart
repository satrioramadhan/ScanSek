import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scan_sek/app/modules/auth/controllers/auth_controller.dart';
import 'package:scan_sek/app/utils/snackbar_helper.dart'; // Import SnackbarHelper

class SetNewPasswordView extends StatefulWidget {
  final String email;
  final String otp;

  SetNewPasswordView({required this.email, required this.otp});

  @override
  _SetNewPasswordViewState createState() => _SetNewPasswordViewState();
}

class _SetNewPasswordViewState extends State<SetNewPasswordView> {
  final controller = Get.find<AuthController>();
  final TextEditingController newPassController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();
  bool _isObscureNew = true;
  bool _isObscureConfirm = true;

  @override
  void initState() {
    super.initState();
    // Future.delayed(Duration(milliseconds: 500), () {
    //   SnackbarHelper.show(
    //     'Info',
    //     'Kode OTP valid. Silakan atur ulang password baru Anda.',
    //     type: 'info',
    //   );
    // });
  }

  void aturUlangPassword() async {
    final newPass = newPassController.text.trim();
    final confirmPass = confirmPassController.text.trim();
    if (newPass.isEmpty || confirmPass.isEmpty) {
      SnackbarHelper.show('Kesalahan', 'Semua kolom harus diisi',
          type: 'error');
      return;
    }
    if (newPass != confirmPass) {
      SnackbarHelper.show('Kesalahan', 'Kata sandi tidak cocok', type: 'error');
      return;
    }

    // Cukup panggil controller, biar dia yang handle snackbar & navigasi
    await controller.setNewPassword(widget.email, widget.otp, newPass);
  }

  Widget buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    required bool isObscure,
    required VoidCallback toggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isObscure,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            isObscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: toggle,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Atur Ulang Kata Sandi",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              buildPasswordField(
                controller: newPassController,
                hintText: 'Masukkan Kata Sandi Baru',
                isObscure: _isObscureNew,
                toggle: () {
                  setState(() {
                    _isObscureNew = !_isObscureNew;
                  });
                },
              ),
              SizedBox(height: 16),
              buildPasswordField(
                controller: confirmPassController,
                hintText: 'Konfirmasi Kata Sandi Baru',
                isObscure: _isObscureConfirm,
                toggle: () {
                  setState(() {
                    _isObscureConfirm = !_isObscureConfirm;
                  });
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: aturUlangPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Simpan Kata Sandi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
