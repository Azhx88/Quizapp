import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/constants.dart';

class ButtonsEditor extends StatelessWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const ButtonsEditor({super.key, required this.question, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final correct = List<String>.from(question.correctAnswers);
    final wrong = List<String>.from(question.falseAnswers);
    while (correct.isEmpty) {
      correct.add('');
    }
    while (wrong.length < 2) {
      wrong.add('');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'Correct Answer', color: AppColors.primaryTeal),
        _AnswerField(
          value: correct.isNotEmpty ? correct[0] : '',
          color: AppColors.primaryTeal,
          hint: 'Correct answer',
          onChanged: (v) {
            correct[0] = v;
            onUpdate(question.copyWith(correctAnswers: correct));
          },
        ),
        const SizedBox(height: 16),
        const _SectionLabel(label: 'Wrong Answers', color: AppColors.primaryPink),
        ...List.generate(3, (i) {
          final val = i < wrong.length ? wrong[i] : '';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AnswerField(
              value: val,
              color: kAnswerColors[(i + 1) % kAnswerColors.length],
              hint: 'Wrong answer ${i + 1}${i >= 1 ? " (optional)" : ""}',
              onChanged: (v) {
                while (wrong.length <= i) {
                  wrong.add('');
                }
                wrong[i] = v;
                onUpdate(question.copyWith(falseAnswers: wrong));
              },
            ),
          );
        }),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: color,
              margin: const EdgeInsets.only(right: 8)),
          Text(label, style: AppText.heading(fontSize: 14)),
        ],
      ),
    );
  }
}

class _AnswerField extends StatelessWidget {
  final String value;
  final Color color;
  final String hint;
  final ValueChanged<String> onChanged;
  const _AnswerField({
    required this.value,
    required this.color,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
      style: AppText.body(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppText.body(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: color, width: 3),
        ),
        prefixIcon: Icon(Icons.radio_button_checked, color: color),
      ),
      onChanged: onChanged,
    );
  }
}
