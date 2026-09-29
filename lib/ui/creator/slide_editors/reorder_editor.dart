import 'package:flutter/material.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

class ReorderEditor extends StatelessWidget {
  final Question question;
  final void Function(Question) onUpdate;
  const ReorderEditor({super.key, required this.question, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final items = List<String>.from(question.orderedItems);
    while (items.length < 2) {
      items.add('');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items in correct order', style: AppText.heading(fontSize: 16)),
        const SizedBox(height: 4),
        Text('Players will be asked to drag these into this order.',
            style: AppText.body(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          onReorder: (o, n) {
            final newItems = List<String>.from(items);
            final item = newItems.removeAt(o);
            newItems.insert(n > o ? n - 1 : n, item);
            onUpdate(question.copyWith(orderedItems: newItems));
          },
          itemBuilder: (ctx, i) => Container(
            key: ValueKey('${question.id}_item_$i'),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider, width: 2),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primaryTeal,
                radius: 16,
                child: Text('${i + 1}', style: AppText.heading(color: Colors.white, fontSize: 14)),
              ),
              title: TextField(
                controller: TextEditingController(text: items[i])
                  ..selection = TextSelection.collapsed(offset: items[i].length),
                style: AppText.body(),
                decoration: InputDecoration(
                  hintText: 'Item ${i + 1}${i >= 2 ? " (optional)" : " *"}',
                  hintStyle: AppText.body(color: AppColors.textMuted),
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  final copy = List<String>.from(items);
                  copy[i] = v;
                  onUpdate(question.copyWith(orderedItems: copy));
                },
              ),
              trailing: const Icon(Icons.drag_indicator_rounded, color: AppColors.textMuted),
            ),
          ),
        ),
        Row(
          children: [
            if (items.length < 4)
              TextButton.icon(
                onPressed: () {
                  final copy = [...items, ''];
                  onUpdate(question.copyWith(orderedItems: copy));
                },
                icon: const Icon(Icons.add, color: AppColors.primaryTeal),
                label: Text('Add item', style: AppText.heading(color: AppColors.primaryTeal, fontSize: 14)),
              ),
            if (items.length > 2)
              TextButton.icon(
                onPressed: () {
                  final copy = items.sublist(0, items.length - 1);
                  onUpdate(question.copyWith(orderedItems: copy));
                },
                icon: const Icon(Icons.remove, color: AppColors.primaryPink),
                label: Text('Remove last', style: AppText.heading(color: AppColors.primaryPink, fontSize: 14)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.auto_awesome),
          label: Text('Autocomplete with AI (offline)', style: AppText.heading(fontSize: 14)),
        ),
      ],
    );
  }
}
