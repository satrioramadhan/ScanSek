import 'package:flutter/animation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart';

class HomeController extends GetxController
    with WidgetsBindingObserver, GetTickerProviderStateMixin {
  var totalGulaHariIni = 0.obs;
  var totalGelasAir = 0.obs;
  var makananTerakhir = "(belum ada)".obs;
  var gulaMakananTerakhir = 0.obs;
  var waktuMakananTerakhir = "".obs;
  var daftarNotifikasi = <String>[].obs;
  var namaUser = "Pengguna".obs;
  var jamMinumTerakhir = "".obs;

  // Ukuran dan alignment Lottie
  final Map<String, double> lottieSizeMap = {
    'assets/lottie/health.json': 60,
    'assets/lottie/warning.json': 64,
    'assets/lottie/stop.json': 60,
  };

  final Map<String, Alignment> lottieAlignmentMap = {
    'assets/lottie/health.json': Alignment.center,
    'assets/lottie/warning.json': Alignment.center,
    'assets/lottie/stop.json': Alignment.center,
  };

  double getLottieSize(String asset) => lottieSizeMap[asset] ?? 60;
  Alignment getLottieAlignment(String asset) =>
      lottieAlignmentMap[asset] ?? Alignment.center;

  late AnimationController lottieController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this); // <--- tambahin ini
    lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    ambilNamaUser();
    ambilDataHariIni();
    ambilRiwayat3Hari();
  }

  @override
  void onReady() {
    super.onReady();
    ambilDataHariIni();
    ambilRiwayat3Hari();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    lottieController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ambilDataHariIni();
      ambilRiwayat3Hari();
    }
  }

  double konversiKeSendokTeh() => (totalGulaHariIni.value / 4).toPrecision(2);

  Future<void> ambilNamaUser() async {
    final prefs = await SharedPreferences.getInstance();
    namaUser.value = prefs.getString('username') ?? 'Pengguna';
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

  String get lottieAsset {
    final total = totalGulaHariIni.value;
    if (total < 25) return 'assets/lottie/health.json';
    if (total < 50) return 'assets/lottie/warning.json';
    return 'assets/lottie/stop.json';
  }

  Future<void> ambilDataHariIni() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      // Ambil data gula
      final resGula = await GulaService.ambilGula(tanggal: today);
      if (resGula.statusCode == 200 && resGula.data['success'] == true) {
        final List<dynamic> data = resGula.data['data'];
        int totalGula = 0;
        for (var item in data) {
          totalGula += (item['totalGula'] as num).toInt();
        }
        totalGulaHariIni.value = totalGula;

        if (data.isNotEmpty) {
          final lastItem = data.last;
          makananTerakhir.value =
              lastItem['namaMakanan'] ?? "(tidak diketahui)";
          gulaMakananTerakhir.value = (lastItem['totalGula'] as num).toInt();

          // ambil waktu input
          final waktu = lastItem['waktuInput'];
          if (waktu != null) {
            final dt = DateTime.tryParse(waktu);
            if (dt != null) {
              waktuMakananTerakhir.value =
                  DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
            }
          }
        }
      }

      // Ambil data air
      final resAir = await AirService.ambilAir(today);
      if (resAir.statusCode == 200 && resAir.data['success'] == true) {
        final List<dynamic> jamList =
            resAir.data['data']['riwayatJamMinum'] ?? [];
        totalGelasAir.value = jamList.length;
        if (jamList.isNotEmpty) {
          final lastTime = jamList.last; // misal "22:45"
          final fullDateTimeStr = "$today $lastTime";

          // Format lengkap: yyyy-MM-dd HH:mm
          final dt = DateTime.tryParse(fullDateTimeStr);
          if (dt != null) {
            jamMinumTerakhir.value =
                DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
          } else {
            jamMinumTerakhir.value = lastTime; // fallback aja kalau gagal parse
          }
        }
      }

      updateLottieSpeed();
    } catch (e) {
      print("Gagal ambil data home: $e");
    }

    cekNotifikasi();
  }

  void cekNotifikasi() {
    daftarNotifikasi.clear();
    if (totalGulaHariIni.value > 50) {
      daftarNotifikasi.add("⚠️ Gula harian melewati batas aman (> 50 gram)");
    } else if (totalGulaHariIni.value > 25) {
      daftarNotifikasi.add("⚠️ Gula harian mendekati batas (25 - 50 gram)");
    }
  }

  Future<void> tambahAirLangsung() async {
    final now = DateTime.now();
    final jam = DateFormat.Hm().format(now);
    final tanggal = DateFormat('yyyy-MM-dd').format(now);

    try {
      final res = await AirService.tambahJamMinum(tanggal, jam);
      if (res.statusCode == 201 && res.data['success'] == true) {
        totalGelasAir.value++;
        jamMinumTerakhir.value = jam;
        Get.snackbar("Berhasil", "Jam minum $jam ditambahkan");
      } else {
        Get.snackbar("Gagal", res.data['message'] ?? "Gagal tambah jam");
      }
    } catch (e) {
      Get.snackbar("Error", "Terjadi kesalahan: $e");
    }
  }

  var riwayat3Hari = <Map<String, dynamic>>[].obs;

  Future<void> ambilRiwayat3Hari() async {
    final now = DateTime.now();
    final dates = List.generate(3, (i) => now.subtract(Duration(days: i + 1)));

    try {
      final List<Map<String, dynamic>> dataList = [];

      for (var date in dates) {
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        final gulaRes = await GulaService.ambilGula(tanggal: dateStr);
        final airRes = await AirService.ambilAir(dateStr);

        int gula = 0, air = 0;

        if (gulaRes.statusCode == 200 && gulaRes.data['success'] == true) {
          for (var item in gulaRes.data['data']) {
            gula += (item['totalGula'] as num).toInt();
          }
        }

        if (airRes.statusCode == 200 && airRes.data['success'] == true) {
          air = (airRes.data['data']['riwayatJamMinum'] as List).length;
        }

        dataList.add({
          "tanggal": date,
          "gula": gula,
          "air": air,
        });
      }

      riwayat3Hari.value = dataList;
    } catch (e) {
      print("Gagal ambil riwayat 3 hari: $e");
      riwayat3Hari.clear();
    }
  }
}
