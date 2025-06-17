part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const HOME = _Paths.HOME;
  static const ONBOARDING = _Paths.ONBOARDING;
  static const LOGIN = _Paths.LOGIN;
  static const REGISTER = _Paths.REGISTER;
  static const OCR = _Paths.OCR;
  static const HISTORY = _Paths.HISTORY;
  static const STATISTICS = _Paths.STATISTICS;
  static const TARGET = _Paths.TARGET;
  static const BERITA = _Paths.BERITA;
  static const PROFILE = _Paths.PROFILE;
  static const UPDATE_PROFILE = _Paths.UPDATE_PROFILE;
  static const LOGIN_HISTORY = _Paths.LOGIN_HISTORY;
  static const FORGOT_PASSWORD = _Paths.FORGOT_PASSWORD;
  static const VERIFY_RESET_OTP = _Paths.VERIFY_RESET_OTP;
  static const SET_NEW_PASSWORD = _Paths.SET_NEW_PASSWORD;
}

abstract class _Paths {
  static const HOME = '/home';
  static const ONBOARDING = '/onboarding';
  static const LOGIN = '/login';
  static const REGISTER = '/register';
  static const OCR = '/ocr';
  static const HISTORY = '/history';
  static const STATISTICS = '/statistics';
  static const TARGET = '/target';
  static const BERITA = '/berita';
  static const PROFILE = '/profile';
  static const UPDATE_PROFILE = '/update-profile';
  static const LOGIN_HISTORY = '/login-history';
  static const FORGOT_PASSWORD = '/forgot-password';
  static const VERIFY_RESET_OTP = '/verify-reset-otp';
  static const SET_NEW_PASSWORD = '/set-new-password';
}
