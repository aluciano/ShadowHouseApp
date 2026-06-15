import 'game_state.dart';
import 'online_pending_effect.dart';
import 'online_room.dart';

class OnlineGameSession {
  const OnlineGameSession({
    required this.room,
    required this.gameState,
    required this.startedAt,
    required this.roundsPlayed,
    this.rematchProposalPlayerIds = const [],
    this.nextRoundReadyPlayerIds = const [],
    this.pendingEffect,
  });

  final OnlineRoom room;
  final GameState gameState;
  final DateTime startedAt;
  final int roundsPlayed;
  final List<String> rematchProposalPlayerIds;
  final List<String> nextRoundReadyPlayerIds;
  final OnlinePendingEffect? pendingEffect;

  OnlineGameSession copyWith({
    OnlineRoom? room,
    GameState? gameState,
    DateTime? startedAt,
    int? roundsPlayed,
    List<String>? rematchProposalPlayerIds,
    List<String>? nextRoundReadyPlayerIds,
    OnlinePendingEffect? pendingEffect,
    bool clearPendingEffect = false,
  }) {
    return OnlineGameSession(
      room: room ?? this.room,
      gameState: gameState ?? this.gameState,
      startedAt: startedAt ?? this.startedAt,
      roundsPlayed: roundsPlayed ?? this.roundsPlayed,
      rematchProposalPlayerIds:
          rematchProposalPlayerIds ?? this.rematchProposalPlayerIds,
      nextRoundReadyPlayerIds:
          nextRoundReadyPlayerIds ?? this.nextRoundReadyPlayerIds,
      pendingEffect: clearPendingEffect
          ? null
          : pendingEffect ?? this.pendingEffect,
    );
  }
}
