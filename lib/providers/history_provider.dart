import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/data/database/app_database.dart';
import 'package:quizzapp/data/database/history_dao.dart';
import 'package:quizzapp/data/models/game_history.dart';

final historyDaoProvider = Provider((ref) => HistoryDao(AppDatabase.instance));

final historyProvider = StateNotifierProvider<HistoryNotifier, List<GameHistory>>((ref) {
  return HistoryNotifier(ref.watch(historyDaoProvider));
});

class HistoryNotifier extends StateNotifier<List<GameHistory>> {
  final HistoryDao _dao;

  HistoryNotifier(this._dao) : super([]) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      state = await _dao.getHistory();
    } catch (_) {}
  }

  Future<void> addHistory(GameHistory history) async {
    try {
      await _dao.addHistory(history);
    } catch (_) {}
    await loadHistory();
  }
}
