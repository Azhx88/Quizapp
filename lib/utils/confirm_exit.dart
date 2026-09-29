import 'package:flutter/material.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

/// Standard "are you sure you want to leave?" dialog. Returns `true` if the
/// user confirms the exit, `false` (or `null`) if they cancel.
///
/// Used by the question screen, host lobby, and quiz creator to prevent
/// accidental back-press from destroying in-progress game state or unsaved
/// edits.
Future<bool> confirmExit(
  BuildContext context, {
  required String title,
  required String message,
  String exitLabel = 'Exit',
  String cancelLabel = 'Stay',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppText.heading(fontSize: 18)),
      content: Text(message,
          style: AppText.body(fontSize: 14, color: AppColors.textMuted)),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelLabel,
              style: AppText.heading(
                fontSize: 14,
                color: AppColors.primaryTeal,
              )),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryPink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(exitLabel,
              style: AppText.heading(fontSize: 14, color: Colors.white)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
