import 'dart:io';

import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';


class OcrController extends GetxController {
  late CameraController cameraController;
  var isCameraInitialized = false.obs;
  var recognizedText = ''.obs;
  var sugarGram = 0.obs;
  

  double get sugarTeaspoon => sugarGram.value / 4.0;

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

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
    cameraController = CameraController(cameras.first, ResolutionPreset.medium);
    await cameraController.initialize();
    isCameraInitialized.value = true;
  }

  /// Fungsi untuk ambil gambar dari kamera dan proses OCR-nya
  Future<void> captureAndRecognizeText() async {
    try {
      final XFile picture = await cameraController.takePicture();

      // Proses OCR
      final inputImage = InputImage.fromFilePath(picture.path);
      final RecognizedText result = await textRecognizer.processImage(inputImage);

      recognizedText.value = result.text;
      extractSugar(result.text);
    } catch (e) {
      Get.snackbar('Error', 'Gagal ambil gambar: $e');
    }
  }

  void extractSugar(String text) {
    final regex = RegExp(r'(gula|sugar|糖|suiker)\s*[:：]?\s*(\d+)', caseSensitive: false);
    final match = regex.firstMatch(text);

    if (match != null) {
      sugarGram.value = int.parse(match.group(2)!);
    } else {
      sugarGram.value = 0;
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText result = await textRecognizer.processImage(inputImage);

      recognizedText.value = result.text;
      extractSugar(result.text);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memproses gambar galeri: $e');
    }
  }
}
