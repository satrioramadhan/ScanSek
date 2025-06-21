import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'app/utils/notification_service.dart';
import 'package:scan_sek/app/utils/alarm_callbacks.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/themes/app_theme.dart';

// 🔒 Paksa Dart tetap sertakan fungsi ini saat tree-shaking
final _keepAlive = [fireIntervalReminder, fireCustomReminder];

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await AndroidAlarmManager.initialize();
  await NotificationService.init();
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  final sudahOnboarding = prefs.getBool('sudahOnboarding') ?? false;
  final sudahLogin = prefs.getBool('sudahLogin') ?? false;

  final auth = Get.put(AuthController());
  await auth.autoLogin();

  String initialRoute;
  if (!sudahOnboarding) {
    initialRoute = Routes.ONBOARDING;
  } else if (!sudahLogin) {
    initialRoute = Routes.LOGIN;
  } else {
    initialRoute = Routes.HOME;
  }

  runApp(
    GetMaterialApp(
      title: "ScanSek",
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
    ),
  );
}
