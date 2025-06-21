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
  final targetGula = 50.obs;
  final targetAir = 8.obs;
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
  late AnimationController airLottieController;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    lottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    airLottieController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    airLottieController.repeat();
    ;

    ambilNamaUser();
    ambilDataHariIni();
    ambilRiwayat3Hari();
    ambilTarget();
    everAll([totalGulaHariIni, targetGula], (_) {
      updateLottieSpeed();
    });
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
    airLottieController.dispose();
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
    final total = totalGulaHariIni.value;
    final target = targetGula.value;

    if (target == 0) {
      lottieController.duration = const Duration(seconds: 2);
    } else {
      final batas1 = (target / 3).floor();
      final batas2 = (2 * target / 3).floor();

      if (total < batas1) {
        lottieController.duration = const Duration(seconds: 2);
      } else if (total < batas2) {
        lottieController.duration = const Duration(seconds: 1);
      } else {
        lottieController.duration = const Duration(milliseconds: 800);
      }
    }

    lottieController.repeat();
  }

  String get lottieAsset {
    final total = totalGulaHariIni.value;
    final target = targetGula.value;

    if (target == 0) return 'assets/lottie/health.json';

    final batas1 = (target / 3).floor();
    final batas2 = (2 * target / 3).floor();

    if (total < batas1) return 'assets/lottie/health.json';
    if (total < batas2) return 'assets/lottie/warning.json';
    return 'assets/lottie/stop.json';
  }

  Future<void> ambilDataHariIni() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    try {
      final resGula = await GulaService.ambilGula(tanggal: today);
      if (resGula.statusCode == 200 && resGula.data['success'] == true) {
        final List<dynamic> data = resGula.data['data'];

        data.removeWhere((item) => item['waktuInput'] == null);

        totalGulaHariIni.value = data.fold(
            0, (sum, item) => sum + (item['totalGula'] as num).toInt());

        if (data.isNotEmpty) {
          data.sort((a, b) => DateTime.parse(b['waktuInput'])
              .compareTo(DateTime.parse(a['waktuInput'])));
          final lastItem = data.first;

          makananTerakhir.value =
              lastItem['namaMakanan'] ?? "(tidak diketahui)";
          gulaMakananTerakhir.value = (lastItem['totalGula'] as num).toInt();

          final waktu = lastItem['waktuInput'];
          final dt = DateTime.tryParse(waktu);
          if (dt != null) {
            waktuMakananTerakhir.value =
                DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
          } else {
            waktuMakananTerakhir.value = "(waktu tidak valid)";
          }
        } else {
          makananTerakhir.value = "(belum ada)";
          gulaMakananTerakhir.value = 0;
          waktuMakananTerakhir.value = "";
        }
      }

      // Ambil data air
      final resAir = await AirService.ambilAir(today);
      if (resAir.statusCode == 200 && resAir.data['success'] == true) {
        final List<dynamic> jamList =
            resAir.data['data']['riwayatJamMinum'] ?? [];
        totalGelasAir.value = jamList.length;
        if (jamList.isNotEmpty) {
          final lastTime = jamList.last;
          final fullDateTimeStr = "$today $lastTime";
          final dt = DateTime.tryParse(fullDateTimeStr);
          if (dt != null) {
            jamMinumTerakhir.value =
                DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dt);
          } else {
            jamMinumTerakhir.value = lastTime;
          }
        } else {
          jamMinumTerakhir.value = "";
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

  Future<void> ambilTarget() async {
    final prefs = await SharedPreferences.getInstance();
    targetGula.value = prefs.getInt('target_gula') ?? 50;
    targetAir.value = prefs.getInt('target_air') ?? 8;
  }

  void triggerFastAnimation(
      {AnimationController? controller, int? durationMs}) {
    final usedController = controller ?? lottieController;

    usedController.stop();
    usedController.duration = Duration(seconds: 1, milliseconds: 300);
    usedController.reset();
    usedController.forward().then((_) {
      usedController.duration = const Duration(seconds: 2);
      usedController.repeat();
    });
  }
}
