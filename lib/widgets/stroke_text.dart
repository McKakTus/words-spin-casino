import 'package:flutter/material.dart';

class StrokeText extends StatelessWidget {
  const StrokeText({
    super.key,
    required this.text,
    this.fontSize = 32,
    this.strokeColor = const Color(0xFFD8D5EA),
    this.fillColor = Colors.white,
    this.strokeWidth = 4,
    this.shadowColor = const Color(0xFF46557B),
    this.shadowBlurRadius = 2,
    this.shadowOffset = const Offset(0, 2),
    this.textAlign,
    this.maxLines = 1,
    this.overflow,
    this.height,
  });

  final String text;
  final double fontSize;
  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;
  final Color shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = TextStyle(
      inherit: false,
      fontSize: fontSize,
      fontFamily: 'Cookies',
      height: height,
      decoration: TextDecoration.none,
    );

    return Stack(
      children: [
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
          style: baseStyle.copyWith(
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeWidth
              ..color = strokeColor,
          ),
        ),
        Text(
          text,
          maxLines: maxLines,
          overflow: overflow,
          textAlign: textAlign,
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
      ],
    );
  }
}
