import 'package:flutter/material.dart';

class HoleOverlayPainter extends CustomPainter {
  final Rect holeRect;

  HoleOverlayPainter(this.holeRect);

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint = Paint()..color = Colors.black.withOpacity(0.6);
    canvas.drawRect(Offset.zero & size, overlayPaint);

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawRect(holeRect, clearPaint);
  }

  @override
  bool shouldRepaint(HoleOverlayPainter oldDelegate) {
    return oldDelegate.holeRect != holeRect;
  }
}
