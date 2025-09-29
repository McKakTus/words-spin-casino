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
    for (var i = 0; i < labels.length; i++) {
      final startAngle = baseStart + i * segmentAngle;
      
      // Create a radial gradient from the dark center to the colored edge
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF2A2A2A), // Dark center
          const Color(0xFF1A1A1A), // Middle
          const Color(0xFFe58923), // Edge
        ],
        stops: const [0.0, 0.4, 1],
      );

      final segmentRect = Rect.fromCircle(center: center, radius: radius);
      final gradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(segmentRect);

      // Draw the segment
      canvas.drawArc(segmentRect, startAngle, segmentAngle, true, gradientPaint);

      // Draw thick black dividers
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 6.0;
      
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
          color: Color(0xFFfeb229),
          fontSize: 16,
          fontFamily: 'MightySouly',
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