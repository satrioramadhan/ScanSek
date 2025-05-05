import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import 'package:scan_sek/app/modules/auth/controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  final controller = Get.find<AuthController>();
  final RxString email = ''.obs;
  final RxString password = ''.obs;
  final RxBool isPasswordHidden = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF6F7FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 15,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Image.asset('assets/images/logo.png',
                                      height: 70),
                                  SizedBox(height: 20),
                                  Text(
                                    "Halo Lagi!",
                                    style: TextStyle(
                                        fontSize: 26,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Selamat datang kembali!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 30),
                            TextField(
                              onChanged: (val) => email.value = val,
                              decoration: InputDecoration(
                                hintText: 'Masukkan email',
                                filled: true,
                                fillColor: Color(0xFFF1F1F1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            Obx(() => TextField(
                                  obscureText: isPasswordHidden.value,
                                  onChanged: (val) => password.value = val,
                                  decoration: InputDecoration(
                                    hintText: 'Kata Sandi',
                                    filled: true,
                                    fillColor: Color(0xFFF1F1F1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        isPasswordHidden.value
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        isPasswordHidden.value =
                                            !isPasswordHidden.value;
                                      },
                                    ),
                                  ),
                                )),
                            SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: Text(
                                  "Lupa Kata Sandi?",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (email.value.isEmpty ||
                                      password.value.isEmpty) {
                                    Get.snackbar('Error',
                                        'Email dan password wajib diisi');
                                    return;
                                  }

                                  controller.login(email.value, password.value);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.fabColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: Text("Masuk",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16)),
                              ),
                            ),
                            SizedBox(height: 20),
                            Center(
                                child: Text("Atau lanjutkan dengan",
                                    style: TextStyle(color: Colors.grey))),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                socialIcon('assets/icons/google.png'),
                              ],
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text("Belum punya akun? ",
                                      style:
                                          TextStyle(color: Colors.grey[700])),
                                  MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: GestureDetector(
                                      onTap: () => Get.toNamed('/register'),
                                      child: Text("Daftar Sekarang",
                                          style: TextStyle(
                                              color: Color(0xFF6C63FF))),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget socialIcon(String assetPath) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Image.asset(
        assetPath,
        height: 20,
        width: 20,
        fit: BoxFit.contain,
      ),
    );
  }
}
