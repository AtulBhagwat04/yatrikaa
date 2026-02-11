import 'package:flutter/material.dart';

class RouteUtils {
  RouteUtils._();

  //Fade Transition
  static Route fadeRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }
  static Route slideFadeRoute({
    required Widget page,
    Duration duration = const Duration(milliseconds: 600),
    Offset begin = const Offset(0.0, 0.1),
  }) {
    return PageRouteBuilder(
      transitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(tween),
            child: child,
          ),
        );
      },
    );
  }
}
