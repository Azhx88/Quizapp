import 'package:flutter/services.dart';

class HapticUtils {
  static void correctAnswer() => HapticFeedback.lightImpact();
  static void wrongAnswer() => HapticFeedback.heavyImpact();
  static void buttonTap() => HapticFeedback.selectionClick();
  static void streakAchieved() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), HapticFeedback.mediumImpact);
  }
}
