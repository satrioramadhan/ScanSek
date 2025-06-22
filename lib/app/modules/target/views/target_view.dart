import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:numberpicker/numberpicker.dart';
import '../../../themes/app_colors.dart';
import '../controllers/target_controller.dart';
import '../../home/controllers/home_controller.dart';
import '../../../utils/notification_service.dart';
import 'package:scan_sek/app/data/models/custom_reminder_model.dart';

class TargetView extends GetView<TargetController> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          final homeCtrl = Get.find<HomeController>();
          homeCtrl.ambilTarget();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text("Atur Target Harian"),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          actions: [
            IconButton(
              onPressed: controller.testNotification,
              icon: Icon(Icons.notifications_active),
              tooltip: 'Test Notifikasi',
            ),
            IconButton(
              onPressed: _showDebugInfo,
              icon: Icon(Icons.bug_report),
              tooltip: 'Debug Info',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Notifikasi
              _buildNotificationStatusCard(),
              SizedBox(height: 20),

              // Target Gula
              Text("🎯 Target Gula Harian (gram)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Obx(() {
                final value = controller.targetGula.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      min: 0,
                      max: 100,
                      divisions: 20,
                      activeColor: AppColors.primary,
                      value: value.toDouble(),
                      label: "$value gram",
                      onChanged: (val) => controller.setTargetGula(val.toInt()),
                    ),
                    Text("Target saat ini: $value gram",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                );
              }),
              SizedBox(height: 20),

              Text("💧 Target Air Minum (gelas)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Obx(() {
                final value = controller.targetAir.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Slider(
                      min: 0,
                      max: 15,
                      divisions: 15,
                      activeColor: AppColors.primary,
                      value: value.toDouble(),
                      label: "$value gelas",
                      onChanged: (val) => controller.setTargetAir(val.toInt()),
                    ),
                    Text("Target saat ini: $value gelas",
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                );
              }),
              SizedBox(height: 30),

              // Notifikasi Toggle
              Text("🔔 Notifikasi",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Obx(() => SwitchListTile(
                    activeColor: AppColors.primary,
                    title: Text("Ingatkan minum air secara berkala"),
                    subtitle: Text(controller.notifAir.value
                        ? "Notifikasi aktif"
                        : "Notifikasi tidak aktif"),
                    value: controller.notifAir.value,
                    onChanged: controller.toggleNotifAir,
                  )),
              SizedBox(height: 10),

              // Picker Interval Reminder
              Text("⏱️ Interval Pengingat Minum Air",
                  style: TextStyle(fontSize: 16)),
              Obx(() {
                final menit = controller.intervalReminderHour.value;
                final jam = menit ~/ 60;
                final sisaMenit = menit % 60;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showIntervalPicker(context, controller),
                          icon: Icon(Icons.timer),
                          label: Text("Atur Interval"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: controller.testNotification,
                          icon: Icon(Icons.bug_report),
                          label: Text("Test"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    controller.intervalPernahDiatur.value
                        ? Text(
                            jam > 0
                                ? "Interval diatur setiap $jam jam${sisaMenit > 0 ? ' $sisaMenit menit' : ''}"
                                : "Interval diatur setiap $sisaMenit menit",
                            style: TextStyle(color: AppColors.textSecondary),
                          )
                        : Text(
                            "Interval belum diatur",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                  ],
                );
              }),
              SizedBox(height: 30),

              // Reminder Khusus
              Text("⏰ Reminder Khusus",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => controller.pickReminderTime(),
                icon: Icon(Icons.add_alarm),
                label: Text("Tambah Reminder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              SizedBox(height: 10),
              Obx(() => Column(
                    children: controller.reminderList.map((reminder) {
                      return Card(
                        child: ListTile(
                          leading: Icon(Icons.alarm, color: AppColors.primary),
                          title: Text(reminder.title),
                          subtitle: Text(
                            "${controller.formatTimeOfDay(reminder.time)} • ${reminder.body}",
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          onTap: () =>
                              controller.pickReminderTime(existing: reminder),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                controller.removeReminder(reminder),
                          ),
                        ),
                      );
                    }).toList(),
                  )),

              SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: controller.applyAllReminders,
                icon: Icon(Icons.sync),
                label: Text("Terapkan Semua Perubahan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.applyAllReminders,
                      icon: Icon(Icons.refresh),
                      label: Text("Refresh Reminder"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await controller.cancelAllReminders();
                        Get.snackbar(
                          "Reminder Dihapus",
                          "Semua pengingat berhasil dibatalkan",
                          backgroundColor: Colors.redAccent,
                          colorText: Colors.white,
                        );
                      },
                      icon: Icon(Icons.delete_forever),
                      label: Text("Hapus Semua"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationStatusCard() {
    return FutureBuilder<bool>(
      future: NotificationService.areNotificationsEnabled(),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return Card(
          color: isEnabled ? Colors.green.shade50 : Colors.red.shade50,
          child: ListTile(
            leading: Icon(
              isEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: isEnabled ? Colors.green : Colors.red,
            ),
            title: Text(
              isEnabled ? "Notifikasi Aktif" : "Notifikasi Tidak Aktif",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isEnabled ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
            subtitle: Text(
              isEnabled
                  ? "Aplikasi dapat mengirim notifikasi"
                  : "Mohon aktifkan notifikasi di pengaturan",
            ),
            trailing: isEnabled
                ? null
                : TextButton(
                    onPressed: NotificationService.openNotificationSettings,
                    child: Text("Pengaturan"),
                  ),
          ),
        );
      },
    );
  }

  void _showIntervalPicker(
      BuildContext context, TargetController controller) async {
    int selectedMinutes = controller.intervalReminderHour.value.clamp(5, 720);
    int selectedHours = selectedMinutes ~/ 60;
    int selectedRemainingMinutes = selectedMinutes % 60;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Pilih Interval Pengingat'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total: ${selectedMinutes < 60 ? selectedMinutes.toString() + " menit" : "${selectedHours}h ${selectedRemainingMinutes}m"}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Jam"),
                          NumberPicker(
                            minValue: 0,
                            maxValue: 12,
                            value: selectedHours,
                            onChanged: (val) {
                              setState(() {
                                selectedHours = val;
                                selectedMinutes = (selectedHours * 60) +
                                    selectedRemainingMinutes;
                                // Pastikan minimum 5 menit
                                if (selectedMinutes < 5) {
                                  selectedMinutes = 5;
                                  selectedRemainingMinutes = 5;
                                  selectedHours = 0;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Menit"),
                          NumberPicker(
                            minValue: 0,
                            maxValue: 55,
                            step: 5,
                            value: selectedRemainingMinutes,
                            onChanged: (val) {
                              setState(() {
                                selectedRemainingMinutes = val;
                                selectedMinutes = (selectedHours * 60) +
                                    selectedRemainingMinutes;
                                // Pastikan minimum 5 menit
                                if (selectedMinutes < 5) {
                                  selectedMinutes = 5;
                                  selectedRemainingMinutes = 5;
                                  selectedHours = 0;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Get.back(), child: Text("Batal")),
                ElevatedButton(
                  onPressed: () {
                    controller.setIntervalReminderHour(selectedMinutes);
                    Get.back();
                    Get.snackbar(
                      'Interval Diperbarui',
                      'Pengingat akan muncul setiap ${selectedMinutes < 60 ? "$selectedMinutes menit" : "${selectedHours}h ${selectedRemainingMinutes}m"}',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  },
                  child: Text("OK"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDebugInfo() async {
    // Debug pending notifications
    await controller.debugPendingNotifications();
    await NotificationService.debugPendingNotifications();

    // Show info dialog
    Get.dialog(
      AlertDialog(
        title: Text('Debug Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notif Air: ${controller.notifAir.value}'),
            Text('Interval Diatur: ${controller.intervalPernahDiatur.value}'),
            Text('Interval: ${controller.intervalReminderHour.value} menit'),
            Text('Custom Reminders: ${controller.reminderList.length}'),
            SizedBox(height: 10),
            Text('Cek console log untuk detail pending notifications'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
