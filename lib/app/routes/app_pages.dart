import 'package:get/get.dart';

import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/register_view.dart';
import '../modules/auth/views/forgot_password_view.dart'; // 🔥 Import baru
import '../modules/auth/views/verify_reset_otp_view.dart'; // 🔥 Import baru
import '../modules/auth/views/set_new_password_view.dart'; // 🔥 Import baru
import '../modules/berita/bindings/berita_binding.dart';
import '../modules/berita/views/berita_view.dart';
import '../modules/history/bindings/history_binding.dart';
import '../modules/history/views/history_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/ocr/bindings/ocr_binding.dart';
import '../modules/ocr/views/ocr_view.dart';
import '../modules/onboarding/bindings/onboarding_binding.dart';
import '../modules/onboarding/views/onboarding_view.dart';
import '../modules/profile/bindings/profile_binding.dart';
import '../modules/profile/views/profile_view.dart';
import '../modules/profile/controllers/profile_controller.dart';
import '../modules/profile/views/update_profile_view.dart';
import '../modules/statistics/bindings/statistics_binding.dart';
import '../modules/statistics/views/statistics_view.dart';
import '../modules/target/bindings/target_binding.dart';
import '../modules/target/views/target_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.ONBOARDING;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => HomeView(),
      binding: HomeBinding(),
      transition: Transition.zoom,
    ),
    GetPage(
      name: Routes.ONBOARDING,
      page: () => OnboardingView(),
      binding: OnboardingBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
        name: Routes.LOGIN,
        page: () => LoginView(),
        binding: AuthBinding(),
        transition: Transition.upToDown),
    GetPage(
        name: Routes.REGISTER,
        page: () => RegisterView(),
        binding: AuthBinding(),
        transition: Transition.downToUp),

    // 🔥 Tambahkan Reset Password Flow Pages
    GetPage(
      name: Routes.FORGOT_PASSWORD,
      page: () => ForgotPasswordView(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.VERIFY_RESET_OTP,
      page: () =>
          VerifyResetOtpView(email: ''), // email nanti dikirim saat navigasi
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.SET_NEW_PASSWORD,
      page: () => SetNewPasswordView(
          email: '', otp: ''), // email & otp dikirim saat navigasi
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: Routes.OCR,
      page: () => OcrView(),
      binding: OcrBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: _Paths.HISTORY,
      page: () => HistoryView(),
      binding: HistoryBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: _Paths.STATISTICS,
      page: () => StatisticsView(),
      binding: StatisticsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.TARGET,
      page: () => TargetView(),
      binding: TargetBinding(),
      transition: Transition.leftToRight,
    ),
    GetPage(
      name: _Paths.BERITA,
      page: () => BeritaView(),
      binding: BeritaBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: _Paths.PROFILE,
      page: () => ProfileView(),
      binding: ProfileBinding(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: Routes.UPDATE_PROFILE,
      page: () => UpdateProfileView(),
      binding: BindingsBuilder(
          () => Get.put(ProfileController())), // 🔥 pakai controller yang sama
      transition: Transition.rightToLeft,
    ),
  ];
}
