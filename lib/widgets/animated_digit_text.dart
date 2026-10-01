import 'package:flutter/material.dart';

/// Smooth vertical slide number/text transition
class AnimatedSlideText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Duration duration;
  final bool slideUp;

  const AnimatedSlideText({
    super.key,
    required this.text,
    required this.style,
    this.duration = const Duration(milliseconds: 600),
    this.slideUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        final inOffset = slideUp
            ? const Offset(0.0, 0.6)
            : const Offset(0.0, -0.6);
        final outOffset = slideUp
            ? const Offset(0.0, -0.6)
            : const Offset(0.0, 0.6);

        final isIncoming = child.key == ValueKey(text);

        final slideAnimation = Tween<Offset>(
          begin: isIncoming ? inOffset : Offset.zero,
          end: isIncoming ? Offset.zero : outOffset,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        );

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        );

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      child: Text(
        text,
        key: ValueKey(text),
        style: style,
      ),
    );
  }
}
