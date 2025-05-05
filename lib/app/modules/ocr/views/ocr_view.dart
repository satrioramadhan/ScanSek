import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import '../controllers/ocr_controller.dart';
import '../../../themes/app_colors.dart';

class OcrView extends GetView<OcrController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SafeArea(
          child: Stack(
            children: [
              // Kamera + tap deteksi manual
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.triggerDetection();
                  Future.delayed(const Duration(milliseconds: 1500), () {
                    controller.triggerDetection();
                  });
                },
                child: SizedBox.expand(
                  child: CameraPreview(controller.cameraController),
                ),
              ),

              // Overlay Informasi Gula (atas tengah)
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Obx(() {
                  final sugar = controller.sugarGram.value;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: sugar > 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Gula Terdeteksi:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "$sugar gram gula ≈ ${controller.sugarTeaspoon.toStringAsFixed(2)} sdt",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          )
                        : const Text(
                            "Tidak ditemukan informasi gula",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                  );
                }),
              ),

              // Tombol ceklis (bawah tengah)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 80),
                  child: Obx(() {
                    final sugar = controller.sugarGram.value;
                    return sugar > 0
                        ? FloatingActionButton.extended(
                            backgroundColor: Colors.greenAccent,
                            onPressed: () {
                              Get.toNamed('/history', arguments: {
                                'openAddDialog': true,
                                'gulaGram': sugar,
                              });
                            },
                            icon: const Icon(Icons.check, color: Colors.black),
                            label: const Text(
                              "Pilih",
                              style: TextStyle(color: Colors.black),
                            ),
                          )
                        : const SizedBox.shrink();
                  }),
                ),
              ),

              // Tombol Back (pojok kiri atas)
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    Get.back();
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
