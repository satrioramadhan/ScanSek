import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'app/utils/background_service.dart';
import 'app/utils/notification_service.dart';
import 'app/modules/auth/controllers/auth_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/themes/app_theme.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ⏰ Timezone setup
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  print('🚀 Starting app initialization...');

  try {
    await Firebase.initializeApp();
    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  try {
    await NotificationService.init();
    print('✅ NotificationService initialized');
  } catch (e) {
    print('❌ NotificationService initialization error: $e');
  }

  try {
    await initializeDateFormatting('id_ID', null);
    print('✅ Date formatting initialized');
  } catch (e) {
    print('❌ Date formatting initialization error: $e');
  }

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

  print('🎯 Initial route: $initialRoute');

  try {
    await initializeBackgroundService();
    print('✅ BackgroundService initialized');
  } catch (e) {
    print('❌ BackgroundService init error: $e');
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
