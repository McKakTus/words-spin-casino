import 'package:flutter/material.dart';

class StrokeIcon extends StatelessWidget {
  const StrokeIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.fillColor = Colors.white,
    this.strokeColor = const Color(0xFFD8D5EA),
    this.strokeWidth = 4,
    this.shadowColor = const Color(0xFF46557B),
    this.shadowBlurRadius = 2,
    this.shadowOffset = const Offset(0, 2),
  });

  final IconData icon;
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _StrokeIconPainter(
          icon: icon,
          iconSize: size,
          fillColor: fillColor,
          strokeColor: strokeColor,
          strokeWidth: strokeWidth,
          shadowColor: shadowColor,
          shadowBlurRadius: shadowBlurRadius,
          shadowOffset: shadowOffset,
          textDirection: textDirection,
        ),
      ),
    );
  }
}

class _StrokeIconPainter extends CustomPainter {
  _StrokeIconPainter({
    required this.icon,
    required this.iconSize,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.shadowColor,
    required this.shadowBlurRadius,
    required this.shadowOffset,
    required this.textDirection,
  });

  final IconData icon;
  final double iconSize;
  final Color fillColor;
  final Color strokeColor;
  final double strokeWidth;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final String glyph = String.fromCharCode(icon.codePoint);

    final TextStyle baseStyle = TextStyle(
      inherit: false,
      fontSize: iconSize,
      fontFamily: icon.fontFamily,
      fontFamilyFallback: icon.fontFamilyFallback,
      package: icon.fontPackage,
      height: 1.0,
      leadingDistribution: TextLeadingDistribution.even,
    );

    final TextPainter strokePainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: baseStyle.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = strokeWidth
            ..color = strokeColor,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final TextPainter fillPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: baseStyle.copyWith(
          color: fillColor,
          shadows: [
            Shadow(
              color: shadowColor,
              blurRadius: shadowBlurRadius,
              offset: shadowOffset,
            ),
          ],
        ),
      ),
      textDirection: textDirection,
    )..layout();

    final double dx = (size.width - strokePainter.width) / 2;
    final double dy = (size.height - strokePainter.height) / 2;
    final Offset offset = Offset(dx, dy);

    strokePainter.paint(canvas, offset);
    fillPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _StrokeIconPainter oldDelegate) {
    return icon != oldDelegate.icon ||
        iconSize != oldDelegate.iconSize ||
        fillColor != oldDelegate.fillColor ||
        strokeColor != oldDelegate.strokeColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        shadowColor != oldDelegate.shadowColor ||
        shadowBlurRadius != oldDelegate.shadowBlurRadius ||
        shadowOffset != oldDelegate.shadowOffset ||
        textDirection != oldDelegate.textDirection;
  }
}
