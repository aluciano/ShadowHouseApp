import '../data/game_setup_rules.dart';
import '../engine/game_engine.dart';
import '../models/game_setup.dart';
import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';

OnlineGameSession createOnlineGameSessionForRoom(OnlineRoom room) {
  final readyPlayers = playersWithMinimumCount(room.players);
  final recommendation = GameSetupRules.recommendation(
    playerCount: readyPlayers.length,
    gameMode: room.gameMode,
  );

  final setup = GameSetup(
    playerNames: readyPlayers.map((player) => player.name).toList(),
    gameMode: room.gameMode,
    initialCards: recommendation.initialCards,
    ghostCopies: recommendation.ghostCopies,
    extraSilenceCopies: recommendation.extraSilenceCopies,
    extraSealedCardCopies: recommendation.extraSealedCardCopies,
  );

  final gameState = createInitialGameState(setup);
  final startedRoom = OnlineRoom(
    id: room.id,
    code: room.code,
    hostPlayerId: room.hostPlayerId,
    players: readyPlayers,
    gameMode: room.gameMode,
    createdAt: room.createdAt,
    status: OnlineRoomStatus.inProgress,
    currentPlayerId: gameState.currentPlayer.id,
  );

  return OnlineGameSession(
    room: startedRoom,
    gameState: gameState,
    startedAt: DateTime.now(),
    roundsPlayed: 1,
  );
}

List<OnlinePlayer> playersWithMinimumCount(List<OnlinePlayer> players) {
  if (players.length >= 3) {
    return players;
  }

  return [
    ...players,
    for (int i = players.length; i < 3; i++)
      OnlinePlayer(
        id: 'placeholder_player_$i',
        name: 'Convidado ${i + 1}',
        isHost: false,
        isReady: true,
      ),
  ];
}
