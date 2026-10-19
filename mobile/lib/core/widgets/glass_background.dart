import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/material.dart';

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: const Alignment(-0.342, -0940),
            end: const Alignment(0.342, 0.940),
            colors: [tokens.baseStart, tokens.baseEnd]
        ),
      ),
      child: CustomPaint(
        painter: _GlowPainter(top: tokens.glowTop, bottom: tokens.glowBottom),
        child: child,
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.top, required this.bottom});

  final Color top;
  final Color bottom;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGlow(
        canvas,
        size,
        const Offset(0.15, 0.10),
        1.2,
        0.9,
        top,
        0.55);
    _paintGlow(
        canvas,
        size,
        const Offset(0.90, 0.85),
        1.2,
        1.0,
        bottom,
        0.60);
  }


  void _paintGlow(Canvas canvas,
      Size size,
      Offset center,
      double radiusX,
      double radiusY,
      Color color,
      double fadeStop) {
    final origin = Offset(size.width * center.dx, size.height * center.dy);
    final scaleX = size.width * radiusX;
    final scaleY = size.height * radiusY;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withValues(alpha: 0)],
        stops: [0, fadeStop],
      ).createShader(Rect.fromCircle(center: Offset.zero, radius: 1));

    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scaleX, scaleY);
    canvas.drawRect(
      Rect.fromLTRB(
        -origin.dx / scaleX,
        -origin.dy / scaleY,
        (size.width - origin.dx) / scaleX,
        (size.height - origin.dy) / scaleY,
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_GlowPainter oldDelegate) {
    return oldDelegate.top != top || oldDelegate.bottom != bottom;
  }

}