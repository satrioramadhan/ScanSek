import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../themes/app_colors.dart';
import '../controllers/target_controller.dart';

class TargetView extends GetView<TargetController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Atur Target Harian"),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SLIDER GULA
            Text("🎯 Target Gula Harian (gram)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Obx(() => Slider(
                  min: 0,
                  max: 100,
                  divisions: 20,
                  activeColor: AppColors.primary,
                  value: controller.targetGula.value.toDouble(),
                  label: "${controller.targetGula.value} gram",
                  onChanged: (val) => controller.setTargetGula(val.toInt()),
                )),
            Obx(() => Text(
                  "Target saat ini: ${controller.targetGula.value} gram",
                  style: TextStyle(color: AppColors.textSecondary),
                )),
            SizedBox(height: 20),

            /// SLIDER AIR
            Text("💧 Target Air Minum (gelas)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Obx(() => Slider(
                  min: 0,
                  max: 15,
                  divisions: 15,
                  activeColor: AppColors.primary,
                  value: controller.targetAir.value.toDouble(),
                  label: "${controller.targetAir.value} gelas",
                  onChanged: (val) => controller.setTargetAir(val.toInt()),
                )),
            Obx(() => Text(
                  "Target saat ini: ${controller.targetAir.value} gelas",
                  style: TextStyle(color: AppColors.textSecondary),
                )),
            SizedBox(height: 30),

            /// PROGRESS BAR (Dummy)
            Text("📊 Progress Hari Ini",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            _buildProgressBar("Gula", 32, controller.targetGula.value),
            SizedBox(height: 10),
            _buildProgressBar("Air", 5, controller.targetAir.value),
            SizedBox(height: 30),

            /// TOGGLE NOTIFIKASI
            Text("🔔 Notifikasi",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Obx(() => SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text("Peringatkan jika gula mendekati batas"),
                  value: controller.notifGula.value,
                  onChanged: controller.toggleNotifGula,
                )),
            Obx(() => SwitchListTile(
                  activeColor: AppColors.primary,
                  title: Text("Ingatkan minum air tiap 2 jam"),
                  value: controller.notifAir.value,
                  onChanged: controller.toggleNotifAir,
                )),
            SizedBox(height: 30),

            /// REMINDER KHUSUS
            Text("⏰ Reminder Khusus",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: controller.pickReminderTime,
              icon: Icon(Icons.add_alarm),
              label: Text("Tambah Reminder"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Obx(() => Column(
                  children: controller.reminderList.map((time) {
                    return ListTile(
                      leading: Icon(Icons.alarm, color: AppColors.primary),
                      title: Text(controller.formatTimeOfDay(time)),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => controller.removeReminder(time),
                      ),
                    );
                  }).toList(),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(String label, int current, int target) {
    double progress = (target == 0) ? 0 : current / target;
    if (progress > 1) progress = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("$label: $current / $target",
            style: TextStyle(color: AppColors.textSecondary)),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}
