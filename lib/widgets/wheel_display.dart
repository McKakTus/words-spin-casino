import 'package:flutter/material.dart';

import '../helpers/image_paths.dart';

import 'wheel_painter.dart';

class WheelDisplay extends StatelessWidget {
  const WheelDisplay({
    super.key,
    required this.controller,
    required this.rotationAnimation,
    required this.currentRotation,
    required this.labels,
    this.onSpinPressed,
    this.enabled = true,
  });

  final AnimationController controller;
  final Animation<double>? rotationAnimation;
  final double currentRotation;
  final List<String> labels;
  final VoidCallback? onSpinPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) {
      return const SizedBox.shrink();
    }

    final double size = MediaQuery.of(context).size.width;
    final segmentCount = labels.length;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Color(0x4DFFD700), blurRadius: 30, spreadRadius: 10),
          BoxShadow(
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
                labels: List<String>.generate(
                  segmentCount,
                  (index) => _formatLabel(labels[index % labels.length]),
                ),
              ),
              child: SizedBox(width: size, height: size),
            ),
          ),

          // Pointer/Arrow at top
          Positioned(
            top: 0,
            child: SizedBox(
              width: 50,
              height: 50,
              child: Image.asset(
                Images.arrow,
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Center hub
          GestureDetector(
            onTap: enabled ? onSpinPressed : null,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: enabled ? 1 : 0.55,
              child: Container(
                width: size * 0.24,
                height: size * 0.24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const RadialGradient(
                    colors: [
                      Color(0xFF404040),
                      Color(0xFF2A2A2A),
                      Color(0xFF1A1A1A),
                    ],
                  ),
                  border: Border.all(color: const Color(0xFFffaf28), width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Text(
                  'SPIN',
                  style: TextStyle(
                    color: const Color(0xFFffaf28),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatLabel(String text) {
    const int limit = 10;
    final sanitized = text.replaceAll('\n', ' ').trim();
    if (sanitized.length <= limit) {
      return sanitized;
    }
    return '${sanitized.substring(0, limit - 1)}…';
  }
}
