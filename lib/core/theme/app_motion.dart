import 'package:flutter/material.dart';

/// Centralized motion and interaction physics for ShareNest.
/// Do NOT hard-code durations or curves in the UI. Always use these presets
/// to ensure the app feels like ONE cohesive premium experience.
class AppMotion {
  // ---------------------------------------------------------------------------
  // DURATIONS
  // ---------------------------------------------------------------------------
  
  /// Extremely fast transitions (e.g. icon toggles, color shifts, button presses)
  static const Duration fast = Duration(milliseconds: 150);

  /// Standard transitions (e.g. bottom sheets, dialogs, simple expansions)
  static const Duration normal = Duration(milliseconds: 300);

  /// Slow transitions for emphasis (e.g. page routing, large morphs, success states)
  static const Duration slow = Duration(milliseconds: 500);

  /// Very slow transitions (e.g. splash choreography, parallax background shifts)
  static const Duration splash = Duration(milliseconds: 1200);

  // ---------------------------------------------------------------------------
  // CURVES (For non-spring animations)
  // ---------------------------------------------------------------------------
  
  /// Standard easing for elements entering the screen
  static const Curve emphasizeDecelerate = Curves.easeOutCubic;

  /// Standard easing for elements exiting the screen
  static const Curve emphasizeAccelerate = Curves.easeInCubic;

  /// Smooth general purpose easing
  static const Curve smooth = Curves.fastOutSlowIn;

  // ---------------------------------------------------------------------------
  // SPRINGS (For physics-based animations)
  // ---------------------------------------------------------------------------

  /// Bouncy, low stiffness. Good for playful micro-interactions (e.g., map markers, success badges).
  static final SpringDescription softSpring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 100.0,
    ratio: 0.5,
  );

  /// Balanced spring. Good for cards, lists, bottom sheets. Feels natural and physical.
  static final SpringDescription standardSpring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 250.0,
    ratio: 0.75,
  );

  /// Snappy, high stiffness. Good for quick, purposeful interactions (e.g., Urgent Need).
  static final SpringDescription emphasizedSpring = SpringDescription.withDampingRatio(
    mass: 1.0,
    stiffness: 400.0,
    ratio: 0.9,
  );
}
