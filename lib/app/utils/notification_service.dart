import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    print('🔧 Inisialisasi NotificationService...');

    // Inisialisasi timezone (penting)
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

    await _requestPermissions();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      print('✅ Plugin notifikasi diinisialisasi');
    } catch (e) {
      print('❌ Error init plugin: $e');
    }

    await _createNotificationChannels();
  }

  static Future<void> _requestPermissions() async {
    final status = await Permission.notification.request();
    print('📢 Permission notifikasi: $status');

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      print('📢 Android notification permission granted: $granted');
    }
  }

  static Future<void> _createNotificationChannels() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const waterChannel = AndroidNotificationChannel(
        'water_reminder_channel',
        'Pengingat Minum Air',
        description: 'Channel untuk alarm minum air secara berkala',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFF2196F3),
      );

      const customChannel = AndroidNotificationChannel(
        'custom_reminder_channel',
        'Reminder Khusus',
        description: 'Channel untuk reminder jam tertentu',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        enableLights: true,
        ledColor: Color(0xFFFF9800),
      );

      try {
        await androidPlugin.createNotificationChannel(waterChannel);
        await androidPlugin.createNotificationChannel(customChannel);
        print('✅ Notification channels dibuat');
      } catch (e) {
        print('❌ Error buat channel: $e');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print(
        '👆 Notifikasi diklik: ID ${response.id}, Payload: ${response.payload}');
    // Tambahkan navigasi jika dibutuhkan
  }

  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'water_reminder_channel',
      'Pengingat Minum Air',
      channelDescription: 'Channel untuk alarm minum air',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    try {
      await _notifications.show(0, title, body, platformDetails);
      print('📨 Notifikasi tampil: $title');
    } catch (e) {
      print('❌ Error show notification: $e');
    }
  }

  static Future<void> scheduleIntervalReminder(int intervalMinutes) async {
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 1; i <= 24; i++) {
      final sched = now.add(Duration(minutes: intervalMinutes * i));

      await _notifications.zonedSchedule(
        1000 + i,
        'Saatnya minum air 💧',
        'Minum air biar tubuh sehat!',
        sched,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_reminder_channel',
            'Water Reminder',
            channelDescription: 'Pengingat untuk minum air',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      print("✅ Scheduled reminder #$i at $sched");
    }
  }

  static Future<void> debugPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      print('📋 Total pending: ${pending.length}');
      for (final notif in pending) {
        print('   - ID: ${notif.id}, Title: ${notif.title}');
      }
    } catch (e) {
      print('❌ Error debug notif: $e');
    }
  }

  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  static Future<void> openNotificationSettings() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
  }
}
