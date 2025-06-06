import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../themes/app_colors.dart';
import '../controllers/statistics_controller.dart';

class StatisticsView extends StatelessWidget {
  final StatisticsController controller = Get.find<StatisticsController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Statistik Konsumsi Mingguan'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Obx(() => ToggleButtons(
                    borderRadius: BorderRadius.circular(10),
                    fillColor: AppColors.primary,
                    selectedColor: Colors.white,
                    color: AppColors.primary,
                    selectedBorderColor: AppColors.primary,
                    borderColor: AppColors.primary,
                    constraints:
                        const BoxConstraints(minHeight: 40, minWidth: 100),
                    isSelected: [
                      controller.selectedChart.value == ChartType.gula,
                      controller.selectedChart.value == ChartType.air,
                    ],
                    onPressed: (index) {
                      controller.setChartType(
                          index == 0 ? ChartType.gula : ChartType.air);
                      controller.pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    children: const [
                      Text('Gula',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('Air',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: PageView(
                controller: controller.pageController,
                onPageChanged: (index) {
                  controller.setChartType(
                      index == 0 ? ChartType.gula : ChartType.air);
                },
                children: [
                  Obx(() => BarChart(_buildGulaChart(controller))),
                  Obx(() => BarChart(_buildAirChart(controller))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              if (controller.selectedChart.value == ChartType.gula) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total gula hari ini: ${controller.totalGulaHariIni} gram",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Rata-rata konsumsi gula: ${controller.rataRataGulaMingguan.toStringAsFixed(1)} gram",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    if (controller.totalGulaHariIni >
                        controller.targetGulaPerHari)
                      const Text(
                        "⚠️ Kamu melebihi target gula hari ini!",
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        "✅ Kamu masih dalam batas aman hari ini!",
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Total minum air hari ini: ${controller.totalAirHariIni} gelas",
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      "Rata-rata minum air: ${controller.rataRataAirMingguan.toStringAsFixed(1)} gelas",
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  BarChartData _buildGulaChart(StatisticsController controller) {
    // 🔥 Cari nilai maksimum gulaHarian biar maxY fleksibel
    final maxData = controller.gulaHarian.isNotEmpty
        ? controller.gulaHarian.reduce((a, b) => a > b ? a : b)
        : 60;
    final kelipatan = maxData <= 60 ? 10 : 20;
    final maxY =
        ((maxData / kelipatan).ceil()) * kelipatan; // 🔥 maxY fleksibel

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY.toDouble(), // 🔥 Pakai maxY dinamis
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => const Color.fromARGB(255, 171, 166, 166),
          tooltipPadding: const EdgeInsets.all(8),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final gram = rod.toY;
            final sendokTeh = (gram / 4).toStringAsFixed(1);
            return BarTooltipItem(
              "$gram gram\n≈ $sendokTeh sdt",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < controller.labelHarian.length) {
                return Text(controller.labelHarian[index],
                    style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(controller.gulaHarian.length, (index) {
        final value = controller.gulaHarian[index];
        Color barColor;
        if (value <= 30) {
          barColor = Colors.blue; // 🔵 biru
        } else if (value <= 49) {
          barColor = Colors.yellow; // 🟡 kuning
        } else {
          barColor = Colors.red; // 🔴 merah
        }
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: barColor,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }

  BarChartData _buildAirChart(StatisticsController controller) {
    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: 15,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => const Color.fromARGB(255, 170, 170, 170),
          tooltipPadding: const EdgeInsets.all(8),
          tooltipRoundedRadius: 8,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final gelas = rod.toY.toStringAsFixed(0);
            return BarTooltipItem(
              "$gelas gelas",
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < controller.labelHarian.length) {
                return Text(controller.labelHarian[index],
                    style: const TextStyle(fontSize: 10));
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: true, reservedSize: 28),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: List.generate(controller.airHarian.length, (index) {
        final value = controller.airHarian[index];
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value.toDouble(),
              color: Colors.lightBlue,
              width: 16,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        );
      }),
    );
  }
}
