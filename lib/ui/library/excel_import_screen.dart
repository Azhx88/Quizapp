// Excel Import Preview Screen — shows parsed questions for review before
// confirming the import into the SQLite database.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/services/excel_import_service.dart';
import 'package:quizzapp/providers/quiz_provider.dart';
import 'package:quizzapp/utils/app_colors.dart';
import 'package:quizzapp/utils/app_text.dart';

/// Screen that displays parsed Excel questions and lets the user review,
/// toggle individual questions, edit the quiz title/category, and confirm.
class ExcelImportScreen extends ConsumerStatefulWidget {
  final ExcelImportResult importResult;

  const ExcelImportScreen({super.key, required this.importResult});

  @override
  ConsumerState<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends ConsumerState<ExcelImportScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _categoryCtrl;

  /// Track which questions the user wants to import (by index).
  late List<bool> _selected;

  bool _showWarnings = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.importResult.suggestedTitle);
    _categoryCtrl = TextEditingController(text: widget.importResult.suggestedCategory);
    _selected = List.filled(widget.importResult.questions.length, true);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  /// Number of questions currently selected for import.
  int get _selectedCount => _selected.where((s) => s).length;

  // ── Import action ──
  Future<void> _confirmImport() async {
    if (_selectedCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions selected.')),
      );
      return;
    }

    final title = _titleCtrl.text.trim().isEmpty ? 'Imported Quiz' : _titleCtrl.text.trim();
    final category = _categoryCtrl.text.trim().isEmpty ? 'General' : _categoryCtrl.text.trim();

    setState(() => _importing = true);

    try {
      const uuid = Uuid();
      final quizId = uuid.v4();

      // Build the final question list with proper quizId.
      final questionsToImport = <Question>[];
      for (int i = 0; i < widget.importResult.questions.length; i++) {
        if (!_selected[i]) continue;
        final q = widget.importResult.questions[i];
        questionsToImport.add(q.copyWith(
          id: uuid.v4(),
          quizId: quizId,
        ));
      }

      final quiz = Quiz(
        id: quizId,
        title: title,
        category: category,
        createdAt: DateTime.now(),
        questions: questionsToImport,
      );

      // Save using existing repository logic.
      await ref.read(quizRepositoryProvider).save(quiz);

      // Refresh the quiz list so the library screen shows the new quiz.
      ref.invalidate(quizListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imported ${questionsToImport.length} questions into "$title"'),
          backgroundColor: AppColors.primaryTeal,
        ),
      );

      // Navigate back to the library.
      context.go('/library');
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: AppColors.answerRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.importResult.questions;
    final warnings = widget.importResult.warnings;

    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──
            _buildTopBar(),

            // ── Title & Category inputs ──
            _buildMetadataInputs(),

            // ── Summary bar ──
            _buildSummaryBar(questions.length, warnings.length),

            // ── Warnings (expandable) ──
            if (warnings.isNotEmpty) _buildWarningSection(warnings),

            // ── Question list ──
            Expanded(
              child: questions.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: questions.length,
                      itemBuilder: (ctx, i) => _buildQuestionCard(i, questions[i]),
                    ),
            ),
          ],
        ),
      ),

      // ── Bottom import button ──
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ────────────────────────────────────────────────────
  // Sub-widgets
  // ────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back, color: AppColors.textDark),
          ),
          const Spacer(),
          Text(
            'Import Preview',
            style: AppText.heading(fontSize: 20, color: AppColors.primaryTeal),
          ),
          const Spacer(),
          // Select all / deselect all toggle.
          IconButton(
            onPressed: () {
              final allSelected = _selected.every((s) => s);
              setState(() {
                _selected = List.filled(_selected.length, !allSelected);
              });
            },
            icon: Icon(
              _selected.every((s) => s)
                  ? Icons.deselect
                  : Icons.select_all,
              color: AppColors.textDark,
            ),
            tooltip: _selected.every((s) => s) ? 'Deselect All' : 'Select All',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataInputs() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          // Quiz title field.
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _titleCtrl,
              style: AppText.body(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Quiz Title',
                labelStyle: AppText.body(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.quiz_outlined, color: AppColors.primaryTeal, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category field.
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _categoryCtrl,
              style: AppText.body(fontSize: 15),
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: AppText.body(fontSize: 13, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.category_outlined, color: AppColors.chipActiveGold, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBar(int totalQuestions, int warningCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primaryTeal.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.checklist_rounded, color: AppColors.primaryTeal, size: 20),
            const SizedBox(width: 8),
            Text(
              '$_selectedCount of $totalQuestions questions selected',
              style: AppText.body(fontSize: 13, color: AppColors.primaryTeal),
            ),
            const Spacer(),
            if (warningCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.answerYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$warningCount warning${warningCount == 1 ? '' : 's'}',
                  style: AppText.body(fontSize: 11, color: AppColors.chipActiveGold),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningSection(List<String> warnings) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showWarnings = !_showWarnings),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.answerYellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.chipActiveGold, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${warnings.length} row${warnings.length == 1 ? '' : 's'} skipped',
                    style: AppText.body(fontSize: 12, color: AppColors.chipActiveGold),
                  ),
                  const Spacer(),
                  Icon(
                    _showWarnings ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.chipActiveGold,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_showWarnings)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.answerYellow.withValues(alpha: 0.3)),
              ),
              child: ListView(
                shrinkWrap: true,
                children: warnings
                    .map((w) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '• $w',
                            style: AppText.body(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question q) {
    final isSelected = _selected[index];
    final correctAnswer = q.correctAnswers.isNotEmpty ? q.correctAnswers.first : '';
    final allOptions = [correctAnswer, ...q.falseAnswers];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryTeal.withValues(alpha: 0.3)
                : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => setState(() => _selected[index] = !_selected[index]),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: question number + checkbox.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number badge.
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryTeal
                              : AppColors.textMuted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: AppText.body(fontSize: 12, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Question text.
                      Expanded(
                        child: Text(
                          q.question,
                          style: AppText.body(fontSize: 13.5),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Checkbox.
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: Checkbox(
                          value: isSelected,
                          onChanged: (v) => setState(() => _selected[index] = v ?? false),
                          activeColor: AppColors.primaryTeal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Options list.
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: allOptions.map((opt) {
                      final isCorrect = opt == correctAnswer;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? AppColors.answerGreen.withValues(alpha: 0.15)
                              : const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCorrect
                                ? AppColors.answerGreen.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isCorrect)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(Icons.check_circle, color: AppColors.answerGreen, size: 14),
                              ),
                            Flexible(
                              child: Text(
                                opt,
                                style: AppText.body(
                                  fontSize: 12,
                                  color: isCorrect ? AppColors.answerGreen : AppColors.textDark,
                                  fontWeight: isCorrect ? FontWeight.w800 : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📭', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('No questions could be parsed', style: AppText.heading(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Check the file format and try again',
            style: AppText.body(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cancel button.
          Expanded(
            child: OutlinedButton(
              onPressed: _importing ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                side: const BorderSide(color: AppColors.textMuted),
              ),
              child: Text('Cancel', style: AppText.body(color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(width: 12),
          // Import button.
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _importing || _selectedCount == 0 ? null : _confirmImport,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryTeal,
                disabledBackgroundColor: AppColors.primaryTeal.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              child: _importing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Import $_selectedCount Question${_selectedCount == 1 ? '' : 's'}',
                      style: AppText.body(fontSize: 15, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
