import 'dart:async';

import '../models/game_mode.dart';
import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import 'online_game_repository.dart';
import 'online_game_session_factory.dart';

class FakeOnlineGameRepository implements OnlineGameRepository {
  FakeOnlineGameRepository._();

  static final FakeOnlineGameRepository instance = FakeOnlineGameRepository._();

  OnlineRoom? _latestRoom;
  OnlineGameSession? _latestSession;
  final StreamController<OnlineGameSession> _sessionController =
      StreamController<OnlineGameSession>.broadcast();

  @override
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

  @override
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
            name: 'Anfitrião',
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

  @override
  Future<OnlineGameSession> startGame(OnlineRoom room) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return _createSessionForRoom(room);
  }

  @override
  Future<OnlineGameSession> startNewMatchInSameRoom(OnlineRoom room) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    return _createSessionForRoom(room);
  }

  @override
  Future<OnlineGameSession> loadCurrentSession(OnlineRoom room) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    return _latestSession ?? _createSessionForRoom(room);
  }

  @override
  Stream<OnlineGameSession> watchCurrentSession(OnlineRoom room) async* {
    final session = _latestSession;

    if (session != null) {
      yield session;
    }

    yield* _sessionController.stream;
  }

  @override
  Future<void> saveCurrentSession(OnlineGameSession session) async {
    _latestSession = session;
    _latestRoom = session.room;
    _sessionController.add(session);
  }

  @override
  Stream<OnlineRoom> watchRoom(String roomId) async* {
    final room = _latestRoom;

    if (room != null && room.id == roomId) {
      yield room;
    }
  }

  OnlineGameSession _createSessionForRoom(OnlineRoom room) {
    final session = createOnlineGameSessionForRoom(room);

    _latestRoom = session.room;
    _latestSession = session;
    _sessionController.add(session);

    return session;
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
