import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import '../controllers/profile_controller.dart'; // 🔥 Ganti pakai ProfileController

class UpdateProfileView extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profil"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: InputDecoration(labelText: "Username"),
                  controller:
                      TextEditingController(text: controller.newUsername.value)
                        ..selection = TextSelection.fromPosition(TextPosition(
                            offset: controller.newUsername.value.length)),
                  onChanged: (val) => controller.newUsername.value = val,
                ),
                TextField(
                  decoration: InputDecoration(labelText: "Email"),
                  controller: TextEditingController(
                      text: controller.newEmail.value)
                    ..selection = TextSelection.fromPosition(
                        TextPosition(offset: controller.newEmail.value.length)),
                  onChanged: (val) => controller.newEmail.value = val,
                ),
                SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    labelText: "Password Baru",
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscureNewPassword.value
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => controller.obscureNewPassword.toggle(),
                    ),
                  ),
                  obscureText: controller.obscureNewPassword.value,
                  onChanged: controller.checkPasswordField,
                ),
                if (controller.showCurrentPasswordField.value)
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Password Saat Ini",
                      suffixIcon: IconButton(
                        icon: Icon(controller.obscureCurrentPassword.value
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () =>
                            controller.obscureCurrentPassword.toggle(),
                      ),
                    ),
                    obscureText: controller.obscureCurrentPassword.value,
                    onChanged: (val) => controller.currentPassword.value = val,
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: controller.saveChanges,
                  child: Text("Simpan Perubahan"),
                ),
                TextButton(
                  onPressed: controller.logoutAndGoToForgotPassword,
                  child: Text("Lupa Password?",
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            )),
      ),
    );
  }
}
