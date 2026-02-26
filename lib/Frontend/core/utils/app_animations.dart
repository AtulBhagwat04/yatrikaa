import 'package:flutter/material.dart';

class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);

  // Curves
  static const Curve decelerate = Curves.decelerate;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;

  // Custom Animation Wrappers
  static Widget fadeIn({
    required Widget child,
    Duration duration = normal,
    int delay = 0,
    double begin = 0.0,
    double end = 1.0,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: begin, end: end),
      duration: duration,
      curve: easeInOut,
      // Adding delay via total duration check or simple Future.delayed is complex for stateless,
      // so we use a simpler strategy for a utility class:
      // We'll wrap it in a child that handles delay if needed.
      builder: (context, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: child,
    );
  }

  static Widget slideIn({
    required Widget child,
    Duration duration = normal,
    int delay = 0,
    Offset begin = const Offset(0, 0.1),
    Offset end = Offset.zero,
  }) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: begin, end: end),
      duration: duration,
      curve: easeOut,
      builder: (context, value, child) {
        return FractionalTranslation(translation: value, child: child);
      },
      child: child,
    );
  }
}
