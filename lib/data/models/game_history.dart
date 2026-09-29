import 'dart:convert';

class GameHistory {
  final String id;
  final String title;
  final bool isHost;
  final int score;
  final int rank;
  final int totalPlayers;
  final DateTime playedAt;
  final String? quizTitle;
  final String? playerDetails;

  const GameHistory({
    required this.id,
    required this.title,
    required this.isHost,
    required this.score,
    required this.rank,
    required this.totalPlayers,
    required this.playedAt,
    this.quizTitle,
    this.playerDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isHost': isHost ? 1 : 0,
      'score': score,
      'rank': rank,
      'totalPlayers': totalPlayers,
      'playedAt': playedAt.millisecondsSinceEpoch,
      'quizTitle': quizTitle,
      'playerDetails': playerDetails,
    };
  }

  factory GameHistory.fromMap(Map<String, dynamic> map) {
    return GameHistory(
      id: map['id'] as String,
      title: map['title'] as String,
      isHost: (map['isHost'] as int) == 1,
      score: map['score'] as int,
      rank: map['rank'] as int,
      totalPlayers: map['totalPlayers'] as int,
      playedAt: DateTime.fromMillisecondsSinceEpoch(map['playedAt'] as int),
      quizTitle: map['quizTitle'] as String?,
      playerDetails: map['playerDetails'] as String?,
    );
  }

  List<Map<String, dynamic>> get parsedPlayerDetails {
    if (playerDetails == null || playerDetails!.isEmpty) return [];
    try {
      return (jsonDecode(playerDetails!) as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
