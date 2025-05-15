import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart';

enum ChartType { gula, air }

class StatisticsController extends GetxController {
  var selectedChart = ChartType.gula.obs;

  var gulaHarian = <int>[].obs;
  var airHarian = <int>[].obs;

  final int targetGulaPerHari = 25;
  late PageController pageController;

  int get totalGulaHariIni => gulaHarian.isNotEmpty ? gulaHarian.last : 0;
  int get totalAirHariIni => airHarian.isNotEmpty ? airHarian.last : 0;

  double get rataRataGulaMingguan => gulaHarian.isEmpty
      ? 0
      : gulaHarian.reduce((a, b) => a + b) / gulaHarian.length;
  double get rataRataAirMingguan => airHarian.isEmpty
      ? 0
      : airHarian.reduce((a, b) => a + b) / airHarian.length;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    fetchWeeklyData(); // ✅ ambil data pas inisialisasi
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void setChartType(ChartType type) {
    selectedChart.value = type;
  }

  Future<void> fetchWeeklyData() async {
    gulaHarian.clear();
    airHarian.clear();

    final today = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      try {
        // GULA
        final resGula = await GulaService.ambilGula(tanggal: dateStr);
        int totalGula = 0;
        if (resGula.statusCode == 200 && resGula.data['success'] == true) {
          final List<dynamic> list = resGula.data['data'];
          for (var item in list) {
            totalGula += (item['totalGula'] as num).toInt();
          }
        }
        gulaHarian.add(totalGula);

        // AIR
        final resAir = await AirService.ambilAir(dateStr);
        int gelas = 0;
        if (resAir.statusCode == 200 && resAir.data['success'] == true) {
          final List<dynamic> list =
              resAir.data['data']['riwayatJamMinum'] ?? [];
          gelas = list.length;
        }
        airHarian.add(gelas);
      } catch (e) {
        gulaHarian.add(0);
        airHarian.add(0);
      }
    }
  }
}
