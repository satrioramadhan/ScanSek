// ocr_controller.dart
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrController extends GetxController {
  late CameraController cameraController;
  var isCameraInitialized = false.obs;
  var recognizedText = ''.obs;
  var sugarGram = 0.obs;
  var lastDetectedAt = DateTime.now();

  double get sugarTeaspoon => sugarGram.value / 4.0;

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  bool isDetecting = false;
  int? _lastDetectedValue;
  SnackbarController? _snackbar;

  @override
  void onInit() {
    super.onInit();
    initCamera();
  }

  @override
  void onClose() {
    cameraController.dispose();
    textRecognizer.close();
    super.onClose();
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await cameraController.initialize();
    isCameraInitialized.value = true;
  }

  Future<void> triggerDetection() async {
    if (!cameraController.value.isInitialized || isDetecting) return;

    isDetecting = true;
    try {
      final XFile file = await cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await textRecognizer.processImage(inputImage);

      recognizedText.value = result.text;
      print('[DEBUG OCR TEXT]:\n${result.text}');
      extractSugar(result.text);
    } catch (e) {
      print("OCR Error: $e");
    }
    isDetecting = false;
  }

  void extractSugar(String text) {
    final lines = text.split('\n').map((e) => e.toLowerCase().trim()).toList();
    int? detectedSugar;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (line.contains('gula') || line.contains('sugar')) {
        print('🔍 Checking line: $line');

        // Cari angka di baris gula itu sendiri
        final sameLineMatch = RegExp(r'(\d+)\s*g').firstMatch(line);
        if (sameLineMatch != null) {
          detectedSugar = int.tryParse(sameLineMatch.group(1)!);
          break;
        }

        // Cek 3 baris setelah dan sebelum
        for (int j = 1; j <= 3; j++) {
          for (int offset in [-j, j]) {
            final nearbyIndex = i + offset;
            if (nearbyIndex >= 0 && nearbyIndex < lines.length) {
              print('🔍 Checking line: ${lines[nearbyIndex]}');
              final match = RegExp(r'(\d+)\s*g').firstMatch(lines[nearbyIndex]);
              if (match != null) {
                detectedSugar = int.tryParse(match.group(1)!);
                break;
              }
            }
          }
          if (detectedSugar != null) break;
        }
      }
      if (detectedSugar != null) break;
    }

    if (detectedSugar != null) {
      _updateSugarIfChanged(detectedSugar);
    } else if (DateTime.now().difference(lastDetectedAt).inSeconds > 5) {
      sugarGram.value = 0;
    }
  }

  void _updateSugarIfChanged(int newValue) {
    print('🚀 Gula baru terdeteksi: $newValue gram');
    if (_lastDetectedValue != newValue) {
      _lastDetectedValue = newValue;
      sugarGram.value = newValue;
      lastDetectedAt = DateTime.now();

      _snackbar?.close();
      _snackbar = Get.snackbar(
        "Gula Terdeteksi",
        "$newValue gram gula (≈ ${sugarTeaspoon.toStringAsFixed(2)} sdt)",
        backgroundColor: Colors.green.shade100,
        colorText: Colors.black,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final result = await textRecognizer.processImage(inputImage);
      recognizedText.value = result.text;
      extractSugar(result.text);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses gambar galeri: $e');
    }
  }
}
