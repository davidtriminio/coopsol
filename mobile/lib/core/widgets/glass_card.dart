import 'dart:ui';

import 'package:coopsol_mobile/core/theme/glass_tokens.dart';
import 'package:flutter/cupertino.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  static final ImageFilter _backdrop = ImageFilter.compose(
      outer: const ColorFilter.matrix(_saturate),
      inner: ImageFilter.blur(sigmaX: 20, sigmaY: 20)
  );

  static const List<double> _saturate = [
    1.6296, -0.572, -0.0576, 0, 0,
    -0.1704, 1.228, -0.0576, 0, 0,
    -0.1704, -0.572, 1.7424, 0, 0,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = GlassTokens.of(context);
    final borderRadius = BorderRadius.circular(radius);
    
    return CustomPaint(
      painter: _OuterShadowPainter(color: tokens.cardShadow, radius: radius),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: _backdrop,
          child: DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.cardBackground,
                borderRadius: borderRadius,
                border: Border.all(color: tokens.cardBorder)
              ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

class _OuterShadowPainter extends CustomPainter{
  const _OuterShadowPainter({required this.color, required this.radius});
  
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius)
    );
    final outside = Path.combine(
        PathOperation.difference,
        Path() ..addRect(Rect.fromLTRB(-200, -200, size.width + 200, size.height + 200)),
        Path() ..addRRect(card)
    );

    canvas.save();
    canvas.clipPath(outside);
    canvas.drawRRect(
    card.shift(const Offset(0, 8)),
      Paint()
        ..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OuterShadowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
  
}