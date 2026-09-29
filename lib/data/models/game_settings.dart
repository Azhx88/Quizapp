enum GameMode { classic, instructorPaced, teamVsTeam }

enum LeaderboardFrequency { everyQuestion, every3, endOnly }

class GameSettings {
  final GameMode gameMode;

  // Primary
  final int timePerQuestion;
  final int? numberOfQuestions; // null = all
  final int maxPlayers;
  final bool allowLateJoin;
  final bool requireNameEntry;

  // Question
  final bool shuffleQuestions;
  final bool shuffleAnswerOptions;
  final bool showCorrectAnswer;
  final bool showFunFact;

  // Gamification
  final bool showLeaderboard;
  final LeaderboardFrequency leaderboardFrequency;
  final bool powerUpsEnabled;
  final bool powerUp50_50;
  final bool powerUpDoublePoints;
  final bool powerUpTimeFreeze;
  final bool streakBonusEnabled;
  final bool backgroundMusicEnabled;
  final bool showFunFactGlobal;

  // Scoring
  final bool speedBasedScoring;
  final int fixedScore;
  final bool negativeMarking;
  final bool rangeProximityScoring;
  final bool partialCreditTeamMode;

  // Anti-cheat
  final bool hideLeaderboardDuringGame;
  final bool preventAnswerReview;
  final bool oneAttemptOnly;

  const GameSettings({
    this.gameMode = GameMode.classic,
    this.timePerQuestion = 30,
    this.numberOfQuestions,
    this.maxPlayers = 20,
    this.allowLateJoin = true,
    this.requireNameEntry = true,
    this.shuffleQuestions = false,
    this.shuffleAnswerOptions = true,
    this.showCorrectAnswer = true,
    this.showFunFact = true,
    this.showLeaderboard = true,
    this.leaderboardFrequency = LeaderboardFrequency.everyQuestion,
    this.powerUpsEnabled = false,
    this.powerUp50_50 = true,
    this.powerUpDoublePoints = true,
    this.powerUpTimeFreeze = true,
    this.streakBonusEnabled = true,
    this.backgroundMusicEnabled = false,
    this.showFunFactGlobal = true,
    this.speedBasedScoring = true,
    this.fixedScore = 100,
    this.negativeMarking = false,
    this.rangeProximityScoring = true,
    this.partialCreditTeamMode = false,
    this.hideLeaderboardDuringGame = false,
    this.preventAnswerReview = false,
    this.oneAttemptOnly = false,
  });

  GameSettings copyWith({
    GameMode? gameMode,
    int? timePerQuestion,
    Object? numberOfQuestions = _sentinel,
    int? maxPlayers,
    bool? allowLateJoin,
    bool? requireNameEntry,
    bool? shuffleQuestions,
    bool? shuffleAnswerOptions,
    bool? showCorrectAnswer,
    bool? showFunFact,
    bool? showLeaderboard,
    LeaderboardFrequency? leaderboardFrequency,
    bool? powerUpsEnabled,
    bool? powerUp50_50,
    bool? powerUpDoublePoints,
    bool? powerUpTimeFreeze,
    bool? streakBonusEnabled,
    bool? backgroundMusicEnabled,
    bool? showFunFactGlobal,
    bool? speedBasedScoring,
    int? fixedScore,
    bool? negativeMarking,
    bool? rangeProximityScoring,
    bool? partialCreditTeamMode,
    bool? hideLeaderboardDuringGame,
    bool? preventAnswerReview,
    bool? oneAttemptOnly,
  }) {
    return GameSettings(
      gameMode: gameMode ?? this.gameMode,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
      numberOfQuestions: numberOfQuestions == _sentinel
          ? this.numberOfQuestions
          : numberOfQuestions as int?,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      allowLateJoin: allowLateJoin ?? this.allowLateJoin,
      requireNameEntry: requireNameEntry ?? this.requireNameEntry,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleAnswerOptions: shuffleAnswerOptions ?? this.shuffleAnswerOptions,
      showCorrectAnswer: showCorrectAnswer ?? this.showCorrectAnswer,
      showFunFact: showFunFact ?? this.showFunFact,
      showLeaderboard: showLeaderboard ?? this.showLeaderboard,
      leaderboardFrequency: leaderboardFrequency ?? this.leaderboardFrequency,
      powerUpsEnabled: powerUpsEnabled ?? this.powerUpsEnabled,
      powerUp50_50: powerUp50_50 ?? this.powerUp50_50,
      powerUpDoublePoints: powerUpDoublePoints ?? this.powerUpDoublePoints,
      powerUpTimeFreeze: powerUpTimeFreeze ?? this.powerUpTimeFreeze,
      streakBonusEnabled: streakBonusEnabled ?? this.streakBonusEnabled,
      backgroundMusicEnabled: backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      showFunFactGlobal: showFunFactGlobal ?? this.showFunFactGlobal,
      speedBasedScoring: speedBasedScoring ?? this.speedBasedScoring,
      fixedScore: fixedScore ?? this.fixedScore,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      rangeProximityScoring: rangeProximityScoring ?? this.rangeProximityScoring,
      partialCreditTeamMode: partialCreditTeamMode ?? this.partialCreditTeamMode,
      hideLeaderboardDuringGame: hideLeaderboardDuringGame ?? this.hideLeaderboardDuringGame,
      preventAnswerReview: preventAnswerReview ?? this.preventAnswerReview,
      oneAttemptOnly: oneAttemptOnly ?? this.oneAttemptOnly,
    );
  }

