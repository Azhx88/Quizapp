import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/slide_type.dart';

/// One concrete reason a slide isn't ready to be hosted. `slideIndex` is
/// 0-based; UI should show it as `Slide ${slideIndex + 1}`.
class SlideValidationIssue {
  final int slideIndex;
  final String reason;
  const SlideValidationIssue({required this.slideIndex, required this.reason});

  @override
  String toString() => 'Slide ${slideIndex + 1}: $reason';
}

/// Walks every slide in [quiz] and returns the list of issues that would make
/// the quiz incomplete to host. Empty list = ready to host.
///
/// Rules per slide type:
///   * All slides require a non-empty `question` (info slides are allowed to
///     use the question field as the headline).
///   * `buttons`     → at least one non-empty correct answer + at least one
///                     non-empty wrong answer.
///   * `checkboxes`  → at least one correct + at least one wrong.
///   * `reorder`     → at least 2 ordered items (all non-empty).
///   * `range`       → numeric correct value + min <= correct <= max.
///   * `typeAnswer`  → non-empty expected answer.
///   * `infoSlide`   → only the question/headline is required.
List<SlideValidationIssue> validateQuiz(Quiz quiz) {
  final issues = <SlideValidationIssue>[];

  if (quiz.questions.isEmpty) {
    issues.add(const SlideValidationIssue(
        slideIndex: 0, reason: 'add at least one slide'));
    return issues;
  }

  for (int i = 0; i < quiz.questions.length; i++) {
    final q = quiz.questions[i];
    final reasons = _validateSlide(q);
    for (final r in reasons) {
      issues.add(SlideValidationIssue(slideIndex: i, reason: r));
    }
  }

  return issues;
}

List<String> _validateSlide(Question q) {
  final reasons = <String>[];

  if (q.question.trim().isEmpty) {
    reasons.add('question text is empty');
  }

  switch (q.slideType) {
    case SlideType.buttons:
      final correct = q.correctAnswers.where((s) => s.trim().isNotEmpty).toList();
      final wrong = q.falseAnswers.where((s) => s.trim().isNotEmpty).toList();
      if (correct.isEmpty) reasons.add('add a correct answer');
      if (wrong.isEmpty) reasons.add('add at least one wrong answer');
      break;

    case SlideType.checkboxes:
      final correct = q.correctAnswers.where((s) => s.trim().isNotEmpty).toList();
      final wrong = q.falseAnswers.where((s) => s.trim().isNotEmpty).toList();
      if (correct.isEmpty) reasons.add('add at least one correct answer');
      if (wrong.isEmpty) reasons.add('add at least one wrong answer');
      break;

    case SlideType.reorder:
      final items = q.orderedItems.where((s) => s.trim().isNotEmpty).toList();
      if (items.length < 2) reasons.add('add at least 2 ordered items');
      break;

    case SlideType.range:
      if (q.correctValue == null) {
        reasons.add('set the correct value');
      } else if (q.minValue != null && q.maxValue != null) {
        if (q.minValue! >= q.maxValue!) {
          reasons.add('min must be less than max');
        } else if (q.correctValue! < q.minValue! ||
            q.correctValue! > q.maxValue!) {
          reasons.add('correct value must be within min/max range');
        }
      }
      break;

    case SlideType.typeAnswer:
      if ((q.typeAnswer ?? '').trim().isEmpty) {
        reasons.add('set the expected typed answer');
      }
      break;

    case SlideType.infoSlide:
      // Question text is sufficient — already checked above.
      break;
  }

  return reasons;
}
