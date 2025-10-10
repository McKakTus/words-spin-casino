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

    final double size = MediaQuery.of(context).size.width + 180;
    final segmentCount = labels.length;

    return SizedBox(
      width: size,
      height: size,
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

          // Outer ring
          Positioned.fill(
            child: Transform.scale(
              scale: 1.35,
              child: Image.asset(
                Images.wheelOuterRing,
                fit: BoxFit.fill,
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
                color: Colors.transparent, // полностью прозрачная, но кликабельная область
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
