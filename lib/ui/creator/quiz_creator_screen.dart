import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';
import 'package:quizzapp/providers/game_session_provider.dart';
import 'package:quizzapp/providers/quiz_provider.dart';
import 'package:quizzapp/providers/settings_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';
import 'package:quizzapp/utils/confirm_exit.dart';
import 'package:quizzapp/utils/question_media.dart';
import 'package:quizzapp/utils/quiz_validator.dart';
import 'package:quizzapp/ui/creator/slide_editors/buttons_editor.dart';
import 'package:quizzapp/ui/creator/slide_editors/checkboxes_editor.dart';
import 'package:quizzapp/ui/creator/slide_editors/reorder_editor.dart';
import 'package:quizzapp/ui/creator/slide_editors/range_editor.dart';
import 'package:quizzapp/ui/creator/slide_editors/type_answer_editor.dart';
import 'package:quizzapp/ui/creator/slide_editors/info_slide_editor.dart';

class QuizCreatorScreen extends ConsumerStatefulWidget {
  final String quizId;
  const QuizCreatorScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizCreatorScreen> createState() => _QuizCreatorScreenState();
}

class _QuizCreatorScreenState extends ConsumerState<QuizCreatorScreen> {
  int _selectedIndex = 0;
  final _picker = ImagePicker();
  bool _settingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final quiz = ref.watch(activeQuizProvider);
    if (quiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final questions = quiz.questions;
    final current =
        _selectedIndex < questions.length ? questions[_selectedIndex] : null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmLeaveCreator();
        if (ok && mounted) context.go('/library');
      },
      child: Scaffold(
        backgroundColor: AppColors.appBackground,
        appBar: AppBar(
          backgroundColor: AppColors.appBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: AppColors.textDark),
            tooltip: 'Back to home',
            onPressed: () async {
              final ok = await _confirmLeaveCreator();
              if (ok && mounted) context.go('/library');
            },
          ),
          title: _TitleField(quiz: quiz),
          actions: [
            IconButton(
              onPressed: () => _preview(context, quiz),
              tooltip: 'Preview',
              icon: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.primaryTeal),
            ),
            // "Host" — saves first, then validates, then goes to settings.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => _hostThisQuiz(context, quiz),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hardShadow, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.hardShadow, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cast_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text('Host',
                          style: AppText.heading(
                              color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8, left: 4),
              child: GestureDetector(
                onTap: () => _save(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryPink,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hardShadow, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.hardShadow, offset: Offset(2, 2)),
                    ],
                  ),
                  child: Text('Done',
                      style:
                          AppText.heading(color: Colors.white, fontSize: 14)),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Editor area
            Expanded(
              child: current == null
                  ? const Center(child: Text('Add a slide below'))
                  : _SlideEditor(
                      question: current,
                      index: _selectedIndex,
                      picker: _picker,
                    ),
            ),
            // Global Quiz Settings — collapsed by default; replaces the old dialog.
            _QuizSettingsPanel(
              expanded: _settingsExpanded,
              onToggle: () =>
                  setState(() => _settingsExpanded = !_settingsExpanded),
            ),
            // Bottom bar: slide strip | add button (no per-section settings).
            _BottomBar(
              questions: questions,
              selectedIndex: _selectedIndex,
              onSelectSlide: (i) => setState(() => _selectedIndex = i),
              onAddSlide: _addSlide,
              onAddBlank: _addBlankSlide,
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLeaveCreator() async {
    return confirmExit(
      context,
      title: 'Discard unsaved changes?',
      message:
          'Your edits to this quiz haven\'t been saved. Tap "Done" in the top-right to save before leaving.',
      exitLabel: 'Discard',
      cancelLabel: 'Keep editing',
    );
  }

  void _addSlide(SlideType type) {
    final quiz = ref.read(activeQuizProvider);
    if (quiz == null) return;
    final q = Question(
      id: const Uuid().v4(),
      quizId: quiz.id,
      slideType: type,
      question: '',
      correctAnswers:
          type == SlideType.buttons || type == SlideType.checkboxes ? [''] : [],
      falseAnswers: type == SlideType.buttons ? ['', ''] : [],
      orderedItems: type == SlideType.reorder ? ['', ''] : [],
    );
    ref.read(activeQuizProvider.notifier).addQuestion(q);
    setState(() => _selectedIndex = quiz.questions.length);
  }

  void _addBlankSlide() {
    _showSlideTypeSheet();
  }

  void _showSlideTypeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.appBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: SlideType.values
            .map((t) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _addSlide(t);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.hardShadow, width: 2),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.hardShadow, offset: Offset(2, 2)),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.icon, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 8),
                        Text(t.label,
                            textAlign: TextAlign.center,
                            style: AppText.heading(
                                fontSize: 12, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    await ref.read(activeQuizProvider.notifier).save();
    ref.invalidate(quizListProvider);
    if (mounted) context.go('/library');
  }

  /// Validate every slide. If anything's missing, show a snackbar and jump to
  /// the first offending slide. Otherwise save, then take the user to host
  /// settings.
  Future<void> _hostThisQuiz(BuildContext context, Quiz quiz) async {
    final issues = validateQuiz(quiz);
    if (issues.isNotEmpty) {
      final firstBadSlide = issues.first.slideIndex;
      final summary = issues
          .take(3)
          .map((i) => '• ${i.toString()}')
          .join('\n');
      final more =
          issues.length > 3 ? '\n…and ${issues.length - 3} more.' : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          content: Text("Can't host yet — fix these first:\n$summary$more"),
          backgroundColor: AppColors.primaryPink,
          action: SnackBarAction(
            label: 'Go to slide',
            textColor: Colors.white,
            onPressed: () => setState(() => _selectedIndex = firstBadSlide),
          ),
        ),
      );
      setState(() => _selectedIndex = firstBadSlide);
      return;
    }
    await ref.read(activeQuizProvider.notifier).save();
    ref.invalidate(quizListProvider);
    if (!mounted) return;
    // Seed the session with this quiz so the settings/lobby flow has it.
    final settings = ref.read(settingsProvider);
    ref.read(gameSessionProvider.notifier).startHostSession(quiz, settings);
    if (mounted) context.push('/host/lobby');
  }

  void _preview(BuildContext context, Quiz quiz) {
    if (quiz.questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one slide to preview.')),
      );
      return;
    }
    context.push('/preview/${quiz.id}', extra: _selectedIndex);
  }
}

