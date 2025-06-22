import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      isForegroundMode: false,
      autoStart: true,
      autoStartOnBoot: true,
    ),
    iosConfiguration: IosConfiguration(),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) {
  DartPluginRegistrant.ensureInitialized();

  final now = tz.TZDateTime.now(tz.local);
  final nextMidnight =
      tz.TZDateTime(tz.local, now.year, now.month, now.day + 1);
  final delay = nextMidnight.difference(now);

  print('🔁 Reminder akan di-refresh pada $nextMidnight');

  Future.delayed(delay, () async {
    await NotificationService.scheduleIntervalReminder(120);
    print("🔁 Reminder interval dijadwalkan ulang jam 00:00");
  });
}
