import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';
import 'package:quizzapp/providers/quiz_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/question_media.dart';

/// Read-only preview of a quiz — shows what each slide will look like to
/// players. No timer, no networking, no answer submission. Step through with
/// the prev/next buttons; tap "Reveal" to see correctness highlighting.
class PreviewScreen extends ConsumerStatefulWidget {
  final String quizId;
  final int initialIndex;

  const PreviewScreen({
    super.key,
    required this.quizId,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen> {
  late int _index;
  bool _revealed = false;
  // Per-slide UI state for the preview, reset when changing slides.
  String? _selectedButton;
  final Set<int> _selectedCheckboxes = {};
  double _rangeValue = 50;
  late TextEditingController _typeCtrl;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _typeCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _typeCtrl.dispose();
    super.dispose();
  }

  void _resetSlideState(Question q) {
    _revealed = false;
    _selectedButton = null;
    _selectedCheckboxes.clear();
    _typeCtrl.clear();
    _rangeValue = q.minValue != null && q.maxValue != null
        ? (q.minValue! + q.maxValue!) / 2
        : 50;
  }

  @override
  Widget build(BuildContext context) {
    // Prefer the in-memory quiz being edited, fall back to the saved version.
    final activeQuiz = ref.watch(activeQuizProvider);
    final Quiz? quiz = activeQuiz != null && activeQuiz.id == widget.quizId
        ? activeQuiz
        : null;

    if (quiz == null) {
      return _LoadingScaffold(quizId: widget.quizId);
    }

    if (quiz.questions.isEmpty) {
      return _EmptyScaffold(onBack: () => context.go('/'));
    }

    final clampedIndex = _index.clamp(0, quiz.questions.length - 1);
    if (clampedIndex != _index) _index = clampedIndex;
    final q = quiz.questions[_index];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: Scaffold(
      backgroundColor: AppColors.appBackground,
      appBar: AppBar(
        backgroundColor: AppColors.appBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textDark),
          onPressed: () => context.go('/'),
        ),
        title: Text('Preview',
            style: AppText.heading(
                fontSize: 18, color: AppColors.textDark)),
        centerTitle: true,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_index + 1}/${quiz.questions.length}',
                style: AppText.heading(
                    fontSize: 12, color: AppColors.primaryTeal),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPink.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primaryPink.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.preview_rounded,
                    color: AppColors.primaryPink, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Preview mode — no timer, no scoring. Tap "Reveal" to see correctness.',
                      style: AppText.body(
                          fontSize: 12, color: AppColors.textDark)),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _slideBody(q),
            ),
          ),
          _NavBar(
            canPrev: _index > 0,
            canNext: _index < quiz.questions.length - 1,
            revealed: _revealed,
            onPrev: () {
              setState(() {
                _index--;
                _resetSlideState(quiz.questions[_index]);
              });
            },
            onNext: () {
              setState(() {
                _index++;
                _resetSlideState(quiz.questions[_index]);
              });
            },
            onReveal: () => setState(() => _revealed = true),
            onResetReveal: () => setState(
                () => _resetSlideState(quiz.questions[_index])),
          ),
        ],
      ),
      ),
    );
  }

  Widget _slideBody(Question q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (q.mediaPath != null && q.mediaPath!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: QuestionMedia.render(q.mediaPath, height: 180),
            ),
          ),
        // Question card
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hardShadow, width: 2),
            boxShadow: const [
              BoxShadow(
                  color: AppColors.hardShadow,
                  offset: Offset(4, 4),
                  blurRadius: 0),
            ],
          ),
          child: Text(
            q.question.isEmpty ? '(empty question)' : q.question,
            style: AppText.heading(fontSize: 20, color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        _answerWidget(q),
        if (_revealed && q.funFact != null && q.funFact!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC02)),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(q.funFact!,
                          style: AppText.body(
                              fontSize: 13,
                              color: const Color(0xFF5D4037)))),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _answerWidget(Question q) {
    switch (q.slideType) {
      case SlideType.buttons:
        // Deterministic shuffle by question id so the correct answer is not
        // always at position 0 (which would give it away in preview), but
        // the order stays stable across rebuilds.
        final opts = _stableShuffle(
          [
            ...q.correctAnswers,
            ...q.falseAnswers,
          ].where((s) => s.isNotEmpty).toList(),
          q.id,
        ).take(4).toList();
        if (opts.isEmpty) {
          return _PlaceholderTile(
              text: 'No answer options yet — add some in the editor.');
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: opts.length,
          itemBuilder: (ctx, i) {
            final opt = opts[i];
            final correct = q.correctAnswers.contains(opt);
            final selected = _selectedButton == opt;
            Color base =
                AppColors.answerColors[i % AppColors.answerColors.length];
            if (_revealed) {
              base = correct
                  ? AppColors.answerGreen
                  : (selected ? AppColors.answerRed : base.withValues(alpha: 0.4));
            } else if (selected) {
              base = base;
            } else if (_selectedButton != null) {
              base = base.withValues(alpha: 0.5);
            }
            return GestureDetector(
              onTap: _revealed
                  ? null
                  : () => setState(() => _selectedButton = opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.hardShadow, width: 2),
                ),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(8),
                child: Text(opt,
                    textAlign: TextAlign.center,
                    style: AppText.heading(
                        fontSize: 18, color: Colors.white)),
              ),
            );
          },
        );

      case SlideType.checkboxes:
        final opts = _stableShuffle(
          [
            ...q.correctAnswers,
            ...q.falseAnswers,
          ].where((s) => s.isNotEmpty).toList(),
          q.id,
        );
        if (opts.isEmpty) {
          return _PlaceholderTile(
              text: 'No options yet — add some in the editor.');
        }
        return Column(
          children: List.generate(opts.length, (i) {
            final opt = opts[i];
            final correct = q.correctAnswers.contains(opt);
            final isChecked = _selectedCheckboxes.contains(i);
            Color border = AppColors.divider;
            if (_revealed) {
              border = correct
                  ? AppColors.answerGreen
                  : (isChecked ? AppColors.answerRed : AppColors.divider);
            } else if (isChecked) {
              border = AppColors.primaryTeal;
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border, width: 1.5),
              ),
              child: CheckboxListTile(
                value: isChecked,
                title: Text(opt,
                    style: AppText.body(
                        fontSize: 14, color: AppColors.textDark)),
                activeColor: AppColors.primaryTeal,
                onChanged: _revealed
                    ? null
                    : (_) => setState(() {
                          if (isChecked) {
                            _selectedCheckboxes.remove(i);
                          } else {
                            _selectedCheckboxes.add(i);
                          }
                        }),
              ),
            );
          }),
        );

      case SlideType.reorder:
        final items = q.orderedItems.where((s) => s.isNotEmpty).toList();
        if (items.length < 2) {
          return _PlaceholderTile(
              text: 'Need at least 2 items in the editor.');
        }
        // Show items in their authored order; in preview we just display them.
        return Column(
          children: items
              .asMap()
              .entries
              .map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primaryTeal,
                        radius: 14,
                        child: Text('${e.key + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ),
                      title: Text(e.value,
                          style: AppText.body(
                              fontSize: 14,
                              color: AppColors.textDark)),
                      trailing: const Icon(Icons.drag_handle_rounded,
                          color: AppColors.textMuted),
                    ),
                  ))
              .toList(),
        );

      case SlideType.range:
        final minV = q.minValue ?? 0;
        final maxV = q.maxValue ?? 100;
        final correctV = q.correctValue ?? ((minV + maxV) / 2);
        final safeMax = maxV == minV ? minV + 1 : maxV;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hardShadow, width: 2),
          ),
          child: Column(
            children: [
              Text(
                  '${_rangeValue.toStringAsFixed(1)}${q.unit != null ? ' ${q.unit}' : ''}',
                  style: AppText.heading(
                      fontSize: 28, color: AppColors.textDark)),
              Slider(
                min: minV,
                max: safeMax,
                value: _rangeValue.clamp(minV, safeMax),
                onChanged: _revealed
                    ? null
                    : (v) => setState(() => _rangeValue = v),
              ),
              Row(children: [
                Text(minV.toStringAsFixed(0),
                    style: AppText.body(color: AppColors.textMuted)),
                const Spacer(),
                Text(maxV.toStringAsFixed(0),
                    style: AppText.body(color: AppColors.textMuted)),
              ]),
              if (_revealed) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.answerGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                      'Correct: ${correctV.toStringAsFixed(1)}${q.unit != null ? ' ${q.unit}' : ''}',
                      style: AppText.heading(
                          fontSize: 14,
                          color: AppColors.answerGreen)),
                ),
              ],
            ],
          ),
        );

      case SlideType.typeAnswer:
        return Column(
          children: [
            TextField(
              controller: _typeCtrl,
              enabled: !_revealed,
              decoration: InputDecoration(
                hintText: 'Type your answer…',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (_revealed) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.answerGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Correct: ${q.typeAnswer ?? "(not set)"}',
                    style: AppText.heading(
                        fontSize: 14, color: AppColors.answerGreen)),
              ),
            ],
          ],
        );

      case SlideType.infoSlide:
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.hardShadow, width: 2),
          ),
          child: Column(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryTeal, size: 36),
              const SizedBox(height: 8),
              Text(q.funFact ?? '',
                  textAlign: TextAlign.center,
                  style: AppText.body(
                      fontSize: 14, color: AppColors.textMuted)),
            ],
          ),
        );
    }
  }
}

