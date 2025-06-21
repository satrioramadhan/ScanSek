import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:scan_sek/app/utils/alarm_callbacks.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

class TargetController extends GetxController {
  // 🎯 State
  RxInt targetGula = 50.obs;
  RxInt targetAir = 8.obs;
  RxBool notifAir = false.obs;
  RxList<TimeOfDay> reminderList = <TimeOfDay>[].obs;
  RxInt intervalReminderHour = 2.obs;
  RxBool intervalPernahDiatur = false.obs;

  final _plugin = FlutterLocalNotificationsPlugin();

  @override
  void onInit() {
    super.onInit();
    _initializeTimezone();
    _loadTargetDariPrefs();
    _loadReminderDariPrefs();
  }

  // 🕐 Initialize timezone
  void _initializeTimezone() {
    tz.initializeTimeZones();
    // Set timezone ke Jakarta (WIB)
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
  }

  // 🎯 Setters & Update ke SharedPreferences
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

  void setIntervalReminderHour(int value) async {
    intervalReminderHour.value = value.clamp(5, 720);
    intervalPernahDiatur.value = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval_reminder_hour', intervalReminderHour.value);
    await prefs.setBool('interval_pernah_diatur', true);

    // Restart reminder jika notifikasi aktif
    if (notifAir.value) {
      await _setupIntervalReminder();
    }
  }

  void toggleNotifAir(bool value) async {
    notifAir.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_air', value);

    if (value) {
      await _setupIntervalReminder();
    } else {
      await _cancelIntervalReminder();
    }
  }

  // 🔔 Setup Interval Reminder menggunakan AndroidAlarmManager
  Future<void> _setupIntervalReminder() async {
    await _cancelIntervalReminder();
    if (!notifAir.value) return;

    print(
        '🔔 Setting up interval reminder: ${intervalReminderHour.value} minutes');

    try {
      // Gunakan AndroidAlarmManager untuk periodic alarm
      final success = await AndroidAlarmManager.periodic(
        Duration(minutes: intervalReminderHour.value),
        999, // Alarm ID
        fireIntervalReminder,
        wakeup: true,
        exact: true,
        rescheduleOnReboot: true,
      );

      if (success) {
        print('✅ Interval reminder berhasil diatur');

        // Jadwalkan notifikasi pertama
        await _scheduleFirstNotification();
      } else {
        print('❌ Gagal mengatur interval reminder');
      }
    } catch (e) {
      print('❌ Error setting up interval reminder: $e');
    }
  }

  // Schedule notifikasi pertama
  Future<void> _scheduleFirstNotification() async {
    final now = tz.TZDateTime.now(tz.local);
    final firstNotification =
        now.add(Duration(minutes: intervalReminderHour.value));

    try {
      await _plugin.zonedSchedule(
        998, // ID berbeda untuk notifikasi pertama
        'Waktunya Minum Air 💧',
        'Ayo minum air untuk menjaga tubuh tetap segar!',
        firstNotification,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminder_channel',
            'Pengingat Minum Air',
            channelDescription: 'Channel untuk alarm minum air',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            showWhen: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      print('✅ First notification scheduled');
    } catch (e) {
      print('❌ Error scheduling first notification: $e');
    }
  }

  Future<void> _cancelIntervalReminder() async {
    try {
      await AndroidAlarmManager.cancel(999);
      await _plugin.cancel(998); // Cancel first notification
      print('✅ Interval reminder cancelled');
    } catch (e) {
      print('❌ Error cancelling interval reminder: $e');
    }
  }

  // ⏰ Reminder Khusus Manual
  void pickReminderTime() async {
    TimeOfDay? picked = await showTimePicker(
      context: Get.context!,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      reminderList.add(picked);
      reminderList.sort((a, b) => a.hour != b.hour
          ? a.hour.compareTo(b.hour)
          : a.minute.compareTo(b.minute));
      await _simpanReminderKePrefs();
      await _jadwalkanReminderKhusus();
    }
  }

  void removeReminder(TimeOfDay time) async {
    final index = reminderList.indexOf(time);
    if (index >= 0) {
      reminderList.removeAt(index);
      await _simpanReminderKePrefs();
      await _jadwalkanReminderKhusus();
    }
  }

  String formatTimeOfDay(TimeOfDay tod) {
    final dt = DateTime(0, 1, 1, tod.hour, tod.minute);
    return DateFormat.Hm().format(dt);
  }

  // 🗂️ Persistence (SharedPreferences)
  Future<void> _simpanReminderKePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = reminderList
        .map((e) =>
            "${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}")
        .toList();
    await prefs.setStringList('reminder_list', listStr);
  }

