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
}
