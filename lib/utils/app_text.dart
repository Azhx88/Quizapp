import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzapp/utils/app_colors.dart';

/// Shared text styles for the entire app.
class AppText {
  AppText._();

  /// FredokaOne — headings, logo, button labels.
  static TextStyle heading({
    double fontSize = 24,
    Color color = AppColors.textDark,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.fredoka(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );

  /// Nunito bold — body / secondary text.
  static TextStyle body({
    double fontSize = 14,
    Color color = AppColors.textDark,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.nunito(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
}
