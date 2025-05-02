import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  var totalGulaHariIni = 38.obs;
  var totalGelasAir = 25.obs;
  var makananTerakhir = "Teh Botol Sosro".obs;
  var gulaMakananTerakhir = 19.obs;

  // 1. Ukuran animasi Lottie (tinggi & lebar)
  final Map<String, double> lottieSizeMap = {
    'assets/lottie/health.json': 60,
    'assets/lottie/warning.json': 64,
    'assets/lottie/stop.json': 60,
  };

  // 2. Alignment tiap animasi (posisi tengah)
  final Map<String, Alignment> lottieAlignmentMap = {
    'assets/lottie/health.json': Alignment.center,
    'assets/lottie/warning.json': Alignment.center,
    'assets/lottie/stop.json': Alignment.center,
  };

  // Getter biar clean di view
  double getLottieSize(String asset) => lottieSizeMap[asset] ?? 60;
  Alignment getLottieAlignment(String asset) =>
      lottieAlignmentMap[asset] ?? Alignment.center;

  late AnimationController lottieController;

  @override
  void onInit() {
    super.onInit();
    lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    lottieController.repeat();
  }

  @override
  void onClose() {
    lottieController.dispose();
    super.onClose();
  }

  double konversiKeSendokTeh() => (totalGulaHariIni.value / 4).toPrecision(2);

  void tambahAir() {
    totalGelasAir.value++;
  }

  void updateLottieSpeed() {
    if (totalGulaHariIni.value < 25) {
      lottieController.duration = const Duration(seconds: 2);
    } else if (totalGulaHariIni.value < 50) {
      lottieController.duration = const Duration(seconds: 200);
    } else {
      lottieController.duration = const Duration(milliseconds: 700);
    }
    lottieController.repeat();
  }

  // Untuk mendapatkan asset berdasarkan gula
  String get lottieAsset {
    final total = totalGulaHariIni.value;
    if (total < 25) return 'assets/lottie/health.json';
    if (total < 50) return 'assets/lottie/warning.json';
    return 'assets/lottie/stop.json';
  }
}
