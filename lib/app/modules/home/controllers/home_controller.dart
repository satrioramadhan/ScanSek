import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart';

class HomeController extends GetxController with GetTickerProviderStateMixin {
  var totalGulaHariIni = 38.obs;
  var totalGelasAir = 25.obs;
  var makananTerakhir = "Teh Botol Sosro".obs;
  var gulaMakananTerakhir = 19.obs;
  var daftarNotifikasi = <String>[].obs;

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

    ambilDataHariIni(); // ✅ ambil dari API
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

  Future<void> ambilDataHariIni() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Gula
      final resGula = await GulaService.ambilGula(tanggal: today);
      if (resGula.statusCode == 200 && resGula.data['success'] == true) {
        final List<dynamic> data = resGula.data['data'];
        int totalGula = 0;
        for (var item in data) {
          totalGula += (item['totalGula'] as num).toInt();
        }
        totalGulaHariIni.value = totalGula;

        // Makanan terakhir (ambil item terakhir)
        if (data.isNotEmpty) {
          final lastItem = data.last;
          makananTerakhir.value =
              lastItem['namaMakanan'] ?? "(tidak diketahui)";
          gulaMakananTerakhir.value = (lastItem['totalGula'] as num).toInt();
        }
      }

      // Air
      final resAir = await AirService.ambilAir(today);
      if (resAir.statusCode == 200 && resAir.data['success'] == true) {
        final List<dynamic> jamList =
            resAir.data['data']['riwayatJamMinum'] ?? [];
        totalGelasAir.value = jamList.length;
      }

      updateLottieSpeed(); // Refresh animasi
    } catch (e) {
      print("Gagal ambil data home: $e");
    }
    cekNotifikasi();
  }

  void cekNotifikasi() {
    if (totalGulaHariIni.value > 50) {
      daftarNotifikasi.add("⚠️ Gula harian melewati batas aman (> 50 gram)");
    } else if (totalGulaHariIni.value > 25) {
      daftarNotifikasi.add("⚠️ Gula harian mendekati batas (25 - 50 gram)");
    }
  }
}
