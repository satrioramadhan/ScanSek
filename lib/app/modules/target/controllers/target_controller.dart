import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:scan_sek/app/data/models/custom_reminder_model.dart';
import 'package:timezone/timezone.dart' as tz;

class TargetController extends GetxController {
  RxInt targetGula = 50.obs;
  RxInt targetAir = 8.obs;
  RxBool notifAir = false.obs;
  RxList<CustomReminder> reminderList = <CustomReminder>[].obs;
  RxInt intervalReminderHour = 2.obs;
  RxBool intervalPernahDiatur = false.obs;

  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _loadTargetDariPrefs();
    _loadReminderDariPrefs();
  }

  void setTargetGula(int value) async {
    targetGula.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_gula', value);
  }

  void setTargetAir(int value) async {
    targetAir.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('target_air', value);
  }

  void setIntervalReminderHour(int valueInMinutes) async {
    intervalReminderHour.value = valueInMinutes.clamp(5, 720);
    intervalPernahDiatur.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval_reminder_hour', intervalReminderHour.value);
    await prefs.setBool('interval_pernah_diatur', true);

    print('🔧 Setting interval: ${intervalReminderHour.value} minutes');

    if (notifAir.value) {
      await _setupIntervalReminder();
    }
  }

  Future<void> cancelAllReminders() async {
    await _cancelIntervalReminder();
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(1000 + i);
    }
  }

  void toggleNotifAir(bool value) async {
    notifAir.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_air', value);

    print('🔔 Toggle notif air: $value');

    if (value) {
      await _setupIntervalReminder();
    } else {
      await _cancelIntervalReminder();
    }
  }

  Future<void> _setupIntervalReminder() async {
    print('⏰ Setting up interval reminders...');
    await _cancelIntervalReminder();

    if (!notifAir.value || !intervalPernahDiatur.value) return;

    final intervalMinutes = intervalReminderHour.value;
    await scheduleIntervalNotification(
      interval: Duration(minutes: intervalMinutes),
      repeatCount: 24, // atau bisa disesuaikan jumlahnya
    );
  }

  Future<void> _cancelIntervalReminder() async {
    print('🗑️ Canceling interval reminders...');
    try {
      // Cancel interval notifications (ID 900-924)
      for (int i = 1; i <= 24; i++) {
        await _plugin.cancel(900 + i);
      }
      print('✅ Interval reminders canceled');
    } catch (e) {
      print('❌ Error canceling interval reminders: $e');
    }
  }

  Future<void> scheduleIntervalNotification({
    required Duration interval,
    int repeatCount = 24,
    int startId = 900,
  }) async {
    print(
        '📆 Menjadwalkan ${repeatCount}x notifikasi tiap ${interval.inMinutes} menit');

    final now = tz.TZDateTime.now(tz.local);
    for (int i = 0; i < repeatCount; i++) {
      final scheduledTime = now.add(interval * (i + 1));
      try {
        await _plugin.zonedSchedule(
          startId + i,
          'Waktunya Minum Air 💧',
          'Minum air untuk jaga tubuh tetap sehat! (${i + 1}/$repeatCount)',
          scheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'water_reminder_channel',
              'Pengingat Minum Air',
              channelDescription: 'Channel untuk alarm minum air',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
        print('✅ Scheduled reminder ${i + 1} at $scheduledTime');
      } catch (e) {
        print('❌ Gagal menjadwalkan reminder ke-${i + 1}: $e');
      }
    }
  }

  void pickReminderTime({CustomReminder? existing}) async {
    final context = Get.context!;
    final isEdit = existing != null;

    TimeOfDay time = existing?.time ?? TimeOfDay.now();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEdit ? 'Edit Reminder' : 'Tambah Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(labelText: 'Judul Notifikasi'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: InputDecoration(labelText: 'Isi Notifikasi'),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: time,
                );
                if (picked != null) {
                  time = picked;
                }
              },
              icon: Icon(Icons.access_time),
              label: Text("Pilih Jam"),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text("Batal")),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty ||
                  bodyCtrl.text.trim().isEmpty) {
                Get.snackbar('Error', 'Judul dan isi tidak boleh kosong',
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }

              final reminder = CustomReminder(
                time: time,
                title: titleCtrl.text.trim(),
                body: bodyCtrl.text.trim(),
              );

              if (isEdit) {
                final index = reminderList.indexOf(existing!);
                reminderList[index] = reminder;
              } else {
                // Cegah duplikat waktu
                final already = reminderList.any((e) =>
                    e.time.hour == time.hour && e.time.minute == time.minute);
                if (already) {
                  Get.snackbar('Gagal', 'Waktu sudah ada',
                      backgroundColor: Colors.orange, colorText: Colors.white);
                  return;
                }
                reminderList.add(reminder);
              }

              // Sort dan simpan
              reminderList.sort((a, b) => a.time.hour != b.time.hour
                  ? a.time.hour.compareTo(b.time.hour)
                  : a.time.minute.compareTo(b.time.minute));

              await _simpanReminderKePrefs();
              await _jadwalkanReminderKhusus();

              Get.back();
            },
            child: Text("Simpan"),
          )
        ],
      ),
    );
  }

  void removeReminder(CustomReminder reminder) async {
    reminderList.remove(reminder);
    await _simpanReminderKePrefs();
    await _jadwalkanReminderKhusus();
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
    return DateFormat.Hm().format(dt);
  }

  Future<void> _simpanReminderKePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = reminderList.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList('reminder_list', listStr);
  }

  Future<void> _loadTargetDariPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    targetGula.value = prefs.getInt('target_gula') ?? 50;
    targetAir.value = prefs.getInt('target_air') ?? 8;
    notifAir.value = prefs.getBool('notif_air') ?? false;

    if (prefs.containsKey('interval_reminder_hour')) {
      intervalReminderHour.value = prefs.getInt('interval_reminder_hour')!;
      intervalPernahDiatur.value =
          prefs.getBool('interval_pernah_diatur') ?? false;
    }

    print('📂 Loaded preferences:');
    print('   - notifAir: ${notifAir.value}');
    print('   - intervalPernahDiatur: ${intervalPernahDiatur.value}');
    print('   - intervalReminderHour: ${intervalReminderHour.value}');

    if (notifAir.value && intervalPernahDiatur.value) {
      await _setupIntervalReminder();
    }
  }

  Future<void> _loadReminderDariPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getStringList('reminder_list') ?? [];

    print("🧠 Raw reminder data from prefs: $listStr");

    final listReminder = listStr
        .map((str) {
          try {
            final map = jsonDecode(str);
            print('✅ Parsed reminder: $map');
            return CustomReminder.fromMap(map);
          } catch (e) {
            print('❌ Gagal decode reminder: $e\nData: $str');
            return null;
          }
        })
        .whereType<CustomReminder>()
        .toList();

    reminderList.assignAll(listReminder);

    print('📂 Loaded ${reminderList.length} custom reminders dari prefs');

    if (reminderList.isNotEmpty) {
      await _jadwalkanReminderKhusus();
    }
  }

  Future<void> _jadwalkanReminderKhusus() async {
    print('⏰ Scheduling custom reminders...');

    // Cancel existing custom reminders (ID 1000-1019)
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(1000 + i);
    }

    try {
      for (int i = 0; i < reminderList.length; i++) {
        final reminder = reminderList[i];
        final time = reminder.time;

        final now = tz.TZDateTime.now(tz.local);
        var scheduled = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // Jika waktu sudah terlewat hari ini, jadwalkan untuk besok
        if (scheduled.isBefore(now)) {
          scheduled = scheduled.add(Duration(days: 1));
        }

        await _plugin.zonedSchedule(
          1000 + i,
          reminder.title,
          reminder.body,
          scheduled,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'custom_reminder_channel', // ✅ Fixed channel ID
              'Reminder Khusus',
              channelDescription: 'Channel untuk reminder jam tertentu',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
              enableVibration: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );

        print(
            '📋 Scheduled custom reminder ${i + 1}: ${reminder.title} at $scheduled');
      }

      print('✅ Successfully scheduled ${reminderList.length} custom reminders');
    } catch (e) {
      print('❌ Error scheduling custom reminders: $e');
    }
  }

  Future<void> testNotification() async {
    print('🧪 Testing notification...');
    try {
      await _plugin.show(
        9999,
        'Test Notifikasi 🧪',
        'Jika kamu melihat ini, notifikasi bekerja dengan baik! ${DateTime.now().toString().substring(11, 19)}',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminder_channel', // ✅ Fixed channel ID
            'Pengingat Minum Air',
            channelDescription: 'Channel untuk alarm minum air',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
          ),
        ),
      );
      print('✅ Test notification sent');
    } catch (e) {
      print('❌ Error sending test notification: $e');
    }
  }

  Future<void> applyAllReminders() async {
    print('🔄 Applying all reminders...');

    try {
      if (notifAir.value && intervalPernahDiatur.value) {
        await _setupIntervalReminder();
        print('✅ Interval reminders applied');
      }

      if (reminderList.isNotEmpty) {
        await _jadwalkanReminderKhusus();
        print('✅ Custom reminders applied');
      }

      Get.snackbar(
        'Berhasil',
        'Semua pengingat telah diterapkan!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('❌ Error applying reminders: $e');
      Get.snackbar(
        'Error',
        'Gagal menerapkan pengingat: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Method untuk debug - lihat pending notifications
  Future<void> debugPendingNotifications() async {
    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      print('📋 Pending notifications (${pendingNotifications.length}):');
      for (final notif in pendingNotifications) {
        print(
            '   - ID: ${notif.id}, Title: ${notif.title}, Body: ${notif.body}');
      }
    } catch (e) {
      print('❌ Error getting pending notifications: $e');
    }
  }
}
