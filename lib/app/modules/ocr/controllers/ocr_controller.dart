import 'dart:async';
import 'dart:io';
import 'package:scan_sek/app/utils/snackbar_helper.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

enum OcrMode { capture, fotoLabel }

class OcrController extends GetxController {
  static const double GRAM_MINIMUM = 0.5;
  static const double GRAM_MAKSIMUM = 50.0;

  late CameraController cameraController;
  var isCameraInitialized = false.obs;
  var recognizedText = ''.obs;
  var currentTeaspoonText = ''.obs;
  var sugarGram = 0.0.obs;
  var isCapturing = false.obs;
  var previewSize = Size.zero;

  var currentMode = OcrMode.capture.obs;
  var capturedImage = Rx<File?>(null);
  var isPhotoMode = false.obs;

  double get sugarTeaspoon => sugarGram.value / 4.0;

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool isDetecting = false;

  var highlightRects = <Rect>[].obs;
  var spoonImages = <String>[].obs;

  final sugarRegex = RegExp(
    r'\b(gula(\s*total)?|sugar|sugars|gula/sugars)\b',
    caseSensitive: false,
  );

  final gramRegex = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(?:g|gram|grams?)\b',
    caseSensitive: false,
  );

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

  void togglePhotoMode() {
    isPhotoMode.value = !isPhotoMode.value;
    resetDetection();
  }

  Future<void> handleMainButton() async {
    isPhotoMode.value ? await captureAndShowResult() : await captureImage();
  }

  String getMainButtonText() => isCapturing.value
      ? "Memproses..."
      : isPhotoMode.value
          ? "Ambil Foto Label"
          : "Deteksi";

  IconData getMainButtonIcon() => isCapturing.value
      ? Icons.hourglass_empty
      : isPhotoMode.value
          ? Icons.image_search
          : Icons.search;

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(cameras.first, ResolutionPreset.high,
          enableAudio: false);
      await cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      _showErrorSnackbar("Gagal membuka kamera");
    }
  }

  Future<void> captureImage() async {
    if (!cameraController.value.isInitialized || isCapturing.value) return;

    isCapturing.value = true;
    try {
      await triggerDetection();
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> captureAndShowResult() async {
    if (!cameraController.value.isInitialized || isCapturing.value) return;

    isCapturing.value = true;
    try {
      final XFile file = await cameraController.takePicture();
      capturedImage.value = File(file.path);

      final inputImage = InputImage.fromFilePath(file.path);
      final result = await textRecognizer.processImage(inputImage);

      final bytes = await File(file.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        // ✅ Koreksi orientasi ukuran gambar dari landscape ke portrait
        previewSize = Size(
          decodedImage.height.toDouble(), // tukar height ke width
          decodedImage.width.toDouble(), // tukar width ke height
        );
        await _extractSugarAutomatic(result.blocks, previewSize);
        recognizedText.value = result.text;
        currentMode.value = OcrMode.fotoLabel;
      }
    } catch (e) {
      _showErrorSnackbar("Gagal memproses gambar");
    } finally {
      isCapturing.value = false;
    }
  }

  Future<void> triggerDetection() async {
    if (!cameraController.value.isInitialized || isDetecting) return;

    isDetecting = true;
    try {
      final XFile file = await cameraController.takePicture();
      final inputImage = InputImage.fromFilePath(file.path);
      final result = await textRecognizer.processImage(inputImage);

      final bytes = await File(file.path).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage != null) {
        previewSize = Size(
          decodedImage.height.toDouble(),
          decodedImage.width.toDouble(),
        );
        await _extractSugarAutomatic(result.blocks, previewSize);
      }
      recognizedText.value = result.text;
    } catch (e) {
      _showErrorSnackbar("Gagal memproses gambar");
    } finally {
      isDetecting = false;
    }
  }

  Future<void> _extractSugarAutomatic(
      List<TextBlock> blocks, Size originalImageSize) async {
    resetDetection();

    // PENTING: Tukar width & height karena orientasi kamera berbeda dengan layar
    final correctedImageSize =
        Size(originalImageSize.height, originalImageSize.width);

    final transformData =
        _calculateTransformation(correctedImageSize, Get.size);
    final allLines = blocks.expand((block) => block.lines).toList();

    if (await _findSugarStrictlyRight(allLines, transformData)) return;
    _showErrorSnackbar("Gula tidak terdeteksi");
  }

  void resetDetection() {
    highlightRects.clear();
    spoonImages.clear();
    sugarGram.value = 0.0;
  }

  Map<String, double> _calculateTransformation(
      Size originalImageSize, Size screenSize) {
    final originalAspect = originalImageSize.width / originalImageSize.height;
    final screenAspect = screenSize.width / screenSize.height;

    double scale;
    double dx = 0;
    double dy = 0;

    if (originalAspect > screenAspect) {
      scale = screenSize.width / originalImageSize.width;
      final scaledHeight = originalImageSize.height * scale;
      dy = (scaledHeight - screenSize.height) / 2;
    } else {
      scale = screenSize.height / originalImageSize.height;
      final scaledWidth = originalImageSize.width * scale;
      dx = (scaledWidth - screenSize.width) / 2;
    }

    return {'scale': scale, 'dx': dx, 'dy': dy};
  }

  Future<bool> _findSugarStrictlyRight(
      List<TextLine> lines, Map<String, double> transformData) async {
    for (final sugarLine in lines
        .where((line) => sugarRegex.hasMatch(line.text.toLowerCase()))) {
      final sugarCenter = sugarLine.boundingBox.center;

      TextLine? closestGramLine;
      double closestDistance = double.infinity;

      for (final line in lines) {
        if (line == sugarLine) continue;
        final gramMatch = gramRegex.firstMatch(line.text.toLowerCase());
        if (gramMatch == null) continue;

        final gramCenter = line.boundingBox.center;

        // Pastikan gram ada di kanan gula
        if (gramCenter.dx <= sugarCenter.dx) continue;

        // Hitung jarak diagonal (Euclidean)
        final distance = (gramCenter - sugarCenter).distance;

        if (distance < closestDistance) {
          closestDistance = distance;
          closestGramLine = line;
        }
      }

      if (closestGramLine != null) {
        final match = gramRegex.firstMatch(closestGramLine.text.toLowerCase());
        final value =
            double.tryParse(match?.group(1)?.replaceAll(',', '.') ?? '');
        if (value != null && value >= GRAM_MINIMUM && value <= GRAM_MAKSIMUM) {
          await _setSugarValue(
              value, [sugarLine, closestGramLine], transformData);
          return true;
        }
      }
    }
    return false;
  }

  Rect _transformRect(Rect rect, double scale, double dx, double dy) {
    return Rect.fromLTWH(
      rect.left * scale - dx,
      rect.top * scale - dy,
      rect.width * scale,
      rect.height * scale,
    );
  }

  Future<void> _setSugarValue(double value, List<TextLine> lines,
      Map<String, double> transformData) async {
    sugarGram.value = value;
    highlightRects.assignAll(lines.map((line) => _transformRect(
        line.boundingBox,
        transformData['scale']!,
        transformData['dx']!,
        transformData['dy']!)));

    _generateSpoons(value);

    SnackbarHelper.show(
      "Gula Terdeteksi",
      "${value}g = ${(value / 4).toStringAsFixed(1)} sdt",
      type: "success",
    );
  }

  void _generateSpoons(double gram) {
    spoonImages.clear();

    int fullCount = gram ~/ 4;
    double sisa = gram - (fullCount * 4);

    int seper2Count = 0;
    int seper4Count = 0;

    if (sisa >= 2) {
      seper2Count = 1;
      sisa -= 2;
    }

    if (sisa >= 1) {
      seper4Count = 1;
      sisa -= 1;
    }

    if (sisa > 0) {
      seper4Count += 1;
    }

    for (int i = 0; i < fullCount; i++) {
      spoonImages.add('assets/images/full_sdt.png');
    }
    for (int i = 0; i < seper2Count; i++) {
      spoonImages.add('assets/images/seper2_sdt.png');
    }
    for (int i = 0; i < seper4Count; i++) {
      spoonImages.add('assets/images/seper4_sdt.png');
    }

    double sdt = gram / 4.0;
    currentTeaspoonText.value =
        "= ${sdt.toStringAsFixed(1)} sdt (${gram.toStringAsFixed(1)} gram)";
  }

  void _showErrorSnackbar(String message) {
    SnackbarHelper.show("Error", message, type: "error");
  }
}