class _TitleField extends ConsumerStatefulWidget {
  final Quiz quiz;
  const _TitleField({required this.quiz});

  @override
  ConsumerState<_TitleField> createState() => _TitleFieldState();
}

class _TitleFieldState extends ConsumerState<_TitleField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.quiz.title);
  }

  @override
  void didUpdateWidget(covariant _TitleField old) {
    super.didUpdateWidget(old);
    // Keep the controller in sync if the underlying quiz title changes
    // from somewhere other than this field (e.g. an undo).
    if (widget.quiz.title != _ctrl.text) {
      _ctrl.value = TextEditingValue(
        text: widget.quiz.title,
        selection: TextSelection.collapsed(offset: widget.quiz.title.length),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextField(
        controller: _ctrl,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          isDense: true,
          isCollapsed: true,
          hintText: 'Quiz title',
          hintStyle: AppText.body(color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: AppText.heading(fontSize: 20, color: AppColors.primaryTeal),
        onChanged: (v) =>
            ref.read(activeQuizProvider.notifier).updateTitle(v),
      ),
    );
  }
}

class _SlideEditor extends ConsumerWidget {
  final Question question;
  final int index;
  final ImagePicker picker;
  const _SlideEditor(
      {required this.question, required this.index, required this.picker});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(Question q) =>
        ref.read(activeQuizProvider.notifier).updateQuestion(index, q);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Slide type chip
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryTeal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.primaryTeal, width: 2),
                ),
                child: Text(
                  '${question.slideType.icon} ${question.slideType.label}',
                  style: AppText.heading(
                      fontSize: 14, color: AppColors.primaryTeal),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.primaryPink),
                tooltip: 'Delete slide',
                onPressed: () {
                  ref
                      .read(activeQuizProvider.notifier)
                      .removeQuestion(index);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Image (optional)
          _ImagePickerTile(
            mediaPath: question.mediaPath,
            picker: picker,
            onPicked: (path) =>
                update(question.copyWith(mediaPath: path)),
            onRemoved: () => update(question.copyWith(mediaPath: null)),
          ),
          const SizedBox(height: 16),

          // Question text
          TextField(
            key: ValueKey('${question.id}_question'),
            controller: TextEditingController(text: question.question)
              ..selection = TextSelection.collapsed(
                  offset: question.question.length),
            style: AppText.body(fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Question *',
              labelStyle:
                  AppText.heading(fontSize: 14, color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.divider, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.divider, width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                    color: AppColors.primaryTeal, width: 2),
              ),
            ),
            maxLines: 3,
            onChanged: (v) => update(question.copyWith(question: v)),
          ),
          const SizedBox(height: 16),

          // Fun fact
          TextField(
            key: ValueKey('${question.id}_funfact'),
            controller:
                TextEditingController(text: question.funFact ?? ''),
            style: AppText.body(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Fun fact (optional)',
              labelStyle: AppText.body(color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.lightbulb_outline,
                  color: AppColors.answerYellow),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.divider, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppColors.divider, width: 2),
              ),
            ),
            onChanged: (v) =>
                update(question.copyWith(funFact: v.isEmpty ? null : v)),
          ),
          const SizedBox(height: 16),

          // Slide-specific editor
          _buildTypeEditor(question, update),
        ],
      ),
    );
  }

  Widget _buildTypeEditor(Question q, void Function(Question) update) {
    return switch (q.slideType) {
      SlideType.buttons => ButtonsEditor(question: q, onUpdate: update),
      SlideType.checkboxes =>
        CheckboxesEditor(question: q, onUpdate: update),
      SlideType.reorder => ReorderEditor(question: q, onUpdate: update),
      SlideType.range => RangeEditor(question: q, onUpdate: update),
      SlideType.typeAnswer =>
        TypeAnswerEditor(question: q, onUpdate: update),
      SlideType.infoSlide => InfoSlideEditor(question: q, onUpdate: update),
    };
  }
}