  Map<String, dynamic> toJson() => {
        'gameMode': gameMode.index,
        'timePerQuestion': timePerQuestion,
        'numberOfQuestions': numberOfQuestions,
        'maxPlayers': maxPlayers,
        'allowLateJoin': allowLateJoin,
        'requireNameEntry': requireNameEntry,
        'shuffleQuestions': shuffleQuestions,
        'shuffleAnswerOptions': shuffleAnswerOptions,
        'showCorrectAnswer': showCorrectAnswer,
        'showFunFact': showFunFact,
        'showLeaderboard': showLeaderboard,
        'leaderboardFrequency': leaderboardFrequency.index,
        'powerUpsEnabled': powerUpsEnabled,
        'powerUp50_50': powerUp50_50,
        'powerUpDoublePoints': powerUpDoublePoints,
        'powerUpTimeFreeze': powerUpTimeFreeze,
        'streakBonusEnabled': streakBonusEnabled,
        'backgroundMusicEnabled': backgroundMusicEnabled,
        'showFunFactGlobal': showFunFactGlobal,
        'speedBasedScoring': speedBasedScoring,
        'fixedScore': fixedScore,
        'negativeMarking': negativeMarking,
        'rangeProximityScoring': rangeProximityScoring,
        'partialCreditTeamMode': partialCreditTeamMode,
        'hideLeaderboardDuringGame': hideLeaderboardDuringGame,
        'preventAnswerReview': preventAnswerReview,
        'oneAttemptOnly': oneAttemptOnly,
      };

  factory GameSettings.fromJson(Map<String, dynamic> j) => GameSettings(
        gameMode: GameMode.values[j['gameMode'] as int? ?? 0],
        timePerQuestion: j['timePerQuestion'] as int? ?? 30,
        numberOfQuestions: j['numberOfQuestions'] as int?,
        maxPlayers: j['maxPlayers'] as int? ?? 20,
        allowLateJoin: j['allowLateJoin'] as bool? ?? true,
        requireNameEntry: j['requireNameEntry'] as bool? ?? true,
        shuffleQuestions: j['shuffleQuestions'] as bool? ?? false,
        shuffleAnswerOptions: j['shuffleAnswerOptions'] as bool? ?? true,
        showCorrectAnswer: j['showCorrectAnswer'] as bool? ?? true,
        showFunFact: j['showFunFact'] as bool? ?? true,
        showLeaderboard: j['showLeaderboard'] as bool? ?? true,
        leaderboardFrequency:
            LeaderboardFrequency.values[j['leaderboardFrequency'] as int? ?? 0],
        powerUpsEnabled: j['powerUpsEnabled'] as bool? ?? false,
        powerUp50_50: j['powerUp50_50'] as bool? ?? true,
        powerUpDoublePoints: j['powerUpDoublePoints'] as bool? ?? true,
        powerUpTimeFreeze: j['powerUpTimeFreeze'] as bool? ?? true,
        streakBonusEnabled: j['streakBonusEnabled'] as bool? ?? true,
        backgroundMusicEnabled: j['backgroundMusicEnabled'] as bool? ?? false,
        showFunFactGlobal: j['showFunFactGlobal'] as bool? ?? true,
        speedBasedScoring: j['speedBasedScoring'] as bool? ?? true,
        fixedScore: j['fixedScore'] as int? ?? 100,
        negativeMarking: j['negativeMarking'] as bool? ?? false,
        rangeProximityScoring: j['rangeProximityScoring'] as bool? ?? true,
        partialCreditTeamMode: j['partialCreditTeamMode'] as bool? ?? false,
        hideLeaderboardDuringGame: j['hideLeaderboardDuringGame'] as bool? ?? false,
        preventAnswerReview: j['preventAnswerReview'] as bool? ?? false,
        oneAttemptOnly: j['oneAttemptOnly'] as bool? ?? false,
      );
}

// Sentinel for nullable copyWith
const Object _sentinel = Object();
