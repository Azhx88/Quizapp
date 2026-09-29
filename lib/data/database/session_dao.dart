import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/models/player_model.dart';

class GameSession {
  final String id;
  final String quizId;
  final Map<String, dynamic> settings;
  final DateTime playedAt;
  final int playerCount;

  const GameSession({
    required this.id,
    required this.quizId,
    required this.settings,
    required this.playedAt,
    required this.playerCount,
  });
}

class SessionDao {
  final AppDatabase _db;
  SessionDao(this._db);

  Future<void> saveSession(GameSession session) async {
    final db = await _db.db;
    await db.insert(
      'game_sessions',
      {
        'id': session.id,
        'quizId': session.quizId,
        'settings': jsonEncode(session.settings),
        'playedAt': session.playedAt.millisecondsSinceEpoch,
        'playerCount': session.playerCount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> savePlayerResults(List<PlayerResult> results) async {
    final db = await _db.db;
    final batch = db.batch();
    for (final r in results) {
      batch.insert('player_results', r.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<PlayerResult>> getResultsForSession(String sessionId) async {
    final db = await _db.db;
    final rows = await db.query(
      'player_results',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'score DESC',
    );
    return rows.map(PlayerResult.fromMap).toList();
  }

  Future<List<GameSession>> getRecentSessions({int limit = 20}) async {
    final db = await _db.db;
    final rows = await db.query(
      'game_sessions',
      orderBy: 'playedAt DESC',
      limit: limit,
    );
    return rows
        .map((r) => GameSession(
              id: r['id'] as String,
              quizId: r['quizId'] as String,
              settings: jsonDecode(r['settings'] as String) as Map<String, dynamic>,
              playedAt: DateTime.fromMillisecondsSinceEpoch(r['playedAt'] as int),
              playerCount: r['playerCount'] as int,
            ))
        .toList();
  }
}
