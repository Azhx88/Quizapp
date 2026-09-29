import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class TypeAnswerEditor extends StatelessWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const TypeAnswerEditor({super.key, required this.question, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correct Answer', style: AppText.heading(fontSize: 16)),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: question.typeAnswer ?? '')
            ..selection = TextSelection.collapsed(
                offset: (question.typeAnswer ?? '').length),
          style: AppText.body(),
          decoration: InputDecoration(
            hintText: 'Type the correct answer...',
            hintStyle: AppText.body(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.divider, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
            prefixIcon: const Icon(Icons.keyboard, color: AppColors.textMuted),
          ),
          onChanged: (v) => onUpdate(question.copyWith(typeAnswer: v)),
        ),
        const SizedBox(height: 8),
        Text(
          'Comparison is case-insensitive and trims whitespace.',
          style: AppText.body(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }
}
