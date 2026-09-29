import 'package:quizzapp/data/database/quiz_dao.dart';
import 'package:quizzapp/data/models/quiz_model.dart';

class QuizRepository {
  final QuizDao _dao;
  QuizRepository(this._dao);

  Future<List<Quiz>> getAll() => _dao.getAllQuizzes();
  Future<Quiz?> getById(String id) => _dao.getQuizById(id);
  Future<void> save(Quiz quiz) => _dao.upsertQuiz(quiz);
  Future<void> delete(String id) => _dao.deleteQuiz(id);
  Future<void> saveQuestion(Question q, int order) => _dao.upsertQuestion(q, order);
  Future<void> deleteQuestion(String id) => _dao.deleteQuestion(id);
  Future<int> count() => _dao.quizCount();
}
