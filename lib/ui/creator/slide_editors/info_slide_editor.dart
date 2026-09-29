import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class InfoSlideEditor extends StatelessWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const InfoSlideEditor({super.key, required this.question, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Info slides display content between questions.\nNo answer is collected.',
          style: AppText.body(color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(text: question.funFact ?? '')
            ..selection = TextSelection.collapsed(
                offset: (question.funFact ?? '').length),
          style: AppText.body(),
          decoration: InputDecoration(
            labelText: 'Body text',
            labelStyle: AppText.heading(fontSize: 14, color: AppColors.textMuted),
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
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          onChanged: (v) => onUpdate(question.copyWith(funFact: v)),
        ),
      ],
    );
  }
}
