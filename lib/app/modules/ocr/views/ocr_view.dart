import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/ocr_controller.dart';
import '../../../themes/app_colors.dart'; // ← penting!
import 'package:camera/camera.dart';

class OcrView extends GetView<OcrController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Scan Label Gula'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Obx(() {
        if (!controller.isCameraInitialized.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            // Kamera Preview
            AspectRatio(
              aspectRatio: controller.cameraController.value.aspectRatio,
              child: CameraPreview(controller.cameraController),
            ),
            const SizedBox(height: 10),

            // Tombol Scan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: controller.captureAndRecognizeText,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Scan dari Kamera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.colbutton,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: controller.pickImageFromGallery,
                    icon: const Icon(Icons.image),
                    label: const Text("Unggah dari Galeri"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hasil OCR & gula
            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: controller.recognizedText.value.isNotEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cardShadow,
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Hasil OCR:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              )),
                          const SizedBox(height: 6),
                          Text(
                            controller.recognizedText.value,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            controller.sugarGram.value > 0
                                ? "${controller.sugarGram.value} gram gula ≈ ${controller.sugarTeaspoon.toStringAsFixed(2)} sdt"
                                : "Tidak ditemukan info gula",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: controller.sugarGram.value > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (controller.sugarGram.value > 0)
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.toNamed('/history', arguments: {
                                  'openAddDialog': true,
                                  'gulaGram': controller.sugarGram.value,
                                });
                              },
                              icon: const Icon(Icons.check),
                              label: const Text("Pilih Makanan Ini"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.colbutton,
                                foregroundColor: Colors.black,
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                        ],
                      ),
                    )
                  : const Text(
                      "Belum ada hasil, silakan scan.",
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
            )),
          ],
        );
      }),
    );
  }
}
