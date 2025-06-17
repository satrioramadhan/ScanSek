import 'dart:async';
import 'dart:io';
import 'package:scan_sek/app/utils/snackbar_helper.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

class OcrController extends GetxController {
  // Konstanta untuk deteksi
  static const double TOLERANSI_GARIS_BANTU = 10.0; // Diperbesar dari 25
  static const double TOLERANSI_BARIS_SAMA = 40.0; // Diperbesar dari 100
  static const double JARAK_MINIMUM_KANAN = 15.0; // Diperkecil dari 40
  static const double GRAM_MINIMUM = 0.5;
  static const double GRAM_MAKSIMUM = 50.0; // Diperkecil dari 100

  late CameraController cameraController;
  var isCameraInitialized = false.obs;
  var recognizedText = ''.obs;
  var currentTeaspoonText = ''.obs;
  var sugarGram = 0.0.obs;
  var guideRect = Rect.zero.obs;
  var isCustomRectActive = false.obs;

  var previewSize = Size.zero;
  int previousGram = 0;

  double get sugarTeaspoon => sugarGram.value / 4.0;

  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  bool isDetecting = false;

  var highlightRects = <Rect>[].obs;
  var spoonImages = <String>[].obs;

  // Regexuntuk gula
  final sugarRegex = RegExp(
    r'\b(gula(\s*total)?|sugar|sugars|gula/sugars)\b',
    caseSensitive: false,
  );

  // Regex untuk gram
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

  Future<void> triggerDetection({
    bool fromGuide = false,
    bool fromCustomRect = false,
  }) async {
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

        if (fromCustomRect) {
          await _extractSugarFromCustomRect(
              result.blocks, guideRect.value, previewSize);
        } else {
          await _extractSugarAutomatic(result.blocks, previewSize);
        }
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
    _resetDetection();

    final screenSize = Get.size;
    final transformData =
        _calculateTransformation(originalImageSize, screenSize);
    final allLines = _extractAllLines(blocks);

    // Strategi 1: Cari kata "gula" dan angka dalam baris yang sama
    if (await _findSugarInSameLine(allLines, transformData)) return;

    // Strategi 2: Cari kata "gula" dan angka di baris berikutnya
    if (await _findSugarInNextLine(allLines, transformData)) return;

    // Strategi 3: Cari kata "gula" dan angka terdekat di sebelah kanan
    if (await _findSugarNearby(allLines, transformData)) return;

    // Fallback terakhir: cari angka gram yang valid walau tanpa kata gula
    if (await _fallbackFindAnyGram(allLines, transformData)) return;
    _showErrorSnackbar("Gula tidak terdeteksi, gunakan garis bantu");
  }

  Future<void> _extractSugarFromCustomRect(
      List<TextBlock> blocks, Rect customRect, Size originalImageSize) async {
    _resetDetection();

    final screenSize = Get.size;
    final transformData =
        _calculateTransformation(originalImageSize, screenSize);

    final imageRect = Rect.fromLTWH(
      customRect.left / transformData['scale']!,
      customRect.top / transformData['scale']!,
      customRect.width / transformData['scale']!,
      customRect.height / transformData['scale']!,
    );

    final allLines = _extractAllLines(blocks);
    final linesInRect = allLines.where((line) {
      final intersect = imageRect.intersect(line.boundingBox);
      final intersectArea = intersect.width * intersect.height;
      final lineArea = line.boundingBox.width * line.boundingBox.height;

      // 60% area masuk + center wajib dalam bingkai
      return intersectArea / lineArea >= 0.5 &&
          imageRect.contains(line.boundingBox.center);
    }).toList();

    if (await _findSugarInSameLine(linesInRect, transformData)) return;
    if (await _findSugarNearby(linesInRect, transformData)) return;

    _showErrorSnackbar("Gagal deteksi dalam area khusus");
  }

  // === UTILITY METHODS ===

  void _resetDetection() {
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

            // Cek apakah dalam baris yang sama dan di sebelah kanan
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

    // Highlight semua line yang terkait
    for (final line in lines) {
      highlightRects.add(_transformRect(line.boundingBox,
          transformData['scale']!, transformData['dx']!, transformData['dy']!));
    }

    _generateSpoons(value);

    // Tampilkan notifikasi sukses
    SnackbarHelper.show(
      "Gula Terdeteksi",
      "${value.toStringAsFixed(1)}g = ${(value / 4).toStringAsFixed(1)} sdt",
      type: "success",
    );
  }

  Rect _transformRect(Rect rect, double scale, double dx, double dy) {
    const offsetY = 5.0; // Naikkan highlight sedikit
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

    // Tambahkan gambar sendok
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
