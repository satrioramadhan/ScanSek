import 'package:flutter/material.dart';

class SugarHighlightPainter extends CustomPainter {
  final List<Rect> highlightRects;

  SugarHighlightPainter(this.highlightRects);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final rect in highlightRects) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
