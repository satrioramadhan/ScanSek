import 'package:flutter/material.dart';

class AnimatedCornerGuideOverlay extends StatelessWidget {
  final Rect guideRect;
  final Duration duration;

  const AnimatedCornerGuideOverlay({
    Key? key,
    required this.guideRect,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned.fromRect(
      duration: duration,
      rect: guideRect,
      child: CustomPaint(
        size: Size(guideRect.width, guideRect.height),
        painter: _CornerPainter(),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Paint cornerPaint = Paint()
    ..color = Colors.white
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    const double cornerLength = 20;

    final corners = [
      Offset(0, 0),
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
