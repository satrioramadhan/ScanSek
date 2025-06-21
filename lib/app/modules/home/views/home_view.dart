import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../themes/app_colors.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
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
                                            final total = controller
                                                .totalGulaHariIni.value;
                                            final target =
                                                controller.targetGula.value;

                                            Color textColor;
                                            if (target == 0) {
                                              textColor = Colors.grey;
                                            } else {
                                              final batas1 =
                                                  (target / 3).floor();
                                              final batas2 =
                                                  (2 * target / 3).floor();

                                              if (total < batas1) {
                                                textColor =
                                                    const Color.fromARGB(
                                                        255, 247, 135, 117);
                                              } else if (total < batas2) {
                                                textColor = Colors.orange;
                                              } else {
                                                textColor =
                                                    const Color.fromARGB(
                                                        255, 255, 30, 30);
                                              }
                                            }

                                            return Text(
                                              "$total gram",
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
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              )),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        final total =
                                            controller.totalGulaHariIni.value;
                                        final target =
                                            controller.targetGula.value;
                                        final selisih = target - total;

                                        if (selisih <= 10 && selisih > 0) {
                                          Get.defaultDialog(
                                            title: "Hati-hati!",
                                            middleText:
                                                "Kamu akan mencapai batas konsumsi gula.\nKurang $selisih gram lagi akan menyentuh target.\nYakin ingin menambahkan?",
                                            textConfirm: "Yakin",
                                            textCancel: "Batal",
                                            confirmTextColor: Colors.white,
                                            onConfirm: () {
                                              Get.back(); // tutup dialog
                                              Get.toNamed(Routes.HISTORY,
                                                  arguments: {
                                                    'openAddDialog': true
                                                  });
                                            },
                                          );
                                        } else if (selisih <= 0) {
                                          Get.defaultDialog(
                                            title: "⚠️ Terlalu Banyak Gula!",
                                            middleText:
                                                "Kamu sudah melebihi batas konsumsi gula harian!\nTambahan konsumsi bisa berdampak buruk bagi kesehatan.\nYakin masih ingin menambahkan?",
                                            textConfirm: "Tetap Tambah",
                                            textCancel: "Batal",
                                            confirmTextColor: Colors.white,
                                            onConfirm: () {
                                              Get.back();
                                              Get.toNamed(Routes.HISTORY,
                                                  arguments: {
                                                    'openAddDialog': true
                                                  });
                                            },
                                          );
                                        } else {
                                          // aman → langsung jalan
                                          Get.toNamed(Routes.HISTORY,
                                              arguments: {
                                                'openAddDialog': true
                                              });
                                        }
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
                                    final asset = controller.lottieAsset;
                                    return Align(
                                      alignment:
                                          controller.getLottieAlignment(asset),
                                      child: SizedBox(
                                        height: controller.getLottieSize(asset),
                                        width: controller.getLottieSize(asset),
                                        child: Lottie.asset(
                                          asset,
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
                          child: GestureDetector(
                            onTap: () {
                              controller.triggerFastAnimation(
                                controller: controller
                                    .airLottieController, // khusus animasi gelas
                                durationMs: 300,
                              );
                              controller.tambahAirLangsung();
                              controller.ambilDataHariIni();
                              controller.ambilRiwayat3Hari();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                      color: Colors.black12, blurRadius: 4),
                                ],
                              ),
                              padding: EdgeInsets.all(16),
                              height: 180,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Lottie.asset(
                                      'assets/lottie/glass.json',
                                      controller: controller
                                          .airLottieController, // animasi gelas
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Obx(() => Text(
                                        "${controller.totalGelasAir.value} gelas hari ini",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textSecondary,
                                        ),
                                      )),
                                  SizedBox(height: 2),
                                  Obx(() => Text(
                                        "Target: ${controller.targetAir.value} gelas/hari",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      )),
                                  SizedBox(height: 2),
                                  Text(
                                    "Klik gelas untuk tambah",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
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
