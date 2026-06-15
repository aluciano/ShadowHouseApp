import 'game_state.dart';
import 'online_room.dart';

class OnlineGameSession {
  const OnlineGameSession({
    required this.room,
    required this.gameState,
    required this.startedAt,
    required this.roundsPlayed,
    this.rematchProposalPlayerIds = const [],
  });

  final OnlineRoom room;
  final GameState gameState;
  final DateTime startedAt;
  final int roundsPlayed;
  final List<String> rematchProposalPlayerIds;

  OnlineGameSession copyWith({
    OnlineRoom? room,
    GameState? gameState,
    DateTime? startedAt,
    int? roundsPlayed,
    List<String>? rematchProposalPlayerIds,
  }) {
    return OnlineGameSession(
      room: room ?? this.room,
      gameState: gameState ?? this.gameState,
      startedAt: startedAt ?? this.startedAt,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      rematchProposalPlayerIds:
          rematchProposalPlayerIds ?? this.rematchProposalPlayerIds,
    );
  }
}
