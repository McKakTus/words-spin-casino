import 'package:flutter/material.dart';

import '../models/quiz_question.dart';
import '../helpers/image_paths.dart';

import 'wheel_painter.dart';

class WheelDisplay extends StatelessWidget {
  const WheelDisplay({
    super.key,
    required this.controller,
    required this.rotationAnimation,
    required this.currentRotation,
    required this.segments,
  });

  final AnimationController controller;
  final Animation<double>? rotationAnimation;
  final double currentRotation;
  final List<QuizQuestion> segments;

  static const _segmentCount = 8;

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 10,
          ),
          const BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main wheel
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              final angle = rotationAnimation?.value ?? currentRotation;
              return Transform.rotate(angle: angle, child: child);
            },
            child: CustomPaint(
              painter: WheelPainter(
                labels: List<String>.generate(_segmentCount, (index) {
                  final quiz = segments[index % segments.length];
                  final label = quiz.category?.toUpperCase() ?? 'QUIZ';
                  return _formatLabel(label);
                }),
              ),
              child: const SizedBox(width: 320, height: 320),
            ),
          ),
          
          // Pointer/Arrow at top
          Positioned(
            top: 0,
            child: SizedBox(
              width: 60,
              height: 60,
              child: Image.asset(Images.arrow,
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
          
          // Center hub
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFF404040),
                  Color(0xFF2A2A2A),
                  Color(0xFF1A1A1A),
                ],
              ),
              border: Border.all(
                color: const Color(0xFFFFD700),
                width: 3,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatLabel(String text) {
    const int limit = 12;
    final sanitized = text.replaceAll('\n', ' ').trim();
    if (sanitized.length <= limit) {
      return sanitized;
    }
    return '${sanitized.substring(0, limit - 1)}…';
  }
}