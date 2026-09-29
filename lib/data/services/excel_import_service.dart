// Excel Import Service — parses .xlsx/.xls files into Question objects.
// Uses the `excel` package for pure-Dart parsing (no native dependencies).

import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';

/// Result returned after parsing an Excel file.
class ExcelImportResult {
  /// Successfully parsed questions (not yet assigned a quizId).
  final List<Question> questions;

  /// Human-readable warnings for skipped / problematic rows.
  final List<String> warnings;

  /// Suggested quiz title derived from the file name.
  final String suggestedTitle;

  /// Suggested category derived from the most-common "reference" column value.
  final String suggestedCategory;

  const ExcelImportResult({
    required this.questions,
    required this.warnings,
    required this.suggestedTitle,
    required this.suggestedCategory,
  });
}

/// Service responsible for parsing Excel files into [ExcelImportResult].
class ExcelImportService {
  ExcelImportService._();

  // ──────────────────────────────────────────────────────────
  // Public API
  // ──────────────────────────────────────────────────────────

  /// Parse [bytes] of an Excel file and return structured result.
  /// [fileName] is used to derive the default quiz title.
  static ExcelImportResult parse(Uint8List bytes, String fileName) {
    final excel = Excel.decodeBytes(bytes);
    final warnings = <String>[];
    final questions = <Question>[];

    // Use the first sheet.
    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName];
    if (sheet == null || sheet.maxRows < 2) {
      return ExcelImportResult(
        questions: const [],
        warnings: const ['The Excel file is empty or has no data rows.'],
        suggestedTitle: _titleFromFileName(fileName),
        suggestedCategory: 'General',
      );
    }

    final rows = sheet.rows;

    // ── Detect column mapping from header row ──
    final mapping = _detectColumns(rows.first);
    if (mapping == null) {
      return ExcelImportResult(
        questions: const [],
        warnings: const [
          'Could not detect column layout. '
              'Expected headers like "question", "option_1", "correct" '
              'or "Question", "Option A", "Answer".'
        ],
        suggestedTitle: _titleFromFileName(fileName),
        suggestedCategory: 'General',
      );
    }

    // ── Parse each data row ──
    final categoryCounts = <String, int>{};
    const uuid = Uuid();

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final rowNum = i + 1; // 1-indexed for user-facing messages

      // Skip completely empty rows.
      if (row.every((c) => c == null || _cellStr(c).isEmpty)) continue;

      // --- Question text ---
      final questionText = _cellAt(row, mapping.questionCol).trim();
      if (questionText.isEmpty) {
        warnings.add('Row $rowNum: empty question text — skipped.');
        continue;
      }

      // --- Options ---
      final allOptions = <String>[];
      for (final col in mapping.optionCols) {
        final opt = _cellAt(row, col).trim();
        // Skip empty or placeholder "None" options.
        if (opt.isNotEmpty && opt.toLowerCase() != 'none') {
          allOptions.add(opt);
        }
      }
      if (allOptions.length < 2) {
        warnings.add('Row $rowNum: fewer than 2 valid options — skipped.');
        continue;
      }

      // --- Correct answer ---
      final correctRaw = _cellAt(row, mapping.correctCol).trim();
      String? correctAnswer;

      if (mapping.correctIsIndex) {
        // The "correct" column holds a 1-based index into the options.
        final idx = int.tryParse(correctRaw);
        if (idx == null || idx < 1 || idx > mapping.optionCols.length) {
          warnings.add('Row $rowNum: invalid correct-answer index "$correctRaw" — skipped.');
          continue;
        }
        correctAnswer = _cellAt(row, mapping.optionCols[idx - 1]).trim();
        // Edge case: the correct option might have been "None" / empty.
        if (correctAnswer.isEmpty || correctAnswer.toLowerCase() == 'none') {
          warnings.add('Row $rowNum: correct option is empty/None — skipped.');
          continue;
        }
      } else {
        // The "correct" / "answer" column holds the literal answer text.
        if (correctRaw.isEmpty) {
          warnings.add('Row $rowNum: missing correct answer — skipped.');
          continue;
        }
        // Match it against available options (case-insensitive).
        correctAnswer = allOptions.firstWhere(
          (o) => o.toLowerCase() == correctRaw.toLowerCase(),
          orElse: () => correctRaw, // Use verbatim if no match found.
        );
      }

      // Build false-answer list (all options except the correct one).
      final falseAnswers = allOptions.where((o) => o != correctAnswer).toList();

