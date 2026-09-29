import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:quizzapp/data/models/game_settings.dart';
import 'package:quizzapp/data/models/player_model.dart';
import 'package:quizzapp/data/models/quiz_model.dart';
import 'package:quizzapp/data/models/game_history.dart';
import 'package:quizzapp/providers/history_provider.dart';
import 'package:quizzapp/utils/constants.dart';

class GameSessionState {
  final String? pin;
  final Quiz? quiz;
  final GameSettings settings;
  final List<PlayerScore> players;
  final int currentQuestionIndex;
  final bool isActive;
  final bool isHost;
  final PlayerScore? localPlayer;
  final AnswerState answerState;
  final List<Map<String, dynamic>> leaderboard;
  final bool showingLeaderboard;
  final Question? receivedQuestion;
  final int? receivedTimeLimit;

  const GameSessionState({
    this.pin,
    this.quiz,
    this.settings = const GameSettings(),
    this.players = const [],
    this.currentQuestionIndex = 0,
    this.isActive = false,
    this.isHost = false,
    this.localPlayer,
    this.answerState = const AnswerState(),
    this.leaderboard = const [],
    this.showingLeaderboard = false,
    this.receivedQuestion,
    this.receivedTimeLimit,
  });

  bool get isClient => !isHost;

  Question? get currentQuestion {
    if (quiz != null) {
      if (currentQuestionIndex >= quiz!.questions.length) return null;
      return quiz!.questions[currentQuestionIndex];
    }
    return receivedQuestion;
  }

  int computeScore({required int timeTaken, required int timeLimit}) {
    if (!settings.speedBasedScoring) return settings.fixedScore;
    final ratio = 1.0 - (timeTaken / (timeLimit == 0 ? 1 : timeLimit));
    return (kMaxScore * ratio.clamp(0.0, 1.0)).round();
  }

  GameSessionState copyWith({
    Object? pin = _s,
    Object? quiz = _s,
    GameSettings? settings,
    List<PlayerScore>? players,
    int? currentQuestionIndex,
    bool? isActive,
    bool? isHost,
    Object? localPlayer = _s,
    AnswerState? answerState,
    List<Map<String, dynamic>>? leaderboard,
    bool? showingLeaderboard,
    Object? receivedQuestion = _s,
    Object? receivedTimeLimit = _s,
  }) =>
      GameSessionState(
        pin: pin == _s ? this.pin : pin as String?,
        quiz: quiz == _s ? this.quiz : quiz as Quiz?,
        settings: settings ?? this.settings,
        players: players ?? this.players,
        currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
        isActive: isActive ?? this.isActive,
        isHost: isHost ?? this.isHost,
        localPlayer: localPlayer == _s ? this.localPlayer : localPlayer as PlayerScore?,
        answerState: answerState ?? this.answerState,
        leaderboard: leaderboard ?? this.leaderboard,
        showingLeaderboard: showingLeaderboard ?? this.showingLeaderboard,
        receivedQuestion: receivedQuestion == _s ? this.receivedQuestion : receivedQuestion as Question?,
        receivedTimeLimit: receivedTimeLimit == _s ? this.receivedTimeLimit : receivedTimeLimit as int?,
      );
}

class AnswerState {
  final bool hasAnswered;
  final dynamic selectedAnswer;
  final bool? isCorrect;
  final int pointsAwarded;
  final dynamic correctAnswer;
  final String? funFact;
  final bool isRevealed;

  const AnswerState({
    this.hasAnswered = false,
    this.selectedAnswer,
    this.isCorrect,
    this.pointsAwarded = 0,
    this.correctAnswer,
    this.funFact,
    this.isRevealed = false,
  });

  AnswerState copyWith({
    bool? hasAnswered,
    dynamic selectedAnswer,
    bool? isCorrect,
    int? pointsAwarded,
    dynamic correctAnswer,
    String? funFact,
    bool? isRevealed,
  }) =>
      AnswerState(
        hasAnswered: hasAnswered ?? this.hasAnswered,
        selectedAnswer: selectedAnswer ?? this.selectedAnswer,
        isCorrect: isCorrect ?? this.isCorrect,
        pointsAwarded: pointsAwarded ?? this.pointsAwarded,
        correctAnswer: correctAnswer ?? this.correctAnswer,
        funFact: funFact ?? this.funFact,
        isRevealed: isRevealed ?? this.isRevealed,
      );

  AnswerState reset() => const AnswerState();
}

final gameSessionProvider =
    StateNotifierProvider<GameSessionNotifier, GameSessionState>((ref) {
  return GameSessionNotifier(ref);
});

class GameSessionNotifier extends StateNotifier<GameSessionState> {
  final Ref ref;
  GameSessionNotifier(this.ref) : super(const GameSessionState());

  String generatePin() {
    final pin = (Random().nextInt(900000) + 100000).toString();
    state = state.copyWith(pin: pin);
    return pin;
  }

