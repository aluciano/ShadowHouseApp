import '../data/game_setup_rules.dart';
import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/game_setup.dart';
import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import '../models/player.dart';

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

  final gameState = _useOnlinePlayerIds(
    createInitialGameState(setup),
    readyPlayers,
  );
  final startedRoom = OnlineRoom(
    id: room.id,
    code: room.code,
    hostPlayerId: room.hostPlayerId,
    players: readyPlayers,
    gameMode: room.gameMode,
    createdAt: room.createdAt,
    status: OnlineRoomStatus.inProgress,
    currentPlayerId: gameState.currentPlayer.id,
    systemMessage: 'A partida online começou.',
    systemMessageAt: DateTime.now(),
  );

  return OnlineGameSession(
    room: startedRoom,
    gameState: gameState,
    startedAt: DateTime.now(),
    roundsPlayed: 1,
  );
}

OnlineGameSession createNextOnlineRoundSession(OnlineGameSession session) {
  final nextRoundState = _useOnlinePlayerIds(
    createNextRoundGameState(session.gameState),
    session.room.players,
  );

  return session.copyWith(
    gameState: nextRoundState,
    roundsPlayed: session.roundsPlayed + 1,
    rematchProposalPlayerIds: const [],
    nextRoundReadyPlayerIds: const [],
    activeProtections: const [],
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
        lastSeenAt: DateTime.now(),
      ),
  ];
}

GameState _useOnlinePlayerIds(
  GameState gameState,
  List<OnlinePlayer> onlinePlayers,
) {
  final players = <Player>[];

  for (int i = 0; i < gameState.players.length; i++) {
    final player = gameState.players[i];
    final onlinePlayer = onlinePlayers[i];

    players.add(
      Player(
        id: onlinePlayer.id,
        name: onlinePlayer.name,
        type: player.type,
        hand: player.hand,
        playedCards: player.playedCards,
        score: player.score,
        isAccomplice: player.isAccomplice,
        hasHandcuffs: player.hasHandcuffs,
      ),
    );
  }

  return GameState(
    setup: gameState.setup,
    players: players,
    deck: gameState.deck,
    currentPlayerIndex: gameState.currentPlayerIndex,
    initialDeckSize: gameState.initialDeckSize,
    roundFinished: gameState.roundFinished,
    silenceOwnerPlayerId: gameState.silenceOwnerPlayerId,
    secretOathPlayerId: gameState.secretOathPlayerId,
    secretOathPartnerPlayerId: gameState.secretOathPartnerPlayerId,
    pianoControllerPlayerId: gameState.pianoControllerPlayerId,
    pianoTargetPlayerId: gameState.pianoTargetPlayerId,
    roundResult: gameState.roundResult,
  );
}
