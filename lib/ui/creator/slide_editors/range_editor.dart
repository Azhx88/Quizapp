import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class RangeEditor extends StatefulWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const RangeEditor({super.key, required this.question, required this.onUpdate});

  @override
  State<RangeEditor> createState() => _RangeEditorState();
}

class _RangeEditorState extends State<RangeEditor> {
  late double _min;
  late double _max;
  late double _correct;

  @override
  void initState() {
    super.initState();
    _min = widget.question.minValue ?? 0;
    _max = widget.question.maxValue ?? 100;
    _correct = widget.question.correctValue ?? 50;
  }

  void _save() {
    widget.onUpdate(widget.question.copyWith(
      minValue: _min,
      maxValue: _max,
      correctValue: _correct,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final unitCtrl = TextEditingController(text: widget.question.unit ?? '');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: _NumField(
              label: 'Min',
              value: _min,
              onChanged: (v) => setState(() { _min = v; _save(); }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumField(
              label: 'Max',
              value: _max,
              onChanged: (v) => setState(() { _max = v; _save(); }),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _NumField(
              label: 'Correct',
              value: _correct,
              onChanged: (v) => setState(() { _correct = v; _save(); }),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: unitCtrl,
          style: AppText.body(),
          decoration: InputDecoration(
            labelText: 'Unit (optional, e.g. "km", "°C")',
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
              borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
            ),
          ),
          onChanged: (v) => widget.onUpdate(
              widget.question.copyWith(unit: v.isEmpty ? null : v)),
        ),
        const SizedBox(height: 16),
        Text('Preview (correct = $_correct)', style: AppText.heading(fontSize: 14)),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryTeal,
            thumbColor: AppColors.primaryTeal,
          ),
          child: Slider(
            min: _min,
            max: _max == _min ? _min + 1 : _max,
            value: _correct.clamp(_min, _max == _min ? _min + 1 : _max),
            onChanged: (v) => setState(() { _correct = v; _save(); }),
          ),
        ),
        Row(children: [
          Text(_min.toStringAsFixed(0), style: AppText.body(color: AppColors.textMuted)),
          const Spacer(),
          Text(_max.toStringAsFixed(0), style: AppText.body(color: AppColors.textMuted)),
        ]),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Require exact answer for points', style: AppText.heading(fontSize: 14)),
          subtitle: Text('Off = proximity scoring', style: AppText.body(fontSize: 12, color: AppColors.textMuted)),
          activeThumbColor: AppColors.primaryTeal,
          value: widget.question.requireExactAnswer,
          onChanged: (v) =>
              widget.onUpdate(widget.question.copyWith(requireExactAnswer: v)),
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _NumField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value.toStringAsFixed(0)),
      keyboardType: TextInputType.number,
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
          borderSide: const BorderSide(color: AppColors.primaryTeal, width: 2),
        ),
      ),
      onChanged: (v) {
        final d = double.tryParse(v);
        if (d != null) onChanged(d);
      },
    );
  }
}