  void startHostSession(Quiz quiz, GameSettings settings) {
    final pin = generatePin();
    state = GameSessionState(
      pin: pin,
      quiz: quiz,
      settings: settings,
      isHost: true,
      isActive: true,
    );
  }

  void startClientSession(PlayerScore player) {
    state = state.copyWith(localPlayer: player, isHost: false, isActive: true);
  }

  void addPlayer(PlayerScore player) {
    if (state.players.any((p) => p.name == player.name)) return;
    state = state.copyWith(players: [...state.players, player]);
  }

  void removePlayer(String name) {
    state = state.copyWith(
      players: state.players.where((p) => p.name != name).toList(),
    );
  }

  void updateScores(List<Map<String, dynamic>> scores) {
    final updated = scores.map(PlayerScore.fromJson).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < updated.length; i++) {
      updated[i].rank = i + 1;
    }
    state = state.copyWith(players: updated);
  }

  void setLeaderboard(List<Map<String, dynamic>> data) {
    state = state.copyWith(leaderboard: data, showingLeaderboard: true);
  }

  void hideLeaderboard() => state = state.copyWith(showingLeaderboard: false);

  void advanceQuestion() {
    state = state.copyWith(
      currentQuestionIndex: state.currentQuestionIndex + 1,
      answerState: const AnswerState(),
      showingLeaderboard: false,
    );
  }

  void receiveQuestion(Question q, {int? timeLimit}) {
    state = state.copyWith(
      receivedQuestion: q,
      receivedTimeLimit: timeLimit,
      answerState: const AnswerState(),
      showingLeaderboard: false,
    );
  }

  void setAnswerState(AnswerState ans) => state = state.copyWith(answerState: ans);

  void revealAnswerUI() {
    state = state.copyWith(
      answerState: state.answerState.copyWith(isRevealed: true),
    );
  }

  void submitAnswer(dynamic answer) {
    if (state.answerState.hasAnswered) return;
    state = state.copyWith(
      answerState: state.answerState.copyWith(
        hasAnswered: true,
        selectedAnswer: answer,
      ),
    );
  }

  void revealAnswer({
    required bool correct,
    required int points,
    required dynamic correctAnswer,
    String? funFact,
  }) {
    state = state.copyWith(
      answerState: state.answerState.copyWith(
        isCorrect: correct,
        pointsAwarded: points,
        correctAnswer: correctAnswer,
        funFact: funFact,
      ),
    );
    if (state.localPlayer != null) {
      final lp = state.localPlayer!;
      final newStreak = correct ? lp.streak + 1 : 0;
      final newBestStreak = newStreak > lp.bestStreak ? newStreak : lp.bestStreak;
      state = state.copyWith(
        localPlayer: PlayerScore(
          name: lp.name,
          avatarId: lp.avatarId,
          score: lp.score + points,
          streak: newStreak,
          correctCount: lp.correctCount + (correct ? 1 : 0),
          bestStreak: newBestStreak,
          rank: lp.rank,
          delta: lp.delta,
          avgTime: lp.avgTime,
          usedPowerUp50: lp.usedPowerUp50,
          usedPowerUpDouble: lp.usedPowerUpDouble,
          usedPowerUpFreeze: lp.usedPowerUpFreeze,
        ),
      );
    }
  }

  void updatePlayerScore({
    required String name,
    required int score,
    required int correctCount,
    required int bestStreak,
    required int streak,
  }) {
    final updated = state.players.map((p) {
      if (p.name != name) return p;
      return PlayerScore(
        name: p.name,
        avatarId: p.avatarId,
        score: score,
        streak: streak,
        correctCount: correctCount,
        bestStreak: bestStreak,
        rank: p.rank,
        delta: p.delta,
        avgTime: p.avgTime,
        usedPowerUp50: p.usedPowerUp50,
        usedPowerUpDouble: p.usedPowerUpDouble,
        usedPowerUpFreeze: p.usedPowerUpFreeze,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < updated.length; i++) {
      updated[i].rank = i + 1;
    }
    state = state.copyWith(players: updated);
  }

  void endSession() {
    if (!state.isActive) return;

    final title = state.isHost
        ? 'Hosted: ${state.quiz?.title ?? 'Quiz'}'
        : 'Played Quiz';

    final score = state.isHost ? 0 : (state.localPlayer?.score ?? 0);
    final rank = state.isHost ? 0 : (state.localPlayer?.rank ?? 0);

    final playerDetails = state.isHost && state.players.isNotEmpty
        ? jsonEncode(state.players.map((p) => p.toJson()).toList())
        : null;

    final history = GameHistory(
      id: const Uuid().v4(),
      title: title,
      isHost: state.isHost,
      score: score,
      rank: rank,
      totalPlayers: state.players.length,
      playedAt: DateTime.now(),
      quizTitle: state.quiz?.title,
      playerDetails: playerDetails,
    );

    ref.read(historyProvider.notifier).addHistory(history);
    state = state.copyWith(isActive: false);
  }

  void reset() => state = const GameSessionState();
}

const Object _s = Object();
