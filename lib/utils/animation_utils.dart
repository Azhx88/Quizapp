import 'package:flutter/material.dart';

/// Returns a SlideTransition offset for wrong-answer horizontal shake.
Animation<Offset> buildShakeAnimation(AnimationController ctrl) {
  return Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0.05, 0),
  ).animate(
    CurvedAnimation(parent: ctrl, curve: Curves.elasticIn),
  );
}

/// Returns a ScaleTransition for correct-answer bounce.
Animation<double> buildBounceAnimation(AnimationController ctrl) {
  return TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 60),
  ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
}

/// Staggered delay for rank-card animations.
Duration staggerDelay(int index) =>
    Duration(milliseconds: 80 + index * 60);
