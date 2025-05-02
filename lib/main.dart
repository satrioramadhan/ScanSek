import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/routes/app_pages.dart';
import 'app/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);

  final prefs = await SharedPreferences.getInstance();
  final sudahOnboarding = prefs.getBool('sudahOnboarding') ?? false;
  final sudahLogin = prefs.getBool('sudahLogin') ?? false;

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
