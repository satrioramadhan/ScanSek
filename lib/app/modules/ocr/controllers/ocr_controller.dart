// ocr_controller.dart dengan mode switch yang lebih clean

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
  static const double TOLERANSI_BARIS_SAMA = 40.0;
  static const double JARAK_MINIMUM_KANAN = 15.0;
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
  var isPhotoMode = false.obs; // ✅ Tambahan untuk switch mode foto

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

  // ✅ Method untuk toggle mode
  void togglePhotoMode() {
    isPhotoMode.value = !isPhotoMode.value;
    resetDetection(); // Reset deteksi saat ganti mode
  }

  // ✅ Method untuk handle button utama (Deteksi/Ambil Foto Label)
  Future<void> handleMainButton() async {
    if (isPhotoMode.value) {
      await captureAndShowResult();
    } else {
      await captureImage();
    }
  }

  // ✅ Method untuk get text button berdasarkan mode
  String getMainButtonText() {
    if (isCapturing.value) return "Memproses...";
    return isPhotoMode.value ? "Ambil Foto Label" : "Deteksi";
  }

  // ✅ Method untuk get icon button berdasarkan mode
  IconData getMainButtonIcon() {
    if (isCapturing.value) return Icons.hourglass_empty;
    return isPhotoMode.value ? Icons.image_search : Icons.search;
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await cameraController.initialize();
      isCameraInitialized.value = true;
    } catch (e) {
      print("❌ Error initializing camera: $e");
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
        previewSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
        await _extractSugarAutomatic(result.blocks, previewSize);
        recognizedText.value = result.text;
        currentMode.value = OcrMode.fotoLabel;
      }
    } catch (e) {
      print("❌ Error OCR fotoLabel: $e");
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
          cameraController.value.previewSize!.height,
          cameraController.value.previewSize!.width,
        );
        await _extractSugarAutomatic(result.blocks, previewSize);
      }

      recognizedText.value = result.text;
    } catch (e) {
      print("❌ OCR Error: $e");
      _showErrorSnackbar("Gagal memproses gambar");
    } finally {
      isDetecting = false;
    }
  }

  Future<void> _extractSugarAutomatic(
      List<TextBlock> blocks, Size originalImageSize) async {
    resetDetection();

    final screenSize = Get.size;
    final transformData =
        _calculateTransformation(originalImageSize, screenSize);
    final allLines = _extractAllLines(blocks);

    if (await _findSugarInSameLine(allLines, transformData)) return;
    if (await _findSugarInNextLine(allLines, transformData)) return;
    if (await _findSugarNearby(allLines, transformData)) return;
    if (await _fallbackFindAnyGram(allLines, transformData)) return;
    _showErrorSnackbar("Gula tidak terdeteksi");
  }

  void resetDetection() {
    highlightRects.clear();
    spoonImages.clear();
    sugarGram.value = 0.0;
  }

  Map<String, double> _calculateTransformation(
      Size originalImageSize, Size screenSize) {
    final imageAspectRatio = originalImageSize.height / originalImageSize.width;
    final screenAspectRatio = screenSize.height / screenSize.width;

    double scale;
    double dx = 0;
    double dy = 0;

    if (imageAspectRatio > screenAspectRatio) {
      scale = screenSize.width / originalImageSize.width;
      final fittedHeight = originalImageSize.height * scale;
      dy = (fittedHeight - screenSize.height) / 2;
    } else {
      scale = screenSize.height / originalImageSize.height;
      final fittedWidth = originalImageSize.width * scale;
      dx = (fittedWidth - screenSize.width) / 2;
    }

    return {'scale': scale, 'dx': dx, 'dy': dy};
  }

  List<TextLine> _extractAllLines(List<TextBlock> blocks) {
    final allLines = <TextLine>[];
    for (final block in blocks) {
      allLines.addAll(block.lines);
    }
    return allLines;
  }

  Future<bool> _findSugarInSameLine(
      List<TextLine> lines, Map<String, double> transformData) async {
    for (final line in lines) {
      final text = line.text.toLowerCase();
      if (sugarRegex.hasMatch(text) && gramRegex.hasMatch(text)) {
        final match = gramRegex.firstMatch(text);
        if (match != null) {
          final value =
              double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
          if (_isValidSugarValue(value)) {
            await _setSugarValue(value, [line], transformData);
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<bool> _findSugarInNextLine(
      List<TextLine> lines, Map<String, double> transformData) async {
    for (int i = 0; i < lines.length - 1; i++) {
      final current = lines[i];
      final next = lines[i + 1];

      if (sugarRegex.hasMatch(current.text.toLowerCase())) {
        final match = gramRegex.firstMatch(next.text.toLowerCase());
        if (match != null) {
          final value =
              double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
          if (_isValidSugarValue(value)) {
            await _setSugarValue(value, [current, next], transformData);
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<bool> _findSugarNearby(
      List<TextLine> lines, Map<String, double> transformData) async {
    for (final sugarLine in lines) {
      if (sugarRegex.hasMatch(sugarLine.text.toLowerCase())) {
        final sugarX = sugarLine.boundingBox.center.dx;
        final sugarY = sugarLine.boundingBox.center.dy;

        for (final gramLine in lines) {
          if (gramLine == sugarLine) continue;

          final match = gramRegex.firstMatch(gramLine.text.toLowerCase());
          if (match != null) {
            final gramX = gramLine.boundingBox.center.dx;
            final gramY = gramLine.boundingBox.center.dy;

            final yDiff = (sugarY - gramY).abs();
            final xDiff = gramX - sugarX;

            if (yDiff < TOLERANSI_BARIS_SAMA && xDiff > JARAK_MINIMUM_KANAN) {
              final value =
                  double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
              if (_isValidSugarValue(value)) {
                await _setSugarValue(
                    value, [sugarLine, gramLine], transformData);
                return true;
              }
            }
          }
        }
      }
    }
    return false;
  }

  Future<bool> _fallbackFindAnyGram(
      List<TextLine> lines, Map<String, double> transformData) async {
    for (final line in lines) {
      final match = gramRegex.firstMatch(line.text.toLowerCase());
      if (match != null) {
        final value =
            double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
        if (_isValidSugarValue(value)) {
          await _setSugarValue(value, [line], transformData);
          return true;
        }
      }
    }
    return false;
  }

  bool _isValidSugarValue(double value) {
    return value >= GRAM_MINIMUM && value <= GRAM_MAKSIMUM;
  }

  Future<void> _setSugarValue(double value, List<TextLine> lines,
      Map<String, double> transformData) async {
    sugarGram.value = value;

    for (final line in lines) {
      highlightRects.add(_transformRect(line.boundingBox,
          transformData['scale']!, transformData['dx']!, transformData['dy']!));
    }

    _generateSpoons(value);

    SnackbarHelper.show(
      "Gula Terdeteksi",
      "${value.toStringAsFixed(1)}g = ${(value / 4).toStringAsFixed(1)} sdt",
      type: "success",
    );
  }

  Rect _transformRect(Rect rect, double scale, double dx, double dy) {
    const offsetY = 5.0;
    return Rect.fromLTWH(
      rect.left * scale - dx,
      rect.top * scale - dy - offsetY,
      rect.width * scale,
      rect.height * scale,
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
