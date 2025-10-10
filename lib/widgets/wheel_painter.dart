import 'dart:math' as math;
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  WheelPainter({
    required this.labels
  });

  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / labels.length;
    final baseStart = -math.pi / 2 - segmentAngle / 2;

    // Draw segments
    const purpleSectionGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF7c158c),
        Color(0xFFa52ebd),
        Color(0xFF9337b6),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    const orangeSectionGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFe74d04),
        Color(0xFFf99c04),
        Color(0xFFf67a01),
      ],
      stops: [0.0, 0.5, 1.0],
    );

    for (var i = 0; i < labels.length; i++) {
      final startAngle = baseStart + i * segmentAngle;
      
      // Alternate gradients for segments
      final gradient = (i % 2 == 0) ? purpleSectionGradient : orangeSectionGradient;

      final segmentRect = Rect.fromCircle(center: center, radius: radius);
      final gradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(segmentRect);

      // Draw the segment
      canvas.drawArc(segmentRect, startAngle, segmentAngle, true, gradientPaint);

      // Draw thick black dividers
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Color(0xFF9ab1da)
        ..strokeWidth = 14.0;
      
      canvas.drawArc(segmentRect, startAngle, segmentAngle, true, borderPaint);

      // Draw text
      _drawSegmentText(
        canvas,
        labels[i],
        center,
        radius,
        startAngle + segmentAngle / 2,
      );
    }

    // Draw outer black border
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 8.0;
    
    canvas.drawCircle(center, radius - 4, outerBorderPaint);
  }

  void _drawSegmentText(
    Canvas canvas,
    String text,
    Offset center,
    double radius,
    double angle,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFFFFF),
          fontSize: 24,
          fontFamily: 'Cookies',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '...',  
    )..layout(maxWidth: radius * 0.6);

    final textRadius = radius * 0.65;
    final textCenter = Offset(
      center.dx + textRadius * math.cos(angle),
      center.dy + textRadius * math.sin(angle),
    );

    canvas.save();
    canvas.translate(textCenter.dx, textCenter.dy);
    
    canvas.rotate(angle);
    
    canvas.translate(-textPainter.width / 2, -textPainter.height / 2);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    if (oldDelegate.labels.length != labels.length) return true;
    for (var i = 0; i < labels.length; i++) {
      if (oldDelegate.labels[i] != labels[i]) return true;
    }
    return false;
  }
}