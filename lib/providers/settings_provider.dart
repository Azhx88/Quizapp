import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizzapp/data/models/game_settings.dart';

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, GameSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<GameSettings> {
  SettingsNotifier() : super(const GameSettings());

  void setGameMode(GameMode mode) => state = state.copyWith(gameMode: mode);
  void setTimePerQuestion(int t) => state = state.copyWith(timePerQuestion: t);
  void setNumberOfQuestions(int? n) =>
      state = state.copyWith(numberOfQuestions: n);
  void setMaxPlayers(int n) => state = state.copyWith(maxPlayers: n);
  void setAllowLateJoin(bool v) => state = state.copyWith(allowLateJoin: v);
  void setRequireNameEntry(bool v) => state = state.copyWith(requireNameEntry: v);
  void setShuffleQuestions(bool v) => state = state.copyWith(shuffleQuestions: v);
  void setShuffleAnswerOptions(bool v) =>
      state = state.copyWith(shuffleAnswerOptions: v);
  void setShowCorrectAnswer(bool v) => state = state.copyWith(showCorrectAnswer: v);
  void setShowFunFact(bool v) => state = state.copyWith(showFunFact: v);
  void setShowLeaderboard(bool v) => state = state.copyWith(showLeaderboard: v);
  void setLeaderboardFrequency(LeaderboardFrequency f) =>
      state = state.copyWith(leaderboardFrequency: f);
  void setPowerUpsEnabled(bool v) => state = state.copyWith(powerUpsEnabled: v);
  void setPowerUp50_50(bool v) => state = state.copyWith(powerUp50_50: v);
  void setPowerUpDoublePoints(bool v) =>
      state = state.copyWith(powerUpDoublePoints: v);
  void setPowerUpTimeFreeze(bool v) =>
      state = state.copyWith(powerUpTimeFreeze: v);
  void setStreakBonusEnabled(bool v) =>
      state = state.copyWith(streakBonusEnabled: v);
  void setBackgroundMusicEnabled(bool v) =>
      state = state.copyWith(backgroundMusicEnabled: v);
  void setSpeedBasedScoring(bool v) =>
      state = state.copyWith(speedBasedScoring: v);
  void setFixedScore(int v) => state = state.copyWith(fixedScore: v);
  void setNegativeMarking(bool v) => state = state.copyWith(negativeMarking: v);
  void setHideLeaderboardDuringGame(bool v) =>
      state = state.copyWith(hideLeaderboardDuringGame: v);
  void setPreventAnswerReview(bool v) =>
      state = state.copyWith(preventAnswerReview: v);
  void setOneAttemptOnly(bool v) => state = state.copyWith(oneAttemptOnly: v);
  void reset() => state = const GameSettings();
}
