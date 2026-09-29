import 'dart:convert';

enum MessageType {
  join,
  settingsSync,
  question,
  answer,
  powerup,
  scoreUpdate,
  leaderboard,
  nextQuestion,
  gameEnd,
  playerKicked,
  playerList,
  gameStarting,
  answerResult,
  playerScoreUpdate,
  revealAnswer,
}

abstract class NetworkMessage {
  MessageType get type;
  Map<String, dynamic> toJson();

  static NetworkMessage? parse(String raw) {
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final typeStr = j['type'] as String;
      final t = MessageType.values.firstWhere(
        (e) => e.name == typeStr,
        orElse: () => MessageType.join,
      );
      switch (t) {
        case MessageType.join:          return JoinMessage.fromJson(j);
        case MessageType.settingsSync:  return SettingsSyncMessage.fromJson(j);
        case MessageType.question:      return QuestionMessage.fromJson(j);
        case MessageType.answer:        return AnswerMessage.fromJson(j);
        case MessageType.powerup:       return PowerUpMessage.fromJson(j);
        case MessageType.scoreUpdate:   return ScoreUpdateMessage.fromJson(j);
        case MessageType.leaderboard:   return LeaderboardMessage.fromJson(j);
        case MessageType.nextQuestion:  return NextQuestionMessage();
        case MessageType.gameEnd:       return GameEndMessage.fromJson(j);
        case MessageType.playerKicked:  return PlayerKickedMessage.fromJson(j);
        case MessageType.playerList:    return PlayerListMessage.fromJson(j);
        case MessageType.gameStarting:  return GameStartingMessage.fromJson(j);
        case MessageType.answerResult:       return AnswerResultMessage.fromJson(j);
        case MessageType.playerScoreUpdate:  return PlayerScoreUpdateMessage.fromJson(j);
        case MessageType.revealAnswer:       return RevealAnswerMessage();
      }
    } catch (_) {
      return null;
    }
  }

  String encode() => '${jsonEncode(toJson())}\n';
}

class JoinMessage extends NetworkMessage {
  final String name;
  final int avatarId;
  JoinMessage({required this.name, required this.avatarId});
  @override MessageType get type => MessageType.join;
  @override Map<String, dynamic> toJson() =>
      {'type': 'join', 'name': name, 'avatarId': avatarId};
  factory JoinMessage.fromJson(Map<String, dynamic> j) =>
      JoinMessage(name: j['name'] as String, avatarId: j['avatarId'] as int? ?? 0);
}

class SettingsSyncMessage extends NetworkMessage {
  final Map<String, dynamic> settings;
  SettingsSyncMessage({required this.settings});
  @override MessageType get type => MessageType.settingsSync;
  @override Map<String, dynamic> toJson() =>
      {'type': 'settingsSync', 'settings': settings};
  factory SettingsSyncMessage.fromJson(Map<String, dynamic> j) =>
      SettingsSyncMessage(settings: j['settings'] as Map<String, dynamic>);
}

class QuestionMessage extends NetworkMessage {
  final String slideType;
  final Map<String, dynamic> data;
  final int index;
  final int total;
  final int timeLimit;
  QuestionMessage({required this.slideType, required this.data,
      required this.index, required this.total, required this.timeLimit});
  @override MessageType get type => MessageType.question;
  @override Map<String, dynamic> toJson() => {
        'type': 'question',
        'slideType': slideType,
        'data': data,
        'index': index,
        'total': total,
        'timeLimit': timeLimit,
      };
  factory QuestionMessage.fromJson(Map<String, dynamic> j) => QuestionMessage(
        slideType: j['slideType'] as String,
        data: j['data'] as Map<String, dynamic>,
        index: j['index'] as int,
        total: j['total'] as int,
        timeLimit: j['timeLimit'] as int,
      );
}

class AnswerMessage extends NetworkMessage {
  final String questionId;
  final dynamic answer;
  final int timeTaken;
  AnswerMessage({required this.questionId, required this.answer, required this.timeTaken});
  @override MessageType get type => MessageType.answer;
  @override Map<String, dynamic> toJson() => {
        'type': 'answer',
        'questionId': questionId,
        'answer': answer,
        'timeTaken': timeTaken,
      };
  factory AnswerMessage.fromJson(Map<String, dynamic> j) => AnswerMessage(
        questionId: j['questionId'] as String,
        answer: j['answer'],
        timeTaken: j['timeTaken'] as int,
      );
}

class PowerUpMessage extends NetworkMessage {
  final String powerUpType;
  PowerUpMessage({required this.powerUpType});
  @override MessageType get type => MessageType.powerup;
  @override Map<String, dynamic> toJson() =>
      {'type': 'powerup', 'powerUpType': powerUpType};
  factory PowerUpMessage.fromJson(Map<String, dynamic> j) =>
      PowerUpMessage(powerUpType: j['powerUpType'] as String);
}

