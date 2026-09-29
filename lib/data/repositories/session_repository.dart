import 'package:quizzapp/data/database/session_dao.dart';
import 'package:quizzapp/data/models/player_model.dart';

class SessionRepository {
  final SessionDao _dao;
  SessionRepository(this._dao);

  Future<void> save(GameSession session) => _dao.saveSession(session);
  Future<void> saveResults(List<PlayerResult> results) => _dao.savePlayerResults(results);
  Future<List<PlayerResult>> getResults(String sessionId) =>
      _dao.getResultsForSession(sessionId);
  Future<List<GameSession>> getRecent({int limit = 20}) =>
      _dao.getRecentSessions(limit: limit);
}
