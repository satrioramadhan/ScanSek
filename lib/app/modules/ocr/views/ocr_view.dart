import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ocr_controller.dart';
import '../widgets/sugar_highlight_painter.dart';
import '../widgets/corner_guide_overlay.dart';
import 'package:scan_sek/app/routes/app_pages.dart';

class OcrView extends GetView<OcrController> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = screenSize.width * 0.6;
    final height = width * 4 / 3;
    final left = (screenSize.width - width) / 2;
    final top = (screenSize.height - height) / 2;
    final guideRect = Rect.fromLTWH(left, top, width, height);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Obx(() {
          final mode = controller.currentMode.value;

          if (mode == OcrMode.fotoLabel &&
              controller.capturedImage.value != null) {
            // Tampilan hasil gambar label + highlight
            return Stack(
              children: [
                Positioned.fill(
                  child: Image.file(
                    controller.capturedImage.value!,
                    fit: BoxFit.contain,
                  ),
                ),
                CustomPaint(
                  size: Size.infinite,
                  painter:
                      SugarHighlightPainter(controller.highlightRects.toList()),
                ),
                // Sendok & konversi
                if (controller.spoonImages.isNotEmpty)
                  Positioned(
                    bottom: 200,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 12,
                          children: controller.spoonImages
                              .toSet()
                              .map((path) => Column(
                                    children: [
                                      Image.asset(path, width: 60, height: 60),
                                      Text(
                                          "x${controller.spoonImages.where((p) => p == path).length}",
                                          style: const TextStyle(
                                              color: Colors.white)),
                                    ],
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          controller.currentTeaspoonText.value,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                // Tombol Pilih
                if (controller.sugarGram.value > 0)
                  Positioned(
                    bottom: 80,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.extended(
                        backgroundColor: Colors.greenAccent,
                        onPressed: () {
                          Get.offNamed(Routes.HISTORY, arguments: {
                            'openAddDialog': true,
                            'gulaGram': controller.sugarGram.value,
                            'autoJumlah': 1,
                            'autoSatuan': 'gram',
                          });
                        },
                        icon: const Icon(Icons.check, color: Colors.black),
                        label: const Text("Pilih",
                            style: TextStyle(color: Colors.black)),
                      ),
                    ),
                  ),
                // Tombol Back/Ulangi
                Positioned(
                  top: 10,
                  left: 10,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      controller.capturedImage.value = null;
                      controller.currentMode.value = OcrMode.capture;
                      controller.resetDetection();
                    },
                  ),
                ),
              ],
            );
          }

          // MODE CAPTURE BIASA
          return Stack(
            children: [
              Obx(() => controller.isCameraInitialized.value
                  ? SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: controller
                              .cameraController.value.previewSize!.height,
                          height: controller
                              .cameraController.value.previewSize!.width,
                          child: CameraPreview(controller.cameraController),
                        ),
                      ),
                    )
                  : const Center(child: CircularProgressIndicator())),

              CornerGuideOverlay(guideRect: guideRect),

              Obx(() => CustomPaint(
                    size: Size.infinite,
                    painter: SugarHighlightPainter(
                        controller.highlightRects.toList()),
                  )),

              // ✅ Sendok & konversi
              Obx(() {
                final spoons = controller.spoonImages;
                if (spoons.isEmpty) return const SizedBox();

                final grouped = <String, int>{};
                for (final path in spoons) {
                  grouped[path] = (grouped[path] ?? 0) + 1;
                }

                return Positioned(
                  bottom: 220,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        children: grouped.entries
                            .map((entry) => Column(
                                  children: [
                                    Image.asset(entry.key,
                                        width: 60, height: 60),
                                    Text("x${entry.value}",
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 16)),
                                  ],
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        controller.currentTeaspoonText.value,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }),

              // ✅ Tombol Pilih (hanya muncul jika ada hasil deteksi)
              if (controller.sugarGram.value > 0)
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: FloatingActionButton.extended(
                      backgroundColor: Colors.greenAccent,
                      onPressed: () {
                        Get.offNamed(Routes.HISTORY, arguments: {
                          'openAddDialog': true,
                          'gulaGram': controller.sugarGram.value,
                          'autoJumlah': 1,
                          'autoSatuan': 'gram',
                        });
                      },
                      icon: const Icon(Icons.check, color: Colors.black),
                      label: const Text("Pilih",
                          style: TextStyle(color: Colors.black)),
                    ),
                  ),
                ),

              // ✅ Button utama yang berubah fungsi berdasarkan mode
              Obx(() => Positioned(
                    bottom: 140,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: FloatingActionButton.extended(
                        backgroundColor: controller.isCapturing.value
                            ? Colors.grey
                            : Colors.blueAccent,
                        onPressed: controller.isCapturing.value
                            ? null
                            : controller.handleMainButton,
                        icon: controller.isCapturing.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(controller.getMainButtonIcon(),
                                color: Colors.white),
                        label: Text(
                          controller.getMainButtonText(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  )),

              // ✅ Switch mode button
              Positioned(
                top: 10,
                right: 10,
                child: Obx(() => Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (controller.isPhotoMode.value) {
                                controller.togglePhotoMode();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !controller.isPhotoMode.value
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Deteksi",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: !controller.isPhotoMode.value
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              if (!controller.isPhotoMode.value) {
                                controller.togglePhotoMode();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: controller.isPhotoMode.value
                                    ? Colors.blueAccent
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.image_search,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Foto",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: controller.isPhotoMode.value
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ),

              // ✅ Back button
              Positioned(
                top: 10,
                left: 10,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),

              // ✅ Instruksi yang berubah berdasarkan mode
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Center(
                  child: Obx(() => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              controller.isPhotoMode.value
                                  ? "Mode: Ambil Foto Label"
                                  : "Mode: Deteksi Langsung",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.isPhotoMode.value
                                  ? "📷 Posisikan label dalam siku putih\n🖼️ Klik tombol untuk ambil foto label"
                                  : "📷 Posisikan label dalam siku putih\n🔍 Klik tombol untuk deteksi langsung",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
