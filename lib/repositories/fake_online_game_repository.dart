import 'dart:async';

import '../models/game_mode.dart';
import '../models/game_setup.dart';
import '../models/game_state.dart';
import '../models/online_game_session.dart';
import '../models/online_pending_effect.dart';
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
  final StreamController<OnlineRoom> _roomController =
      StreamController<OnlineRoom>.broadcast();
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
          lastSeenAt: now,
        ),
      ],
      gameMode: gameMode,
      createdAt: now,
      status: OnlineRoomStatus.waiting,
      systemMessage: '$hostName criou a sala.',
      systemMessageAt: now,
    );

    _latestRoom = _normalizeRoom(room);
    _emitRoom();

    return _latestRoom!;
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
      lastSeenAt: now,
    );

    final room = OnlineRoom(
      id: baseRoom?.id ?? 'room_${now.microsecondsSinceEpoch}',
      code: roomCode.toUpperCase(),
      hostPlayerId: baseRoom?.hostPlayerId ?? 'player_host',
      players: [
        if (baseRoom == null)
          OnlinePlayer(
            id: 'player_host',
            name: 'Anfitrião',
            isHost: true,
            isReady: true,
            lastSeenAt: now,
          )
        else
          ...baseRoom.players,
        player,
      ],
      gameMode: baseRoom?.gameMode ?? GameMode.expansionBalanced,
      createdAt: baseRoom?.createdAt ?? now,
      status: OnlineRoomStatus.waiting,
      systemMessage: '$playerName entrou na sala.',
      systemMessageAt: now,
    );

    _latestRoom = _normalizeRoom(room);
    _emitRoom();

    return _latestRoom!;
  }

  @override
  Future<OnlineRoom> reconnectToRoom({
    required String roomId,
    required String playerId,
  }) async {
    final room = _latestRoom;

    if (room == null || room.id != roomId) {
      throw StateError('A sala anterior não está mais disponível.');
    }

    final reconnectedPlayer = room.players.firstWhere(
      (player) => player.id == playerId,
    );
    final wasConnected = reconnectedPlayer.isConnected;
    final updatedPlayers = room.players.map((player) {
      if (player.id != playerId) {
        return player;
      }

      return player.copyWith(
        isConnected: true,
        lastSeenAt: DateTime.now(),
      );
    }).toList();

    _latestRoom = _normalizeRoom(
      room.copyWith(
        players: updatedPlayers,
        systemMessage:
            wasConnected ? room.systemMessage : '${reconnectedPlayer.name} reconectou.',
        systemMessageAt: wasConnected ? room.systemMessageAt : DateTime.now(),
      ),
    );
    _syncRoomIntoExistingSession(_latestRoom!);
    _emitRoom();

    return _latestRoom!;
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
    _latestRoom = _normalizeRoom(session.room);
    _latestSession = session.copyWith(room: _latestRoom);
    _emitRoom();
    _emitSession();
  }

  @override
  Stream<OnlineRoom> watchRoom(String roomId) async* {
    final room = _latestRoom;

    if (room != null && room.id == roomId) {
      yield room;
    }

    yield* _roomController.stream.where((room) => room.id == roomId);
  }

  @override
  Future<void> updatePlayerConnection({
    required String roomId,
    required String playerId,
    required bool isConnected,
  }) async {
    final room = _latestRoom;

    if (room == null || room.id != roomId) {
      return;
    }

    final updatedPlayers = room.players.map((player) {
      if (player.id != playerId) {
        return player;
      }

      return player.copyWith(
        isConnected: isConnected,
        lastSeenAt: DateTime.now(),
      );
    }).toList();

    final existingPlayer = room.players.firstWhere((player) => player.id == playerId);
    final connectionChanged = existingPlayer.isConnected != isConnected;
    final changedPlayer =
        updatedPlayers.firstWhere((player) => player.id == playerId);
    _latestRoom = _normalizeRoom(
      room.copyWith(
        players: updatedPlayers,
        systemMessage: !connectionChanged
            ? room.systemMessage
            : isConnected
                ? '${changedPlayer.name} reconectou.'
                : '${changedPlayer.name} desconectou.',
        systemMessageAt:
            connectionChanged ? DateTime.now() : room.systemMessageAt,
      ),
    );
    _syncRoomIntoExistingSession(_latestRoom!);
    _emitRoom();
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    final room = _latestRoom;

    if (room == null || room.id != roomId) {
      return;
    }

    final updatedPlayers =
        room.players.where((player) => player.id != playerId).toList();
    final removedPlayer =
        room.players.firstWhere((player) => player.id == playerId);

    _latestRoom = _normalizeRoom(
      room.copyWith(
        players: updatedPlayers,
        systemMessage: '${removedPlayer.name} saiu da sala.',
        systemMessageAt: DateTime.now(),
      ),
    );
    _syncSessionAfterRemovingPlayer(
      updatedRoom: _latestRoom!,
      removedPlayerId: playerId,
    );
    _emitRoom();
  }

  @override
  Future<void> removePlayer({
    required String roomId,
    required String actingPlayerId,
    required String removedPlayerId,
  }) async {
    final room = _latestRoom;

    if (room == null || room.id != roomId) {
      return;
    }

    final removedPlayer =
        room.players.firstWhere((player) => player.id == removedPlayerId);
    final actingPlayer =
        room.players.firstWhere((player) => player.id == actingPlayerId);
    final updatedPlayers =
        room.players.where((player) => player.id != removedPlayerId).toList();

    _latestRoom = _normalizeRoom(
      room.copyWith(
        players: updatedPlayers,
        systemMessage:
            '${removedPlayer.name} foi removido da sala por ${actingPlayer.name}.',
        systemMessageAt: DateTime.now(),
      ),
    );
    _syncSessionAfterRemovingPlayer(
      updatedRoom: _latestRoom!,
      removedPlayerId: removedPlayerId,
    );
    _emitRoom();
  }

  void _emitRoom() {
    if (_latestRoom != null) {
      _roomController.add(_latestRoom!);
    }
  }

  void _emitSession() {
    if (_latestSession != null) {
      _sessionController.add(_latestSession!);
    }
  }

  OnlineRoom _normalizeRoom(OnlineRoom room) {
    if (room.players.isEmpty) {
      return room;
    }

    var hostPlayerId = room.hostPlayerId;
    final hostStillExists =
        room.players.any((player) => player.id == hostPlayerId);
    final currentHost = hostStillExists
        ? room.players.firstWhere((player) => player.id == hostPlayerId)
        : null;

    if (!hostStillExists || currentHost == null || !currentHost.isConnected) {
      final replacement = room.players.firstWhere(
        (player) => player.isConnected,
        orElse: () => room.players.first,
      );
      hostPlayerId = replacement.id;
    }

    final players = room.players.map((player) {
      return player.copyWith(isHost: player.id == hostPlayerId);
    }).toList();

    final currentPlayerId = room.currentPlayerId != null &&
            players.any((player) => player.id == room.currentPlayerId)
        ? room.currentPlayerId
        : null;

    return room.copyWith(
      hostPlayerId: hostPlayerId,
      players: players,
      currentPlayerId: currentPlayerId,
    );
  }

  void _syncRoomIntoExistingSession(OnlineRoom room) {
    if (_latestSession == null) {
      return;
    }

    _latestSession = _latestSession!.copyWith(room: room);
    _emitSession();
  }

  void _syncSessionAfterRemovingPlayer({
    required OnlineRoom updatedRoom,
    required String removedPlayerId,
  }) {
    if (_latestSession == null) {
      return;
    }

    _latestSession = _sessionAfterRemovingPlayer(
      session: _latestSession!,
      updatedRoom: updatedRoom,
      removedPlayerId: removedPlayerId,
    );
    _emitSession();
  }

  OnlineGameSession _sessionAfterRemovingPlayer({
    required OnlineGameSession session,
    required OnlineRoom updatedRoom,
    required String removedPlayerId,
  }) {
    final updatedPlayers = session.gameState.players
        .where((player) => player.id != removedPlayerId)
        .toList();

    if (updatedPlayers.isEmpty) {
      return session.copyWith(room: updatedRoom);
    }

    final removedIndex = session.gameState.players.indexWhere(
      (player) => player.id == removedPlayerId,
    );
    var currentPlayerIndex = session.gameState.currentPlayerIndex;

    if (removedIndex >= 0) {
      if (removedIndex < currentPlayerIndex) {
        currentPlayerIndex -= 1;
      } else if (removedIndex == currentPlayerIndex &&
          currentPlayerIndex >= updatedPlayers.length) {
        currentPlayerIndex = 0;
      }
    }

    if (currentPlayerIndex >= updatedPlayers.length) {
      currentPlayerIndex = 0;
    }

    final updatedSetup = GameSetup(
      playerNames: updatedPlayers.map((player) => player.name).toList(),
      gameMode: session.gameState.setup.gameMode,
      initialCards: session.gameState.setup.initialCards,
      ghostCopies: session.gameState.setup.ghostCopies,
      extraSilenceCopies: session.gameState.setup.extraSilenceCopies,
      extraSealedCardCopies: session.gameState.setup.extraSealedCardCopies,
    );

    final updatedGameState = GameState(
      setup: updatedSetup,
      players: updatedPlayers,
      deck: session.gameState.deck,
      currentPlayerIndex: currentPlayerIndex,
      initialDeckSize: session.gameState.initialDeckSize,
      roundFinished: session.gameState.roundFinished,
      roundResult: session.gameState.roundResult,
    );

    final pendingEffect = _pendingEffectAfterRemovingPlayer(
      effect: session.pendingEffect,
      removedPlayerId: removedPlayerId,
    );

    if (session.pendingEffect != null &&
        pendingEffect == null &&
        !updatedGameState.roundFinished) {
      updatedGameState.moveToNextPlayer();
    }

    final sanitizedRoom = updatedRoom.copyWith(
      currentPlayerId: updatedGameState.currentPlayer.id,
      players: updatedRoom.players
          .where(
            (roomPlayer) =>
                updatedPlayers.any((player) => player.id == roomPlayer.id),
          )
          .toList(),
    );

    return session.copyWith(
      room: sanitizedRoom,
      gameState: updatedGameState,
      rematchProposalPlayerIds: session.rematchProposalPlayerIds
          .where((playerId) => playerId != removedPlayerId)
          .toList(),
      nextRoundReadyPlayerIds: session.nextRoundReadyPlayerIds
          .where((playerId) => playerId != removedPlayerId)
          .toList(),
      activeProtections: session.activeProtections
          .where((protection) => protection.playerId != removedPlayerId)
          .toList(),
      pendingEffect: pendingEffect,
    );
  }

  OnlinePendingEffect? _pendingEffectAfterRemovingPlayer({
    required OnlinePendingEffect? effect,
    required String removedPlayerId,
  }) {
    if (effect == null) {
      return null;
    }

    if (effect.actingPlayerId == removedPlayerId) {
      return null;
    }

    final isCollectiveSelectionEffect =
        effect.type == OnlineEffectType.share ||
            effect.type == OnlineEffectType.rumors ||
            effect.type == OnlineEffectType.frenzy;

    if (effect.resultMessage == null &&
        (effect.targetPlayerId == removedPlayerId ||
            effect.secondaryCardId == removedPlayerId ||
            (!isCollectiveSelectionEffect &&
                effect.participantPlayerIds.contains(removedPlayerId)))) {
      return null;
    }

    final participantPlayerIds = effect.participantPlayerIds
        .where((playerId) => playerId != removedPlayerId)
        .toList();
    final completedPlayerIds = effect.completedPlayerIds
        .where((playerId) => playerId != removedPlayerId)
        .toList();
    final acknowledgedPlayerIds = effect.acknowledgedPlayerIds
        .where((playerId) => playerId != removedPlayerId)
        .toList();
    final selectedCardIdsByPlayerId = Map<String, String>.fromEntries(
      effect.selectedCardIdsByPlayerId.entries.where(
        (entry) => entry.key != removedPlayerId,
      ),
    );
    final selectedCardNamesByPlayerId = Map<String, String>.fromEntries(
      effect.selectedCardNamesByPlayerId.entries.where(
        (entry) => entry.key != removedPlayerId,
      ),
    );
    final receivedCardCountByPlayerId = Map<String, int>.fromEntries(
      effect.receivedCardCountByPlayerId.entries.where(
        (entry) => entry.key != removedPlayerId,
      ),
    );
    final receivedCardNamesByPlayerId = Map<String, String>.fromEntries(
      effect.receivedCardNamesByPlayerId.entries.where(
        (entry) => entry.key != removedPlayerId,
      ),
    );

    if (isCollectiveSelectionEffect &&
        effect.resultMessage == null &&
        participantPlayerIds.isEmpty) {
      return null;
    }

    return effect.copyWith(
      targetPlayerId: effect.targetPlayerId == removedPlayerId
          ? null
          : effect.targetPlayerId,
      secondaryCardId: effect.secondaryCardId == removedPlayerId
          ? null
          : effect.secondaryCardId,
      secondaryCardName: effect.secondaryCardId == removedPlayerId
          ? null
          : effect.secondaryCardName,
      secondaryCardTemplateId: effect.secondaryCardId == removedPlayerId
          ? null
          : effect.secondaryCardTemplateId,
      participantPlayerIds: participantPlayerIds,
      completedPlayerIds: completedPlayerIds,
      acknowledgedPlayerIds: acknowledgedPlayerIds,
      selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
      selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
      receivedCardCountByPlayerId: receivedCardCountByPlayerId,
      receivedCardNamesByPlayerId: receivedCardNamesByPlayerId,
    );
  }

  OnlineGameSession _createSessionForRoom(OnlineRoom room) {
    final session = createOnlineGameSessionForRoom(_normalizeRoom(room));

    _latestRoom = session.room;
    _latestSession = session;
    _emitRoom();
    _emitSession();

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
