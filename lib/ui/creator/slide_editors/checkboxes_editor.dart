import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class CheckboxesEditor extends StatelessWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const CheckboxesEditor({super.key, required this.question, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final correct = List<String>.from(question.correctAnswers);
    final wrong = List<String>.from(question.falseAnswers);
    while (correct.isEmpty) {
      correct.add('');
    }
    while (wrong.isEmpty) {
      wrong.add('');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Correct Answers (all must be selected)',
            style: AppText.heading(fontSize: 14, color: AppColors.primaryTeal)),
        const SizedBox(height: 8),
        ...List.generate(2, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _OptionField(
            value: i < correct.length ? correct[i] : '',
            isCorrect: true,
            label: 'Correct ${i + 1}${i == 1 ? " (optional)" : ""}',
            onChanged: (v) {
              while (correct.length <= i) {
                correct.add('');
              }
              correct[i] = v;
              onUpdate(question.copyWith(correctAnswers: correct));
            },
          ),
        )),
        const SizedBox(height: 16),
        Text('Wrong Options', style: AppText.heading(fontSize: 14, color: AppColors.primaryPink)),
        const SizedBox(height: 8),
        ...List.generate(2, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _OptionField(
            value: i < wrong.length ? wrong[i] : '',
            isCorrect: false,
            label: 'Wrong ${i + 1}${i == 1 ? " (optional)" : ""}',
            onChanged: (v) {
              while (wrong.length <= i) {
                wrong.add('');
              }
              wrong[i] = v;
              onUpdate(question.copyWith(falseAnswers: wrong));
            },
          ),
        )),
      ],
    );
  }
}

class _OptionField extends StatelessWidget {
  final String value;
  final bool isCorrect;
  final String label;
  final ValueChanged<String> onChanged;
  const _OptionField({
    required this.value,
    required this.isCorrect,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.primaryTeal : AppColors.primaryPink;
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      style: AppText.body(),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body(color: AppColors.textMuted),
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
          borderSide: BorderSide(color: color, width: 3),
        ),
        prefixIcon: Icon(
          isCorrect ? Icons.check_box : Icons.check_box_outline_blank,
          color: color,
        ),
      ),
      onChanged: onChanged,
    );
  }
}
