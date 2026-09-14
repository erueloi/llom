import 'package:flutter/material.dart';

/// Widget que dibuixa el monograma oficial de 4 colors de Google (G)
/// sense dependències d'imatges ni fitxers externs.
class GoogleLogoWidget extends StatelessWidget {
  final double size;

  const GoogleLogoWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GoogleLogoPainter(),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final double strokeWidth = w * 0.20;
    final double radius = (w - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = true;

    // Vermell Google (arc superior esquerre)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -3.14159 * 0.76, 3.14159 * 0.52, false, paint);

    // Blau Google (arc superior dret i lateral)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -3.14159 * 0.24, 3.14159 * 0.48, false, paint);

    // Verd Google (arc inferior)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, 3.14159 * 0.24, 3.14159 * 0.52, false, paint);

    // Groc Google (arc inferior esquerre)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, 3.14159 * 0.76, 3.14159 * 0.48, false, paint);

    // Barra horitzontal blava cap al centre
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final barRect = Rect.fromLTRB(
      center.dx - 1,
      center.dy - (strokeWidth / 2),
      w - (strokeWidth / 2) + 1,
      center.dy + (strokeWidth / 2),
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
