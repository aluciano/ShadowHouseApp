import '../data/game_setup_rules.dart';
import '../engine/game_engine.dart';
import '../models/game_mode.dart';
import '../models/game_setup.dart';
import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';

class FakeOnlineGameRepository {
  FakeOnlineGameRepository._();

  static final FakeOnlineGameRepository instance = FakeOnlineGameRepository._();

  OnlineRoom? _latestRoom;

  Future<OnlineRoom> createRoom({
    required String hostName,
    required GameMode gameMode,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final now = DateTime.now();
    final room = OnlineRoom(
      id: 'room_${now.microsecondsSinceEpoch}',
      code: _createRoomCode(now),
      hostPlayerId: 'player_host',
      players: [
        OnlinePlayer(
          id: 'player_host',
          name: hostName,
          isHost: true,
          isReady: true,
        ),
      ],
      gameMode: gameMode,
      createdAt: now,
      status: OnlineRoomStatus.waiting,
    );

    _latestRoom = room;

    return room;
  }

  Future<OnlineRoom> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final baseRoom = _latestRoom;
    final now = DateTime.now();
    final player = OnlinePlayer(
      id: 'player_${now.microsecondsSinceEpoch}',
      name: playerName,
      isHost: false,
      isReady: true,
    );

    final room = OnlineRoom(
      id: baseRoom?.id ?? 'room_${now.microsecondsSinceEpoch}',
      code: roomCode.toUpperCase(),
      hostPlayerId: baseRoom?.hostPlayerId ?? 'player_host',
      players: [
        if (baseRoom == null)
          const OnlinePlayer(
            id: 'player_host',
            name: 'Anfitriao',
            isHost: true,
            isReady: true,
          )
        else
          ...baseRoom.players,
        player,
      ],
      gameMode: baseRoom?.gameMode ?? GameMode.expansionBalanced,
      createdAt: baseRoom?.createdAt ?? now,
      status: OnlineRoomStatus.waiting,
    );

    _latestRoom = room;

    return room;
  }

  Future<OnlineGameSession> startGame(OnlineRoom room) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final readyPlayers = _playersWithMinimumCount(room.players);
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

    _latestRoom = startedRoom;

    return OnlineGameSession(
      room: startedRoom,
      gameState: gameState,
      startedAt: DateTime.now(),
    );
  }

  List<OnlinePlayer> _playersWithMinimumCount(List<OnlinePlayer> players) {
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

  String _createRoomCode(DateTime now) {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    var value = now.millisecondsSinceEpoch;
    final chars = <String>[];

    for (int i = 0; i < 6; i++) {
      chars.add(alphabet[value % alphabet.length]);
      value = value ~/ alphabet.length;
    }

    return chars.reversed.join();
  }
}