/// Stable shuffle: deterministic per [seed], so the order is constant for a
/// given question id but the correct answer isn't always at position 0.
List<T> _stableShuffle<T>(List<T> items, String seed) {
  final out = List<T>.from(items);
  final rng = math.Random(seed.hashCode);
  for (int i = out.length - 1; i > 0; i--) {
    final j = rng.nextInt(i + 1);
    final tmp = out[i];
    out[i] = out[j];
    out[j] = tmp;
  }
  return out;
}

class _NavBar extends StatelessWidget {
  final bool canPrev;
  final bool canNext;
  final bool revealed;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onReveal;
  final VoidCallback onResetReveal;

  const _NavBar({
    required this.canPrev,
    required this.canNext,
    required this.revealed,
    required this.onPrev,
    required this.onNext,
    required this.onReveal,
    required this.onResetReveal,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
              Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: Row(
          children: [
            IconButton.filledTonal(
              onPressed: canPrev ? onPrev : null,
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: revealed ? onResetReveal : onReveal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: revealed
                      ? AppColors.textMuted
                      : AppColors.primaryTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(revealed
                    ? Icons.refresh_rounded
                    : Icons.lightbulb_rounded),
                label:
                    Text(revealed ? 'Try again' : 'Reveal answer'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: canNext ? onNext : null,
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final String text;
  const _PlaceholderTile({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.divider.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.primaryPink, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: AppText.body(
                      fontSize: 13, color: AppColors.textDark))),
        ],
      ),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  final String quizId;
  const _LoadingScaffold({required this.quizId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text('Loading quiz $quizId…',
                style: AppText.body(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _EmptyScaffold extends StatelessWidget {
  final VoidCallback onBack;
  const _EmptyScaffold({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: onBack),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎬', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Nothing to preview',
                  style: AppText.heading(fontSize: 18)),
              const SizedBox(height: 8),
              Text('Add at least one slide to see the preview.',
                  textAlign: TextAlign.center,
                  style: AppText.body(color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}