  Future<void> _loadTargetDariPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    targetGula.value = prefs.getInt('target_gula') ?? 50;
    targetAir.value = prefs.getInt('target_air') ?? 8;
    notifAir.value = prefs.getBool('notif_air') ?? false;

    // ✅ cek apakah pernah diatur manual
    if (prefs.containsKey('interval_reminder_hour')) {
      intervalReminderHour.value = prefs.getInt('interval_reminder_hour')!;
      intervalPernahDiatur.value =
          prefs.getBool('interval_pernah_diatur') ?? false;
    }

    // Auto start reminder jika sudah aktif sebelumnya
    if (notifAir.value && intervalPernahDiatur.value) {
      await _setupIntervalReminder();
    }
  }

  Future<void> _loadReminderDariPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final listStr = prefs.getStringList('reminder_list') ?? [];
    final listTime = listStr.map((str) {
      final parts = str.split(":");
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }).toList();
    reminderList.assignAll(listTime);

    // Jadwalkan reminder khusus jika ada
    if (reminderList.isNotEmpty) {
      await _jadwalkanReminderKhusus();
    }
  }

  Future<void> _jadwalkanReminderKhusus() async {
    print('📅 Menjadwalkan ${reminderList.length} reminder khusus');

    // Cancel semua notifikasi reminder khusus dulu
    for (int i = 0; i < 20; i++) {
      await _plugin.cancel(1000 + i);
      await AndroidAlarmManager.cancel(1000 + i); // Cancel alarm juga
    }

    for (int i = 0; i < reminderList.length; i++) {
      final time = reminderList[i];
      final now = tz.TZDateTime.now(tz.local);

      // Buat scheduled time untuk hari ini
      var scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // Jika waktu sudah lewat hari ini, jadwalkan untuk besok
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(Duration(days: 1));
      }

      print('⏰ Reminder ${i + 1}: ${formatTimeOfDay(time)} -> $scheduled');

      try {
        final alarmTime = scheduled.millisecondsSinceEpoch;
        final success = await AndroidAlarmManager.oneShotAt(
          DateTime.fromMillisecondsSinceEpoch(alarmTime),
          1000 + i,
          fireCustomReminder,
          wakeup: true,
          exact: true,
          rescheduleOnReboot: true,
        );

        if (success) {
          print(
              '✅ Custom reminder ${i + 1} berhasil dijadwalkan dengan AndroidAlarmManager');

          await _plugin.zonedSchedule(
            1000 + i,
            'Reminder Khusus 🕒',
            'Sudah saatnya kamu minum air sesuai jadwal.',
            scheduled,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'custom_reminder_channel',
                'Reminder Khusus',
                channelDescription: 'Channel untuk reminder jam tertentu',
                importance: Importance.max,
                priority: Priority.high,
                playSound: true,
                enableVibration: true,
                showWhen: true,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
          );
        }
      } catch (e) {
        print('❌ Error scheduling custom reminder ${i + 1}: $e');
      }
    }
  }

  Future<void> testNotification() async {
    try {
      await _plugin.show(
        9999,
        'Test Notifikasi 🧪',
        'Jika kamu melihat ini, notifikasi bekerja dengan baik!',
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
      );

      Get.snackbar(
        'Test Berhasil',
        'Notifikasi test telah dikirim!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Test Gagal',
        'Error: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> applyAllReminders() async {
    try {
      if (notifAir.value && intervalPernahDiatur.value) {
        await _setupIntervalReminder();
      }

      if (reminderList.isNotEmpty) {
        await _jadwalkanReminderKhusus();
      }

      Get.snackbar(
        'Pengaturan Diterapkan',
        'Semua reminder telah diperbarui!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Gagal menerapkan pengaturan: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