/// Single global Quiz Settings panel pinned to the bottom of the creator,
/// replacing the per-section gear-icon dialog. Collapsed by default to save
/// space; expanding it reveals quiz-level fields (category today, room for
/// more without changing the layout).
class _QuizSettingsPanel extends ConsumerWidget {
  final bool expanded;
  final VoidCallback onToggle;

  const _QuizSettingsPanel(
      {required this.expanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quiz = ref.watch(activeQuizProvider);
    if (quiz == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.tune_rounded,
                      color: AppColors.primaryTeal, size: 20),
                  const SizedBox(width: 8),
                  Text('Quiz Settings',
                      style: AppText.heading(
                          fontSize: 14, color: AppColors.textDark)),
                  const Spacer(),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          key: ValueKey('${quiz.id}_category'),
                          controller:
                              TextEditingController(text: quiz.category)
                                ..selection = TextSelection.collapsed(
                                    offset: quiz.category.length),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            isDense: true,
                          ),
                          onChanged: (v) => ref
                              .read(activeQuizProvider.notifier)
                              .updateCategory(v),
                        ),
                        const SizedBox(height: 6),
                        Text(
                            '${quiz.questions.length} slide${quiz.questions.length == 1 ? "" : "s"} • Use the Host button above to start a session.',
                            style: AppText.body(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final List<Question> questions;
  final int selectedIndex;
  final ValueChanged<int> onSelectSlide;
  final VoidCallback onAddBlank;
  final void Function(SlideType) onAddSlide;

  const _BottomBar({
    required this.questions,
    required this.selectedIndex,
    required this.onSelectSlide,
    required this.onAddBlank,
    required this.onAddSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 64,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: questions.length,
                itemBuilder: (ctx, i) {
                  final selected = i == selectedIndex;
                  return GestureDetector(
                    onTap: () => onSelectSlide(i),
                    child: Container(
                      width: 54,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primaryTeal.withValues(alpha: 0.1)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? AppColors.primaryTeal
                              : AppColors.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(questions[i].slideType.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(height: 4),
                          Text('${i + 1}',
                              style: AppText.heading(
                                fontSize: 10,
                                color: selected
                                    ? AppColors.primaryTeal
                                    : AppColors.textMuted,
                              )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded,
                color: AppColors.primaryTeal, size: 36),
            tooltip: 'Add slide',
            onPressed: onAddBlank,
          ),
        ],
      ),
    );
  }
}

class _ImagePickerTile extends StatelessWidget {
  final String? mediaPath;
  final ImagePicker picker;
  final ValueChanged<String> onPicked;
  final VoidCallback onRemoved;

  const _ImagePickerTile({
    required this.mediaPath,
    required this.picker,
    required this.onPicked,
    required this.onRemoved,
  });

  Future<void> _pick(BuildContext context, {required bool fromCamera}) async {
    try {
      final path = await QuestionMedia.pickAndStoreImage(picker,
          fromCamera: fromCamera);
      if (path != null) onPicked(path);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load image: $e')),
        );
      }
    }
  }

  void _showSourceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primaryTeal),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheet);
                _pick(context, fromCamera: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primaryTeal),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheet);
                _pick(context, fromCamera: true);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = mediaPath != null && mediaPath!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Image (optional)',
                style: AppText.heading(
                    fontSize: 14, color: AppColors.textDark)),
            const Spacer(),
            if (hasImage)
              TextButton.icon(
                onPressed: onRemoved,
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: AppColors.primaryPink),
                label: Text('Remove',
                    style: AppText.body(
                        fontSize: 12, color: AppColors.primaryPink)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showSourceSheet(context),
          child: Container(
            height: hasImage ? 160 : 88,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    hasImage ? AppColors.primaryTeal : AppColors.divider,
                width: 2,
              ),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      QuestionMedia.render(mediaPath, fit: BoxFit.cover),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded,
                                  size: 14, color: Colors.white),
                              SizedBox(width: 6),
                              Text('Replace',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined,
                          color: AppColors.primaryTeal, size: 28),
                      const SizedBox(width: 10),
                      Text('Add an image',
                          style: AppText.heading(
                              fontSize: 14,
                              color: AppColors.primaryTeal)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

