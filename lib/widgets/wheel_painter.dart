import 'dart:math' as math;
import 'package:flutter/material.dart';

class WheelPainter extends CustomPainter {
  WheelPainter({required this.labels});

  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final segmentAngle = (2 * math.pi) / labels.length;
    final baseStart = -math.pi / 2 - segmentAngle / 2;

    // Цвета для сегментов как на скриншоте
    final List<Color> segmentColors = [
      const Color(0xFF4A90E2), // Синий
      const Color(0xFFE74C3C), // Красный  
      const Color(0xFF2ECC71), // Зеленый
      const Color(0xFFF39C12), // Оранжевый
      const Color(0xFF9B59B6), // Фиолетовый
      const Color(0xFF1ABC9C), // Бирюзовый
      const Color(0xFFE91E63), // Розовый
      const Color(0xFF795548), // Коричневый
    ];

    // Рисуем сегменты
    for (var i = 0; i < labels.length; i++) {
      final startAngle = baseStart + i * segmentAngle;
      final segmentColor = segmentColors[i % segmentColors.length];
      
      // Создаем радиальный градиент от темного центра к цветному краю
      final gradient = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          const Color(0xFF2A2A2A), // Темный центр
          const Color(0xFF1A1A1A), // Средний
          segmentColor.withOpacity(0.8), // Цветной край
        ],
        stops: const [0.0, 0.6, 1.0],
      );

      final segmentRect = Rect.fromCircle(center: center, radius: radius);
      final gradientPaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = gradient.createShader(segmentRect);

      // Рисуем сегмент
      canvas.drawArc(segmentRect, startAngle, segmentAngle, true, gradientPaint);

      // Рисуем толстые черные разделители
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = Colors.black
        ..strokeWidth = 6.0;
      
      canvas.drawArc(segmentRect, startAngle, segmentAngle, true, borderPaint);

      // Рисуем текст
      _drawSegmentText(
        canvas,
        labels[i],
        center,
        radius,
        startAngle + segmentAngle / 2,
      );
    }

    // Рисуем внешнюю черную обводку
    final outerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = 8.0;
    
    canvas.drawCircle(center, radius - 4, outerBorderPaint);

    // Рисуем белый центральный круг
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    
    canvas.drawCircle(center, radius * 0.25, centerPaint);

    // Черная обводка центрального круга
    final centerBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.black;
    
    canvas.drawCircle(center, radius * 0.25, centerBorderPaint);
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
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'MightySouly',
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: radius * 0.4);

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