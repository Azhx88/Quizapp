import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/models/game_history.dart';

class HistoryDao {
  final AppDatabase _db;
  HistoryDao(this._db);

  Future<List<GameHistory>> getHistory() async {
    final db = await _db.db;
    final rows = await db.query('game_history', orderBy: 'playedAt DESC');
    final result = <GameHistory>[];
    for (final row in rows) {
      try {
        result.add(GameHistory.fromMap(row));
      } catch (_) {}
    }
    return result;
  }

  Future<void> addHistory(GameHistory history) async {
    final db = await _db.db;
    await db.insert('game_history', history.toMap());
  }

  Future<void> clearHistory() async {
    final db = await _db.db;
    await db.delete('game_history');
  }
}
