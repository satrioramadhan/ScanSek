import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum ChartType { gula, air }

class StatisticsController extends GetxController {
  var selectedChart = ChartType.gula.obs;

  final List<int> gulaHarian = [20, 35, 15, 40, 25, 30, 10];
  final List<int> airHarian = [6, 5, 8, 7, 4, 6, 7];

  final int targetGulaPerHari = 25;

  late PageController pageController; // <<< INI YANG PERLU DITAMBAH

  int get totalGulaHariIni => gulaHarian.last;
  int get totalAirHariIni => airHarian.last;

  double get rataRataGulaMingguan => gulaHarian.reduce((a, b) => a + b) / gulaHarian.length;
  double get rataRataAirMingguan => airHarian.reduce((a, b) => a + b) / airHarian.length;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void setChartType(ChartType type) {
    selectedChart.value = type;
  }
}