class ScoreUpdateMessage extends NetworkMessage {
  final List<Map<String, dynamic>> scores;
  ScoreUpdateMessage({required this.scores});
  @override MessageType get type => MessageType.scoreUpdate;
  @override Map<String, dynamic> toJson() => {'type': 'scoreUpdate', 'scores': scores};
  factory ScoreUpdateMessage.fromJson(Map<String, dynamic> j) => ScoreUpdateMessage(
        scores: (j['scores'] as List).cast<Map<String, dynamic>>(),
      );
}

class LeaderboardMessage extends NetworkMessage {
  final List<Map<String, dynamic>> data;
  final bool isFinal;
  LeaderboardMessage({required this.data, required this.isFinal});
  @override MessageType get type => MessageType.leaderboard;
  @override Map<String, dynamic> toJson() =>
      {'type': 'leaderboard', 'data': data, 'isFinal': isFinal};
  factory LeaderboardMessage.fromJson(Map<String, dynamic> j) => LeaderboardMessage(
        data: (j['data'] as List).cast<Map<String, dynamic>>(),
        isFinal: j['isFinal'] as bool? ?? false,
      );
}

class NextQuestionMessage extends NetworkMessage {
  @override MessageType get type => MessageType.nextQuestion;
  @override Map<String, dynamic> toJson() => {'type': 'nextQuestion'};
}

class GameEndMessage extends NetworkMessage {
  final List<Map<String, dynamic>> leaderboard;
  final Map<String, dynamic> stats;
  GameEndMessage({required this.leaderboard, required this.stats});
  @override MessageType get type => MessageType.gameEnd;
  @override Map<String, dynamic> toJson() =>
      {'type': 'gameEnd', 'leaderboard': leaderboard, 'stats': stats};
  factory GameEndMessage.fromJson(Map<String, dynamic> j) => GameEndMessage(
        leaderboard: (j['leaderboard'] as List).cast<Map<String, dynamic>>(),
        stats: j['stats'] as Map<String, dynamic>? ?? {},
      );
}

class PlayerKickedMessage extends NetworkMessage {
  final String name;
  PlayerKickedMessage({required this.name});
  @override MessageType get type => MessageType.playerKicked;
  @override Map<String, dynamic> toJson() => {'type': 'playerKicked', 'name': name};
  factory PlayerKickedMessage.fromJson(Map<String, dynamic> j) =>
      PlayerKickedMessage(name: j['name'] as String);
}

class PlayerListMessage extends NetworkMessage {
  final List<Map<String, dynamic>> players;
  PlayerListMessage({required this.players});
  @override MessageType get type => MessageType.playerList;
  @override Map<String, dynamic> toJson() =>
      {'type': 'playerList', 'players': players};
  factory PlayerListMessage.fromJson(Map<String, dynamic> j) => PlayerListMessage(
        players: (j['players'] as List).cast<Map<String, dynamic>>(),
      );
}

class GameStartingMessage extends NetworkMessage {
  final int countdown;
  GameStartingMessage({required this.countdown});
  @override MessageType get type => MessageType.gameStarting;
  @override Map<String, dynamic> toJson() =>
      {'type': 'gameStarting', 'countdown': countdown};
  factory GameStartingMessage.fromJson(Map<String, dynamic> j) =>
      GameStartingMessage(countdown: j['countdown'] as int? ?? 3);
}

class AnswerResultMessage extends NetworkMessage {
  final bool correct;
  final int pointsAwarded;
  final dynamic correctAnswer;
  final String? funFact;
  AnswerResultMessage({
    required this.correct,
    required this.pointsAwarded,
    this.correctAnswer,
    this.funFact,
  });
  @override MessageType get type => MessageType.answerResult;
  @override Map<String, dynamic> toJson() => {
        'type': 'answerResult',
        'correct': correct,
        'pointsAwarded': pointsAwarded,
        'correctAnswer': correctAnswer,
        'funFact': funFact,
      };
  factory AnswerResultMessage.fromJson(Map<String, dynamic> j) => AnswerResultMessage(
        correct: j['correct'] as bool,
        pointsAwarded: j['pointsAwarded'] as int,
        correctAnswer: j['correctAnswer'],
        funFact: j['funFact'] as String?,
      );
}

class RevealAnswerMessage extends NetworkMessage {
  @override MessageType get type => MessageType.revealAnswer;
  @override Map<String, dynamic> toJson() => {'type': 'revealAnswer'};
}

class PlayerScoreUpdateMessage extends NetworkMessage {
  final String name;
  final int score;
  final int correctCount;
  final int bestStreak;
  final int streak;

  PlayerScoreUpdateMessage({
    required this.name,
    required this.score,
    required this.correctCount,
    required this.bestStreak,
    required this.streak,
  });

  @override MessageType get type => MessageType.playerScoreUpdate;
  @override Map<String, dynamic> toJson() => {
        'type': 'playerScoreUpdate',
        'name': name,
        'score': score,
        'correctCount': correctCount,
        'bestStreak': bestStreak,
        'streak': streak,
      };
  factory PlayerScoreUpdateMessage.fromJson(Map<String, dynamic> j) => PlayerScoreUpdateMessage(
        name: j['name'] as String,
        score: j['score'] as int? ?? 0,
        correctCount: j['correctCount'] as int? ?? 0,
        bestStreak: j['bestStreak'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
      );
}
