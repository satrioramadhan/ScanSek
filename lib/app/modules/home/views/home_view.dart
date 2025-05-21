import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../themes/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import '../../../data/services/gula_service.dart';
import '../../../data/services/air_service.dart';
import '../../../modules/history/controllers/history_controller.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.ambilDataHariIni(),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.gradientStart, AppColors.primary],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius:
                          BorderRadius.vertical(bottom: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 6,
                            offset: Offset(0, 3)),
                      ],
                    ),
                    padding: EdgeInsets.fromLTRB(20, 50, 20, 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Obx(() => Text("Hi, ${controller.namaUser} 👋",
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))),
                                SizedBox(height: 4),
                                Text("Semangat sehat hari ini!",
                                    style: TextStyle(color: Colors.white70)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.notifications_none,
                                      color: Colors.white),
                                  onPressed: () {
                                    final notifs = controller.daftarNotifikasi;
                                    if (notifs.isEmpty) {
                                      Get.snackbar("Notifikasi",
                                          "Belum ada notifikasi hari ini");
                                    } else {
                                      Get.bottomSheet(
                                        Container(
                                          padding: EdgeInsets.all(20),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(20)),
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text("Notifikasi Hari Ini",
                                                  style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold)),
                                              SizedBox(height: 10),
                                              ...notifs.map((n) => Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 6),
                                                    child: Text("• $n"),
                                                  ))
                                            ],
                                          ),
                                        ),
                                        isScrollControlled: true,
                                      );
                                    }
                                  },
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.more_vert, color: Colors.white),
                              ],
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            height: 180,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Gula Hari Ini",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Obx(() {
                                            Color textColor;
                                            if (controller
                                                    .totalGulaHariIni.value <
                                                25) {
                                              textColor = const Color.fromARGB(
                                                  255, 247, 135, 117);
                                            } else if (controller
                                                    .totalGulaHariIni.value <
                                                50) {
                                              textColor = Colors.orange;
                                            } else {
                                              textColor = const Color.fromARGB(
                                                  255, 255, 30, 30);
                                            }
                                            return Text(
                                              "${controller.totalGulaHariIni.value} gram",
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            );
                                          }),
                                          Obx(() => Text(
                                                "≈ ${controller.konversiKeSendokTeh()} sdt",
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors
                                                        .textSecondary),
                                              )),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        await Get.toNamed(Routes.HISTORY,
                                            arguments: {'openAddDialog': true});
                                        controller.ambilDataHariIni();
                                        controller.ambilRiwayat3Hari();
                                      },
                                      icon: Icon(Icons.add_circle,
                                          color: AppColors.colbutton, size: 30),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                Center(
                                  child: Obx(() {
                                    String lottieAsset;
                                    if (controller.totalGulaHariIni.value <
                                        25) {
                                      lottieAsset = 'assets/lottie/health.json';
                                    } else if (controller
                                            .totalGulaHariIni.value <
                                        50) {
                                      lottieAsset =
                                          'assets/lottie/warning.json';
                                    } else {
                                      lottieAsset = 'assets/lottie/stop.json';
                                    }
                                    return Align(
                                      alignment: controller
                                          .getLottieAlignment(lottieAsset),
                                      child: SizedBox(
                                        height: controller
                                            .getLottieSize(lottieAsset),
                                        width: controller
                                            .getLottieSize(lottieAsset),
                                        child: Lottie.asset(
                                          lottieAsset,
                                          controller:
                                              controller.lottieController,
                                          fit: BoxFit.contain,
                                          repeat: true,
                                          onLoaded: (composition) {
                                            controller
                                                    .lottieController.duration =
                                                composition.duration;
                                            controller.lottieController
                                                .repeat();
                                          },
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ],
                            ),
                            padding: EdgeInsets.all(16),
                            height: 180,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset('assets/lottie/glass.json',
                                    height: 90),
                                SizedBox(height: 8),
                                Obx(() => Text(
                                      "${controller.totalGelasAir.value} gelas hari ini",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary),
                                    )),
                                SizedBox(height: 4),
                                Text("Target: 8 gelas/hari",
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary))
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        menuTile(Icons.qr_code_scanner, "Scan Label",
                            () => Get.toNamed(Routes.OCR)),
                        menuTile(Icons.history, "Riwayat", bukaRiwayatHariIni),
                        menuTile(Icons.bar_chart, "Statistik",
                            () => Get.toNamed(Routes.STATISTICS)),
                        menuTile(Icons.flag, "Target",
                            () => Get.toNamed(Routes.TARGET)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Makanan Terakhir",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black12, blurRadius: 4)
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Obx(() => Text(
                                          controller.makananTerakhir.value,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )),
                                    Obx(() => controller.waktuMakananTerakhir
                                            .value.isNotEmpty
                                        ? Text(
                                            controller
                                                .waktuMakananTerakhir.value,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          )
                                        : SizedBox.shrink()),
                                    SizedBox(height: 4),
                                    Obx(() => Text(
                                          "${controller.gulaMakananTerakhir.value} gram gula",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textSecondary,
                                          ),
                                        )),
                                  ],
                                ),
                                Icon(Icons.fastfood, color: Colors.deepPurple),
                              ],
                            )),
                        SizedBox(height: 20),
                        Text("Air Putih Hari Ini",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Obx(() => Text(
                                  controller.jamMinumTerakhir.isEmpty
                                      ? "Belum ada jam minum hari ini"
                                      : "Terakhir minum: ${controller.jamMinumTerakhir.value}",
                                  style: TextStyle(fontSize: 16))),
                              IconButton(
                                onPressed: () async {
                                  await controller.tambahAirLangsung();
                                  controller.ambilDataHariIni();
                                  controller.ambilRiwayat3Hari();
                                },
                                icon: Icon(Icons.add_circle,
                                    color: AppColors.colbutton),
                              )
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Text("Riwayat 3 Hari Terakhir",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Obx(() {
                          final dataList = controller.riwayat3Hari;

                          if (dataList.isEmpty) {
                            return Center(child: Text("Belum ada data"));
                          }

                          return Column(
                            children: dataList.map((data) {
                              final tgl = DateFormat('EEEE, d MMM', 'id_ID')
                                  .format(data["tanggal"]);
                              return ListTile(
                                title: Text(tgl),
                                subtitle: Text(
                                    "${data['gula']} gram gula, ${data['air']} gelas air"),
                                leading: Icon(Icons.calendar_today_outlined),
                              );
                            }).toList(),
                          );
                        }),
                        Text("Insight Gula",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          child: Text(
                              "💡 Batasi konsumsi minuman manis sebelum tidur untuk menjaga kadar gula darahmu."),
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        currentIndex: 0, // Default index = Home
        onTap: (index) {
          switch (index) {
            case 0:
              Get.toNamed(Routes.HOME);
              break;
            case 1:
              Get.toNamed(Routes.BERITA);
              break;
            case 2:
              Get.toNamed(Routes.PROFILE);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: "Berita"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }

  Widget menuTile(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void bukaRiwayatHariIni() {
    final controller = Get.put(HistoryController());
    controller.changeSelectedDate(DateTime.now());
    Get.toNamed(Routes.HISTORY);
  }
}
