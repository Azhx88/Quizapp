import 'package:sqflite/sqflite.dart';
import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/models/quiz_model.dart';

class QuizDao {
  final AppDatabase _db;
  QuizDao(this._db);

  Future<List<Quiz>> getAllQuizzes() async {
    final db = await _db.db;
    final rows = await db.query('quizzes', orderBy: 'createdAt DESC');
    final quizzes = <Quiz>[];
    for (final row in rows) {
      final questions = await getQuestionsForQuiz(row['id'] as String);
      quizzes.add(Quiz(
        id: row['id'] as String,
        title: row['title'] as String,
        category: row['category'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
        questions: questions,
      ));
    }
    return quizzes;
  }

  Future<Quiz?> getQuizById(String id) async {
    final db = await _db.db;
    final rows = await db.query('quizzes', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final questions = await getQuestionsForQuiz(id);
    final row = rows.first;
    return Quiz(
      id: row['id'] as String,
      title: row['title'] as String,
      category: row['category'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['createdAt'] as int),
      questions: questions,
    );
  }

  Future<List<Question>> getQuestionsForQuiz(String quizId) async {
    final db = await _db.db;
    final rows = await db.query(
      'questions',
      where: 'quizId = ?',
      whereArgs: [quizId],
      orderBy: 'sortOrder ASC',
    );
    return rows.map(Question.fromMap).toList();
  }

  Future<void> upsertQuiz(Quiz quiz) async {
    final db = await _db.db;
    await db.insert(
      'quizzes',
      {
        'id': quiz.id,
        'title': quiz.title,
        'category': quiz.category,
        'createdAt': quiz.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    for (int i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final map = q.toMap()..['sortOrder'] = i;
      await db.insert('questions', map, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  Future<void> deleteQuiz(String id) async {
    final db = await _db.db;
    await db.delete('quizzes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> upsertQuestion(Question q, int sortOrder) async {
    final db = await _db.db;
    final map = q.toMap()..['sortOrder'] = sortOrder;
    await db.insert('questions', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteQuestion(String id) async {
    final db = await _db.db;
    await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> quizCount() async {
    final db = await _db.db;
    final result = await db.rawQuery('SELECT COUNT(*) as c FROM quizzes');
    return result.first['c'] as int;
  }
}
