import 'package:flutter/material.dart';

import 'stroke_text.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.busy = false,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(vertical: 18),
    this.textStyle,
    this.borderRadius = 34,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.borderColor = const Color(0xFFD8D5EA),
    this.disabledBorderColor = const Color(0x669E9E9E),
    this.shadowColor = const Color(0xFF46557B),
    this.backgroundGradient,
    this.uppercase = true,
  }) : assert(
          label != null || child != null,
          'Either label or child must be provided.',
        );

  final Object? label;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool busy;
  final bool enabled;
  final EdgeInsets padding;
  final TextStyle? textStyle;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final Color shadowColor;
  final Color disabledBorderColor;
  final Gradient? backgroundGradient;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    final bool canTap = enabled && !busy && onPressed != null;
    final Color effectiveBorder = canTap ? borderColor : disabledBorderColor;
    final Color baseFillColor = textStyle?.color ?? Colors.white54;
    final Color textFillColor = canTap
        ? baseFillColor
        : baseFillColor.withOpacity(0.6);

    final String? displayLabel = label is String
        ? (uppercase ? (label as String).toUpperCase() : label as String)
        : null;
    final Widget? effectiveChild = child ??
        (label is Widget ? label as Widget : null);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: canTap ? 1 : 0.6,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: canTap ? onPressed : null,
          child: Ink(
            width: double.infinity,
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundGradient == null ? backgroundColor : null,
              gradient: backgroundGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border(
                bottom: BorderSide(color: effectiveBorder, width: 5),
              ),
            ),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF46557B)),
                      ),
                    )
                  : effectiveChild ??
                      StrokeText(
                        text: displayLabel ?? '',
                        fontSize: textStyle?.fontSize ?? 26,
                        strokeColor: effectiveBorder,
                        fillColor: textFillColor,
                        shadowColor: shadowColor,
                        textAlign: TextAlign.center,
                      ),
            ),
          ),
        ),
      ),
    );
  }
}
