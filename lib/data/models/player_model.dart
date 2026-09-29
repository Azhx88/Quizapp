class Player {
  final String name;
  final int avatarId;
  final String? address; // host-side only

  const Player({required this.name, required this.avatarId, this.address});

  Map<String, dynamic> toJson() =>
      {'name': name, 'avatarId': avatarId};

  factory Player.fromJson(Map<String, dynamic> j) => Player(
        name: j['name'] as String,
        avatarId: j['avatarId'] as int? ?? 0,
      );
}

class PlayerScore {
  final String name;
  final int avatarId;
  int score;
  int streak;
  int correctCount;
  int rank;
  int delta;
  double avgTime;
  int bestStreak;
  bool usedPowerUp50;
  bool usedPowerUpDouble;
  bool usedPowerUpFreeze;

  PlayerScore({
    required this.name,
    required this.avatarId,
    this.score = 0,
    this.streak = 0,
    this.correctCount = 0,
    this.rank = 0,
    this.delta = 0,
    this.avgTime = 0,
    this.bestStreak = 0,
    this.usedPowerUp50 = false,
    this.usedPowerUpDouble = false,
    this.usedPowerUpFreeze = false,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'avatarId': avatarId,
        'score': score,
        'streak': streak,
        'rank': rank,
        'delta': delta,
        'correctCount': correctCount,
        'bestStreak': bestStreak,
        'avgTime': avgTime,
      };

  factory PlayerScore.fromJson(Map<String, dynamic> j) => PlayerScore(
        name: j['name'] as String,
        avatarId: j['avatarId'] as int? ?? 0,
        score: j['score'] as int? ?? 0,
        streak: j['streak'] as int? ?? 0,
        rank: j['rank'] as int? ?? 0,
        delta: j['delta'] as int? ?? 0,
        correctCount: j['correctCount'] as int? ?? 0,
        bestStreak: j['bestStreak'] as int? ?? 0,
        avgTime: (j['avgTime'] as num?)?.toDouble() ?? 0.0,
      );
}

class PlayerResult {
  final String sessionId;
  final String playerName;
  final int score;
  final int correctCount;
  final double avgTime;
  final int bestStreak;

  const PlayerResult({
    required this.sessionId,
    required this.playerName,
    required this.score,
    required this.correctCount,
    required this.avgTime,
    required this.bestStreak,
  });

  Map<String, dynamic> toMap() => {
        'sessionId': sessionId,
        'playerName': playerName,
        'score': score,
        'correctCount': correctCount,
        'avgTime': avgTime,
        'bestStreak': bestStreak,
      };

  factory PlayerResult.fromMap(Map<String, dynamic> m) => PlayerResult(
        sessionId: m['sessionId'] as String,
        playerName: m['playerName'] as String,
        score: m['score'] as int,
        correctCount: m['correctCount'] as int,
        avgTime: (m['avgTime'] as num).toDouble(),
        bestStreak: m['bestStreak'] as int,
      );
}
