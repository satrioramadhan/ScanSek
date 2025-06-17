import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:scan_sek/app/modules/profile/controllers/profile_controller.dart';
import 'package:scan_sek/app/modules/profile/views/update_profile_view.dart';
import 'package:scan_sek/app/modules/profile/views/login_history_view.dart';
import 'package:scan_sek/app/themes/app_colors.dart';

class ProfileView extends StatelessWidget {
  final controller = Get.find<ProfileController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text("Profil Saya"),
        backgroundColor: AppColors.fabColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 16),
          _buildSectionCard(
            children: [
              _buildMenuItem(
                icon: Icons.person_outline,
                title: "Ubah Profil",
                onTap: () => Get.to(() => UpdateProfileView()),
              ),
              _buildMenuItem(
                icon: Icons.history,
                title: "Riwayat Login",
                onTap: () => Get.to(() => LoginHistoryView()),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            children: [
              _buildMenuItem(
                icon: Icons.logout,
                title: "Keluar",
                onTap: controller.logout,
                iconColor: Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Obx(() {
      final username = controller.username.value;
      final email = controller.email.value;

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.fabColor.withOpacity(0.9), AppColors.fabColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.fabColor.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 35,
              backgroundImage: AssetImage("assets/images/avatar.png"),
            ),
            const SizedBox(height: 12),
            Text(
              username.isEmpty ? "Pengguna" : username,
              style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              email.isEmpty ? "-" : email,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = Colors.black54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right, size: 20),
      ),
    );
  }
}
