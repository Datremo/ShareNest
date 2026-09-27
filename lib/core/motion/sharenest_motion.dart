import 'package:flutter/material.dart';

class ShareNestMotion {
  // Durations
  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 520);

  // Curves
  static const softSpring = SpringDescription(mass: 1, stiffness: 100, damping: 15);
  static const standardSpring = SpringDescription(mass: 1, stiffness: 200, damping: 20);
  static const emphasizedSpring = SpringDescription(mass: 1, stiffness: 300, damping: 25);

  // Reusable Transitions
  static Widget fadeSlide({required Widget child, required Animation<double> animation}) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }
}
