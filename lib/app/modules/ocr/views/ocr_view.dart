import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/ocr_controller.dart';
import '../widgets/animated_corner_guide_overlay.dart';
import '../widgets/sugar_highlight_painter.dart';
import '../widgets/hole_overlay_painter.dart';
import 'package:scan_sek/app/routes/app_pages.dart';

class OcrView extends GetView<OcrController> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final width = MediaQuery.of(context).size.width * 0.8;
    final height = 200.0;
    final left = (screenSize.width - width) / 2;
    final top = (screenSize.height - height) / 2;
    final guideRect = Rect.fromLTWH(left, top, width, height);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Kamera Preview
            Obx(
              () => controller.isCameraInitialized.value
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
                  : const Center(child: CircularProgressIndicator()),
            ),

            // Highlight OCR gula & gram
            Obx(
              () => CustomPaint(
                size: Size.infinite,
                painter:
                    SugarHighlightPainter(controller.highlightRects.toList()),
              ),
            ),

            // Overlay gelap berlubang
            Obx(
              () => controller.isCustomRectActive.value
                  ? Positioned.fill(
                      child: CustomPaint(
                        painter: HoleOverlayPainter(controller.guideRect.value),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Bingkai animasi
            Obx(
              () => AnimatedCornerGuideOverlay(
                guideRect: controller.guideRect.value,
              ),
            ),

            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                final tapY = details.localPosition.dy;
                final width = MediaQuery.of(context).size.width * 0.8;
                final height = 50.0;
                final left = (MediaQuery.of(context).size.width - width) / 2;
                final top = tapY - height / 2;

                controller.guideRect.value =
                    Rect.fromLTWH(left, top, width, height);
                controller.isCustomRectActive.value = true;

                controller.triggerDetection(fromCustomRect: true);
              },
              onDoubleTap: () {
                controller.isCustomRectActive.value = false;
                controller.guideRect.value = guideRect;
                controller.triggerDetection();
              },
            ),

            // Gambar sendok & teks (tidak tergelapkan)
            Obx(() {
              final spoons = controller.spoonImages;
              if (spoons.isEmpty) return const SizedBox();

              final grouped = <String, int>{};
              for (final path in spoons)
                grouped[path] = (grouped[path] ?? 0) + 1;

              return Positioned(
                bottom: 150,
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
                                  Image.asset(entry.key, width: 60, height: 60),
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
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              );
            }),

            // Tombol "Pilih" (tidak tergelapkan)
            Obx(() {
              final sugar = controller.sugarGram.value;
              return Positioned(
                bottom: 80,
                left: 0,
                right: 0,
                child: sugar > 0
                    ? Center(
                        child: FloatingActionButton.extended(
                          backgroundColor: Colors.greenAccent,
                          onPressed: () {
                            final sugar = controller.sugarGram.value;
                            Get.offNamed(Routes.HISTORY, arguments: {
                              'openAddDialog': true,
                              'gulaGram': sugar,
                              'autoJumlah': 1,
                              'autoSatuan': 'gram',
                            });
                          },
                          icon: const Icon(Icons.check, color: Colors.black),
                          label: const Text("Pilih",
                              style: TextStyle(color: Colors.black)),
                        ),
                      )
                    : const SizedBox.shrink(),
              );
            }),

            // Tombol Back (tidak tergelapkan)
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Get.back(),
              ),
            ),

            // Petunjuk UX (tidak tergelapkan)
            Positioned(
              top: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        "📦 Posisikan label gizi dalam siku putih",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "👆 Tap untuk pilih area 'Gula'\n🌀 Double tap deteksi otomatis",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
