import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> fireIntervalReminder() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Waktunya Minum Air 💧',
    'Ayo minum air untuk menjaga tubuh tetap segar!',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'water_reminder_channel',
        'Pengingat Minum Air',
        channelDescription: 'Channel untuk alarm minum air',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> fireCustomReminder() async {
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    ),
  );

  await plugin.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    'Reminder Khusus 🕒',
    'Sudah saatnya kamu minum air.',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'custom_reminder_channel',
        'Reminder Khusus',
        channelDescription: 'Reminder dari alarm manager',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
      ),
    ),
  );
}
