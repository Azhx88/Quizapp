import 'dart:convert';
import 'package:quizzapp/data/models/slide_type.dart';

class Quiz {
  final String id;
  final String title;
  final String category;
  final DateTime createdAt;
  final List<Question> questions;

  const Quiz({
    required this.id,
    required this.title,
    required this.category,
    required this.createdAt,
    this.questions = const [],
  });

  Quiz copyWith({
    String? id,
    String? title,
    String? category,
    DateTime? createdAt,
    List<Question>? questions,
  }) =>
      Quiz(
        id: id ?? this.id,
        title: title ?? this.title,
        category: category ?? this.category,
        createdAt: createdAt ?? this.createdAt,
        questions: questions ?? this.questions,
      );
}

class Question {
  final String id;
  final String quizId;
  final SlideType slideType;
  final String question;
  final String? mediaPath;
  final String? funFact;
  final String? funFactMediaPath;

  // Buttons / Checkboxes
  final List<String> correctAnswers;
  final List<String> falseAnswers;

  // Reorder
  final List<String> orderedItems;

  // Range
  final double? correctValue;
  final String? unit;
  final double? minValue;
  final double? maxValue;
  final bool requireExactAnswer;

  // Type answer
  final String? typeAnswer;

  const Question({
    required this.id,
    required this.quizId,
    required this.slideType,
    required this.question,
    this.mediaPath,
    this.funFact,
    this.funFactMediaPath,
    this.correctAnswers = const [],
    this.falseAnswers = const [],
    this.orderedItems = const [],
    this.correctValue,
    this.unit,
    this.minValue,
    this.maxValue,
    this.requireExactAnswer = false,
    this.typeAnswer,
  });

  Question copyWith({
    String? id,
    String? quizId,
    SlideType? slideType,
    String? question,
    Object? mediaPath = _s,
    Object? funFact = _s,
    Object? funFactMediaPath = _s,
    List<String>? correctAnswers,
    List<String>? falseAnswers,
    List<String>? orderedItems,
    Object? correctValue = _s,
    Object? unit = _s,
    Object? minValue = _s,
    Object? maxValue = _s,
    bool? requireExactAnswer,
    Object? typeAnswer = _s,
  }) =>
      Question(
        id: id ?? this.id,
        quizId: quizId ?? this.quizId,
        slideType: slideType ?? this.slideType,
        question: question ?? this.question,
        mediaPath: mediaPath == _s ? this.mediaPath : mediaPath as String?,
        funFact: funFact == _s ? this.funFact : funFact as String?,
        funFactMediaPath: funFactMediaPath == _s ? this.funFactMediaPath : funFactMediaPath as String?,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        falseAnswers: falseAnswers ?? this.falseAnswers,
        orderedItems: orderedItems ?? this.orderedItems,
        correctValue: correctValue == _s ? this.correctValue : correctValue as double?,
        unit: unit == _s ? this.unit : unit as String?,
        minValue: minValue == _s ? this.minValue : minValue as double?,
        maxValue: maxValue == _s ? this.maxValue : maxValue as double?,
        requireExactAnswer: requireExactAnswer ?? this.requireExactAnswer,
        typeAnswer: typeAnswer == _s ? this.typeAnswer : typeAnswer as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'quizId': quizId,
        'slideType': slideType.name,
        'question': question,
        'mediaPath': mediaPath,
        'funFact': funFact,
        'funFactMediaPath': funFactMediaPath,
        'correctAnswers': jsonEncode(correctAnswers),
        'falseAnswers': jsonEncode(falseAnswers),
        'orderedItems': jsonEncode(orderedItems),
        'correctValue': correctValue,
        'unit': unit,
        'minValue': minValue,
        'maxValue': maxValue,
        'requireExactAnswer': requireExactAnswer ? 1 : 0,
        'typeAnswer': typeAnswer,
      };

  factory Question.fromMap(Map<String, dynamic> m) => Question(
        id: m['id'] as String,
        quizId: m['quizId'] as String,
        slideType: SlideType.values.firstWhere((e) => e.name == m['slideType']),
        question: m['question'] as String,
        mediaPath: m['mediaPath'] as String?,
        funFact: m['funFact'] as String?,
        funFactMediaPath: m['funFactMediaPath'] as String?,
        correctAnswers: _decodeList(m['correctAnswers']),
        falseAnswers: _decodeList(m['falseAnswers']),
        orderedItems: _decodeList(m['orderedItems']),
        correctValue: (m['correctValue'] as num?)?.toDouble(),
        unit: m['unit'] as String?,
        minValue: (m['minValue'] as num?)?.toDouble(),
        maxValue: (m['maxValue'] as num?)?.toDouble(),
        requireExactAnswer: (m['requireExactAnswer'] as int? ?? 0) == 1,
        typeAnswer: m['typeAnswer'] as String?,
      );
}

List<String> _decodeList(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) return raw.cast<String>();
  try {
    final decoded = jsonDecode(raw as String);
    if (decoded is List) return decoded.cast<String>();
  } catch (_) {}
  return [];
}

const Object _s = Object();