      // --- Category / reference ---
      if (mapping.referenceCol != null) {
        final cat = _cellAt(row, mapping.referenceCol!).trim();
        if (cat.isNotEmpty) {
          categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        }
      }

      // --- Build Question ---
      questions.add(Question(
        id: uuid.v4(),
        quizId: '', // Will be set when the user confirms import.
        slideType: SlideType.buttons,
        question: questionText,
        correctAnswers: [correctAnswer],
        falseAnswers: falseAnswers,
      ));
    }

    // Determine the most-common category.
    String suggestedCategory = 'General';
    if (categoryCounts.isNotEmpty) {
      suggestedCategory = categoryCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    return ExcelImportResult(
      questions: questions,
      warnings: warnings,
      suggestedTitle: _titleFromFileName(fileName),
      suggestedCategory: suggestedCategory,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Column detection
  // ──────────────────────────────────────────────────────────

  /// Holds the detected column indices.
  static _ColumnMapping? _detectColumns(List<Data?> headerRow) {
    final headers = headerRow.map((c) => _cellStr(c).toLowerCase().trim()).toList();

    // --- Strategy 1: exact/known header names ---
    int? questionCol;
    int? correctCol;
    int? referenceCol;
    final optionCols = <int>[];
    bool correctIsIndex = true;

    for (int i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (_matchesAny(h, ['question', 'q', 'question text', 'questions'])) {
        questionCol = i;
      } else if (_matchesAny(h, [
        'option_1', 'option_2', 'option_3', 'option_4', 'option_5',
        'option a', 'option b', 'option c', 'option d', 'option e',
        'a', 'b', 'c', 'd', 'e',
        'opt1', 'opt2', 'opt3', 'opt4', 'opt5',
        'choice_1', 'choice_2', 'choice_3', 'choice_4', 'choice_5',
        'choice a', 'choice b', 'choice c', 'choice d', 'choice e',
      ])) {
        optionCols.add(i);
      } else if (_matchesAny(h, ['correct', 'answer', 'correct_answer', 'correct answer', 'ans', 'key'])) {
        correctCol = i;
        // If header is "answer" or "correct_answer", likely text not index.
        if (_matchesAny(h, ['answer', 'correct_answer', 'correct answer', 'ans'])) {
          correctIsIndex = false;
        }
      } else if (_matchesAny(h, ['reference', 'category', 'topic', 'subject', 'ref'])) {
        referenceCol = i;
      }
    }

    // Auto-detect if "correct" column is index vs text by peeking at data later.
    // For now, if the header is literally "correct" we assume index (matches sample).

    if (questionCol != null && correctCol != null && optionCols.length >= 2) {
      // Sort option columns by their position to maintain order.
      optionCols.sort();
      return _ColumnMapping(
        questionCol: questionCol,
        optionCols: optionCols,
        correctCol: correctCol,
        correctIsIndex: correctIsIndex,
        referenceCol: referenceCol,
      );
    }

    // --- Strategy 2: positional fallback (no header match) ---
    // Assume: col0 = question, col1..col4 = options, col5 = correct
    if (headers.length >= 6) {
      return const _ColumnMapping(
        questionCol: 0,
        optionCols: [1, 2, 3, 4],
        correctCol: 5,
        correctIsIndex: true,
        referenceCol: null,
      );
    }

    return null;
  }

  // ──────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────

  /// Derive a clean quiz title from the file name.
  static String _titleFromFileName(String name) {
    // Remove extension.
    final noExt = name.replaceAll(RegExp(r'\.(xlsx|xls)$', caseSensitive: false), '');
    // Replace underscores / dashes with spaces and trim.
    return noExt.replaceAll(RegExp(r'[_\-]+'), ' ').trim();
  }

  /// Safely get the string value of a cell, or empty string.
  static String _cellStr(Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  /// Get string value at a specific column index, guarding bounds.
  static String _cellAt(List<Data?> row, int col) {
    if (col < 0 || col >= row.length) return '';
    return _cellStr(row[col]);
  }

  /// Check if [value] matches any of [candidates].
  static bool _matchesAny(String value, List<String> candidates) {
    return candidates.contains(value);
  }
}

/// Internal column mapping descriptor.
class _ColumnMapping {
  final int questionCol;
  final List<int> optionCols;
  final int correctCol;
  final bool correctIsIndex;
  final int? referenceCol;

  const _ColumnMapping({
    required this.questionCol,
    required this.optionCols,
    required this.correctCol,
    required this.correctIsIndex,
    this.referenceCol,
  });
}
