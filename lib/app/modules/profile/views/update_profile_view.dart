import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../themes/app_colors.dart';
import '../controllers/profile_controller.dart';

class UpdateProfileView extends GetView<ProfileController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text("Update Profil",
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Obx(() => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔥 Security reminder hanya muncul kalo user belum punya password
                  if (controller.reminder.value.isNotEmpty)
                    _buildSecurityReminderCard(),
                  if (controller.reminder.value.isNotEmpty)
                    const SizedBox(height: 24),

                  // Profile info section
                  _buildProfileInfoSection(),
                  const SizedBox(height: 24),

                  // Password section
                  _buildPasswordSection(),
                  const SizedBox(height: 32),

                  // Action button
                  _buildActionButton(),
                  const SizedBox(height: 16),

                  // Forgot password button (hanya untuk user yang udah punya password)
                  if (controller.hasExistingPassword.value)
                    _buildForgotPasswordButton(),
                ],
              )),
        ),
      ),
    );
  }

  Widget _buildSecurityReminderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.shade50,
            Colors.orange.shade100.withOpacity(0.8)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.shade100.withOpacity(0.5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.security, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Keamanan Akun",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                        fontSize: 16)),
                const SizedBox(height: 4),
                Text(controller.reminder.value,
                    style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 14,
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return _buildCard(
      title: "Informasi Profil",
      child: Column(
        children: [
          _buildTextField(
            label: "Username",
            initialValue: controller.newUsername.value,
            onChanged: (val) => controller.newUsername.value = val,
            prefixIcon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            label: "Email",
            initialValue: controller.newEmail.value,
            onChanged: (val) => controller.newEmail.value = val,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            enabled: false, // 🔥 Lock the email field
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return _buildCard(
      title: "Keamanan Password",
      subtitle: controller.hasExistingPassword.value
          ? "Ubah password untuk keamanan yang lebih baik"
          : "Buat password untuk login manual tanpa Google",
      child: Column(
        children: [
          // 🔥 Main password field - label berubah berdasarkan kondisi
          _buildPasswordField(
            label: controller.passwordFieldLabel,
            value: controller.newPassword.value,
            obscureText: controller.obscureNewPassword.value,
            onChanged: controller.onPasswordChanged,
            onToggleVisibility: () => controller.obscureNewPassword.toggle(),
            prefixIcon: controller.hasExistingPassword.value
                ? Icons.lock_outline
                : Icons.lock_open_outlined,
          ),

          // 🔥 Animated additional fields
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: controller.showPasswordFields.value
                ? Column(
                    children: [
                      const SizedBox(height: 20),

                      // Confirm password field (selalu muncul kalo user ngetik password)
                      _buildPasswordField(
                        label: "Konfirmasi Password",
                        value: controller.confirmPassword.value,
                        obscureText: controller.obscureConfirmPassword.value,
                        onChanged: (val) =>
                            controller.confirmPassword.value = val,
                        onToggleVisibility: () =>
                            controller.obscureConfirmPassword.toggle(),
                        prefixIcon: Icons.lock_outline,
                      ),

                      // Current password field (hanya untuk user yang udah punya password)
                      if (controller.shouldShowCurrentPasswordField)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildPasswordField(
                              label: "Password Saat Ini",
                              value: controller.currentPassword.value,
                              obscureText:
                                  controller.obscureCurrentPassword.value,
                              onChanged: (val) =>
                                  controller.currentPassword.value = val,
                              onToggleVisibility: () =>
                                  controller.obscureCurrentPassword.toggle(),
                              prefixIcon: Icons.key_outlined,
                            ),
                          ],
                        ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade600, height: 1.3)),
          ],
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    required Function(String) onChanged,
    required IconData prefixIcon,
    TextInputType keyboardType = TextInputType.text,
    bool enabled = true, // 🔥 Add enabled parameter
  }) {
    return TextField(
      controller: TextEditingController(text: initialValue)
        ..selection = TextSelection.fromPosition(
            TextPosition(offset: initialValue.length)),
      onChanged: onChanged,
      keyboardType: keyboardType,
      enabled: enabled, // 🔥 Use enabled parameter
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon,
            color: enabled
                ? AppColors.primary
                : Colors.grey), // 🔥 Gray out icon when disabled
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        disabledBorder: OutlineInputBorder(
          // 🔥 Add disabled border style
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: enabled
            ? Colors.grey.shade50
            : Colors.grey.shade100, // 🔥 Different fill color when disabled
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required String value,
    required bool obscureText,
    required Function(String) onChanged,
    required VoidCallback onToggleVisibility,
    required IconData prefixIcon,
  }) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection =
            TextSelection.fromPosition(TextPosition(offset: value.length)),
      onChanged: onChanged,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: AppColors.primary),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: AppColors.primary,
          ),
          onPressed: onToggleVisibility,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: controller.saveProfile, // 🔥 Unified method
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: (controller.isSavingChanges.value ||
                controller.isCreatingPassword.value)
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(controller.buttonIcon, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    controller.buttonLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildForgotPasswordButton() {
    return Center(
      child: TextButton.icon(
        onPressed: controller.logoutAndGoToForgotPassword,
        icon: const Icon(Icons.help_outline, size: 18),
        label: const Text("Lupa Password?",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade600,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
