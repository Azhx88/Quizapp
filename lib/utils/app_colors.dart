import 'package:flutter/material.dart';

/// Central color palette — matches stitch reference screens exactly.
/// Do NOT use Material defaults or ad-hoc colors anywhere.
class AppColors {
  AppColors._();

  // ─── Backgrounds ───
  static const appBackground = Color(0xFFF2EDE4);   // warm cream
  static const questionBg    = Color(0xFF1B4D6E);    // dark navy
  static const cardBg        = Color(0xFFFFFFFF);

  // ─── Primary accents ───
  static const primaryTeal   = Color(0xFF3DBFBF);
  static const primaryPink   = Color(0xFFF07070);

  // ─── Answer buttons ───
  static const answerRed     = Color(0xFFE05555);
  static const answerBlue    = Color(0xFF4A90D9);
  static const answerYellow  = Color(0xFFF5C242);
  static const answerGreen   = Color(0xFF4CAF50);

  // ─── Text ───
  static const textDark      = Color(0xFF2C2C2C);
  static const textMuted     = Color(0xFF8A8A8A);

  // ─── Hard shadow / border ───
  static const hardShadow    = Color(0xFF1A1A1A);

  // ─── Category chip "All" active ───
  static const chipActiveGold = Color(0xFFE8A838);

  // ─── Misc ───
  static const divider       = Color(0xFFE0E0E0);

  /// The 4 answer-button colors in order.
  static const List<Color> answerColors = [
    answerRed,
    answerBlue,
    answerYellow,
    answerGreen,
  ];
}
