import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    print('🔧 Inisialisasi NotificationService...');

    // Request permission untuk notifikasi
    await _requestPermissions();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    try {
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('📱 Plugin notifikasi berhasil diinisialisasi');
    } catch (e) {
      print('❌ Error inisialisasi plugin: $e');
    }

    // Buat notification channels
    await _createNotificationChannels();

    print('✅ NotificationService siap digunakan');
  }

  static Future<void> _requestPermissions() async {
    print('🔐 Meminta permission notifikasi...');

    // Request notification permission
    PermissionStatus status = await Permission.notification.request();
    print('📢 Permission notifikasi: $status');

    // Request exact alarm permission (Android 12+)
    if (await Permission.scheduleExactAlarm.isDenied) {
      PermissionStatus alarmStatus =
          await Permission.scheduleExactAlarm.request();
      print('⏰ Permission exact alarm: $alarmStatus');
    }

    // Request ignore battery optimization
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      PermissionStatus batteryStatus =
          await Permission.ignoreBatteryOptimizations.request();
      print('🔋 Permission battery optimization: $batteryStatus');
    }
  }

  static Future<void> _createNotificationChannels() async {
    print('📋 Membuat notification channels...');

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Channel untuk water reminder
      const AndroidNotificationChannel waterChannel =
          AndroidNotificationChannel(
        'water_reminder_channel',
        'Pengingat Minum Air',
        description: 'Channel untuk alarm minum air secara berkala',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      // Channel untuk custom reminder
      const AndroidNotificationChannel customChannel =
          AndroidNotificationChannel(
        'custom_reminder_channel',
        'Reminder Khusus',
        description: 'Channel untuk reminder jam tertentu',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );

      try {
        await androidPlugin.createNotificationChannel(waterChannel);
        await androidPlugin.createNotificationChannel(customChannel);
        print('✅ Notification channels berhasil dibuat');
      } catch (e) {
        print('❌ Error membuat channels: $e');
      }
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    print('👆 Notifikasi diklik: ${response.id}');
    // Bisa tambahkan navigasi atau aksi lain di sini
  }

  static Future<void> showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'water_reminder_channel',
      'Pengingat Minum Air',
      channelDescription: 'Channel untuk alarm minum air',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    try {
      await _notifications.show(0, title, body, platformDetails);
      print('📨 Notifikasi berhasil ditampilkan: $title');
    } catch (e) {
      print('❌ Error menampilkan notifikasi: $e');
    }
  }

  // Method untuk mengecek permission
  static Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    }
    return false;
  }

  // Method untuk membuka settings notifikasi
  static Future<void> openNotificationSettings() async {
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }
}
