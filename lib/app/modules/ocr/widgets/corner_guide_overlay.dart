import 'package:flutter/material.dart';

class CornerGuideOverlay extends StatelessWidget {
  final Rect guideRect;

  const CornerGuideOverlay({Key? key, required this.guideRect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.infinite,
      painter: _CornerPainter(guideRect),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Rect rect;
  final Paint cornerPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  _CornerPainter(this.rect);

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerLength = 20;

    final corners = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final isLeft = (i == 0 || i == 2);
      final isTop = (i == 0 || i == 1);

      final hEnd = corner.translate(isLeft ? cornerLength : -cornerLength, 0);
      final vEnd = corner.translate(0, isTop ? cornerLength : -cornerLength);

      canvas.drawLine(corner, hEnd, cornerPaint);
      canvas.drawLine(corner, vEnd, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) =>
      oldDelegate.rect != rect;
}
