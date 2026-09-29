import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/database/quiz_dao.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/repositories/quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return QuizRepository(QuizDao(AppDatabase.instance));
});

final quizListProvider = FutureProvider<List<Quiz>>((ref) {
  return ref.watch(quizRepositoryProvider).getAll();
});

final quizDetailProvider = FutureProvider.family<Quiz?, String>((ref, id) {
  return ref.watch(quizRepositoryProvider).getById(id);
});

// Active quiz being edited in creator
final activeQuizProvider = StateNotifierProvider<ActiveQuizNotifier, Quiz?>((ref) {
  return ActiveQuizNotifier(ref.watch(quizRepositoryProvider));
});

class ActiveQuizNotifier extends StateNotifier<Quiz?> {
  final QuizRepository _repo;
  ActiveQuizNotifier(this._repo) : super(null);

  void load(Quiz quiz) => state = quiz;

  void clear() => state = null;

  void updateTitle(String title) {
    if (state == null) return;
    state = state!.copyWith(title: title);
  }

  void updateCategory(String category) {
    if (state == null) return;
    state = state!.copyWith(category: category);
  }

  void addQuestion(Question q) {
    if (state == null) return;
    state = state!.copyWith(questions: [...state!.questions, q]);
  }

  void updateQuestion(int index, Question q) {
    if (state == null) return;
    final qs = List<Question>.from(state!.questions);
    qs[index] = q;
    state = state!.copyWith(questions: qs);
  }

  void removeQuestion(int index) {
    if (state == null) return;
    final qs = List<Question>.from(state!.questions)..removeAt(index);
    state = state!.copyWith(questions: qs);
  }

  void reorderQuestions(int oldIndex, int newIndex) {
    if (state == null) return;
    final qs = List<Question>.from(state!.questions);
    final item = qs.removeAt(oldIndex);
    qs.insert(newIndex, item);
    state = state!.copyWith(questions: qs);
  }

  Future<void> save() async {
    if (state != null) await _repo.save(state!);
  }

  Future<void> delete() async {
    if (state != null) {
      await _repo.delete(state!.id);
      state = null;
    }
  }
}
