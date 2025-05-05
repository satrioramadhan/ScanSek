import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Profil"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// HEADER PROFILE
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundImage: NetworkImage(
                      'https://source.unsplash.com/100x100/?person,profile',
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Simon Barnwell",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "simon@email.com",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            /// MENU OPTIONS
            _menuItem(Icons.edit, "Ubah Data Akun", () {
              Get.snackbar("Info", "Fitur belum tersedia");
            }),
            _menuItem(Icons.notifications, "Pengaturan Notifikasi", () {
              Get.snackbar("Info", "Fitur belum tersedia");
            }),
            _menuItem(Icons.privacy_tip, "Kebijakan Privasi", () {
              Get.snackbar("Info", "Ini cuma dummy ya bro 😄");
            }),
            _menuItem(Icons.info_outline, "Tentang Aplikasi", () {
              Get.defaultDialog(
                title: "Tentang ScanSek",
                middleText:
                    "Versi 1.0.0\n\nScanSek membantu kamu memantau konsumsi gula harian dengan OCR label makanan.",
                confirm: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: Text("Tutup"),
                ),
              );
            }),
            _menuItem(Icons.logout, "Keluar Akun", () async {
              await controller.logout();
            }),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
