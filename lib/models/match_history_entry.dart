import 'game_mode.dart';
import 'match_play_mode.dart';

class MatchHistoryEntry {
  const MatchHistoryEntry({
    required this.id,
    required this.playMode,
    required this.gameMode,
    required this.startedAt,
    required this.finishedAt,
    required this.playerNames,
    required this.winnerNames,
    required this.roundsPlayed,
    this.roomCode,
  });

  final String id;
  final MatchPlayMode playMode;
  final GameMode gameMode;
  final DateTime startedAt;
  final DateTime finishedAt;
  final List<String> playerNames;
  final List<String> winnerNames;
  final int roundsPlayed;
  final String? roomCode;

  Duration get totalDuration => finishedAt.difference(startedAt);
}
