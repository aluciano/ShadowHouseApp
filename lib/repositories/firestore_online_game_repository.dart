import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_mode.dart';
import '../models/game_setup.dart';
import '../models/game_state.dart';
import '../models/online_game_session.dart';
import '../models/online_pending_effect.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import 'firestore_serializers.dart';
import 'online_game_repository.dart';
import 'online_game_session_factory.dart';

class FirestoreOnlineGameRepository implements OnlineGameRepository {
  FirestoreOnlineGameRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;
  final Random _random = Random();

  CollectionReference<Map<String, dynamic>> get _rooms {
    return firestore.collection('rooms');
  }

  DocumentReference<Map<String, dynamic>> _roomRef(String roomId) {
    return _rooms.doc(roomId);
  }

  DocumentReference<Map<String, dynamic>> _currentSessionRef(String roomId) {
    return _roomRef(roomId).collection('sessions').doc('current');
  }

  @override
  Future<OnlineRoom> createRoom({
    required String hostName,
    required GameMode gameMode,
  }) async {
    final now = DateTime.now();
    final roomRef = _rooms.doc();
    final player = OnlinePlayer(
      id: 'player_${now.microsecondsSinceEpoch}',
      name: hostName,
      isHost: true,
      isReady: true,
      isConnected: true,
      lastSeenAt: now,
    );
    final room = _normalizeRoom(
      OnlineRoom(
        id: roomRef.id,
        code: await _createUniqueRoomCode(),
        hostPlayerId: player.id,
        players: [player],
        gameMode: gameMode,
        createdAt: now,
        status: OnlineRoomStatus.waiting,
      ),
    );

    await roomRef.set(onlineRoomToFirestore(room));

    return room;
  }

  @override
  Future<OnlineRoom> joinRoom({
    required String roomCode,
    required String playerName,
  }) async {
    final normalizedCode = roomCode.trim().toUpperCase();
    final normalizedPlayerName = playerName.trim();
    final roomQuery = await _rooms
        .where('code', isEqualTo: normalizedCode)
        .limit(1)
        .get();

    if (roomQuery.docs.isEmpty) {
      throw StateError('Sala não encontrada.');
    }

    final roomDoc = roomQuery.docs.first;
    final room = onlineRoomFromFirestore(
      id: roomDoc.id,
      data: roomDoc.data(),
    );

    if (room.status != OnlineRoomStatus.waiting) {
      throw StateError(
        'Não é possível entrar: a sala já está em jogo.',
      );
    }

    final now = DateTime.now();
    final existingPlayerIndex = room.players.indexWhere((player) {
      return player.name.trim().toLowerCase() ==
              normalizedPlayerName.toLowerCase() &&
          !player.id.startsWith('placeholder_player_');
    });

    late final OnlinePlayer joinedPlayer;
    late final List<OnlinePlayer> updatedPlayers;

    if (existingPlayerIndex >= 0) {
      final existingPlayer = room.players[existingPlayerIndex];

      if (existingPlayer.isConnected) {
        throw StateError('Já existe um jogador conectado com esse nome.');
      }

      joinedPlayer = existingPlayer.copyWith(
        name: normalizedPlayerName,
        isConnected: true,
        isReady: true,
        lastSeenAt: now,
      );
      updatedPlayers = [...room.players];
      updatedPlayers[existingPlayerIndex] = joinedPlayer;
    } else {
      joinedPlayer = OnlinePlayer(
        id: 'player_${now.microsecondsSinceEpoch}',
        name: normalizedPlayerName,
        isHost: false,
        isReady: true,
        isConnected: true,
        lastSeenAt: now,
      );
      updatedPlayers = [...room.players, joinedPlayer];
    }

    final updatedRoom = _normalizeRoom(
      room.copyWith(players: updatedPlayers),
    );

    await roomDoc.reference.update(onlineRoomToFirestore(updatedRoom));
    await _syncRoomIntoExistingSession(updatedRoom);

    return updatedRoom;
  }

  @override
  Future<OnlineRoom> reconnectToRoom({
    required String roomId,
    required String playerId,
  }) async {
    final roomSnapshot = await _roomRef(roomId).get();

    if (!roomSnapshot.exists || roomSnapshot.data() == null) {
      throw StateError('A sala anterior não está mais disponível.');
    }

    final room = onlineRoomFromFirestore(
      id: roomSnapshot.id,
      data: roomSnapshot.data()!,
    );
    final playerIndex = room.players.indexWhere((player) => player.id == playerId);

    if (playerIndex < 0) {
      throw StateError('Seu jogador não está mais nessa sala.');
    }

    final now = DateTime.now();
    final updatedPlayers = [...room.players];
    updatedPlayers[playerIndex] = updatedPlayers[playerIndex].copyWith(
      isConnected: true,
      isReady: true,
      lastSeenAt: now,
    );

    final updatedRoom = _normalizeRoom(
      room.copyWith(players: updatedPlayers),
    );

    await roomSnapshot.reference.update(onlineRoomToFirestore(updatedRoom));
    await _syncRoomIntoExistingSession(updatedRoom);

    return updatedRoom;
  }

  @override
  Future<OnlineGameSession> startGame(OnlineRoom room) async {
    final normalizedRoom = _normalizeRoom(room);
    final session = createOnlineGameSessionForRoom(normalizedRoom);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(normalizedRoom.id),
        onlineGameSessionToFirestore(session),
      );
      transaction.set(
        _roomRef(normalizedRoom.id),
        onlineRoomToFirestore(session.room),
        SetOptions(merge: true),
      );
    });

    return session;
  }

  @override
  Future<OnlineGameSession> startNewMatchInSameRoom(OnlineRoom room) async {
    final normalizedRoom = _normalizeRoom(
      room.copyWith(
        status: OnlineRoomStatus.waiting,
        clearCurrentPlayerId: true,
      ),
    );
    final session = createOnlineGameSessionForRoom(normalizedRoom);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(normalizedRoom.id),
        onlineGameSessionToFirestore(session),
      );
      transaction.set(
        _roomRef(normalizedRoom.id),
        onlineRoomToFirestore(session.room),
        SetOptions(merge: true),
      );
    });

    return session;
  }

  @override
  Future<OnlineGameSession> loadCurrentSession(OnlineRoom room) async {
    final sessionSnapshot = await _currentSessionRef(room.id).get();

    if (!sessionSnapshot.exists || sessionSnapshot.data() == null) {
      throw StateError('A partida ainda não está pronta.');
    }

    return onlineGameSessionFromFirestore(
      room: room,
      data: sessionSnapshot.data()!,
    );
  }

  @override
  Stream<OnlineGameSession> watchCurrentSession(OnlineRoom room) {
    return _currentSessionRef(room.id).snapshots().where((snapshot) {
      return snapshot.exists && snapshot.data() != null;
    }).map((snapshot) {
      return onlineGameSessionFromFirestore(
        room: room,
        data: snapshot.data()!,
      );
    });
  }

  @override
  Future<void> saveCurrentSession(OnlineGameSession session) async {
    final updatedRoom = _normalizeRoom(_roomWithCurrentPlayer(session));
    final updatedSession = session.copyWith(room: updatedRoom);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(updatedRoom.id),
        onlineGameSessionToFirestore(updatedSession),
      );
      transaction.set(
        _roomRef(updatedRoom.id),
        onlineRoomToFirestore(updatedRoom),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Stream<OnlineRoom> watchRoom(String roomId) {
    return _roomRef(roomId).snapshots().where((snapshot) {
      return snapshot.exists && snapshot.data() != null;
    }).map((snapshot) {
      return onlineRoomFromFirestore(
        id: snapshot.id,
        data: snapshot.data()!,
      );
    });
  }

  @override
  Future<void> updatePlayerConnection({
    required String roomId,
    required String playerId,
    required bool isConnected,
  }) async {
    await firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(_roomRef(roomId));

      if (!roomSnapshot.exists || roomSnapshot.data() == null) {
        return;
      }

      final room = onlineRoomFromFirestore(
        id: roomSnapshot.id,
        data: roomSnapshot.data()!,
      );
      final playerIndex =
          room.players.indexWhere((player) => player.id == playerId);

      if (playerIndex < 0) {
        return;
      }

      final now = DateTime.now();
      final updatedPlayers = [...room.players];
      final existingPlayer = updatedPlayers[playerIndex];

      updatedPlayers[playerIndex] = existingPlayer.copyWith(
        isConnected: isConnected,
        lastSeenAt: now,
      );

      final updatedRoom = _normalizeRoom(
        room.copyWith(players: updatedPlayers),
      );

      transaction.set(
        _roomRef(roomId),
        onlineRoomToFirestore(updatedRoom),
        SetOptions(merge: true),
      );

      final sessionSnapshot = await transaction.get(_currentSessionRef(roomId));

      if (sessionSnapshot.exists && sessionSnapshot.data() != null) {
        final session = onlineGameSessionFromFirestore(
          room: updatedRoom,
          data: sessionSnapshot.data()!,
        );

        transaction.set(
          _currentSessionRef(roomId),
          onlineGameSessionToFirestore(
            session.copyWith(room: updatedRoom),
          ),
        );
      }
    });
  }

  @override
  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  }) async {
    await _removePlayerInternal(
      roomId: roomId,
      removedPlayerId: playerId,
      actingPlayerId: playerId,
      enforceHostPermission: false,
    );
  }

  @override
  Future<void> removePlayer({
    required String roomId,
    required String actingPlayerId,
    required String removedPlayerId,
  }) async {
    await _removePlayerInternal(
      roomId: roomId,
      removedPlayerId: removedPlayerId,
      actingPlayerId: actingPlayerId,
      enforceHostPermission: true,
    );
  }

  Future<void> _removePlayerInternal({
    required String roomId,
    required String removedPlayerId,
    required String actingPlayerId,
    required bool enforceHostPermission,
  }) async {
    await firestore.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(_roomRef(roomId));

      if (!roomSnapshot.exists || roomSnapshot.data() == null) {
        return;
      }

      final room = onlineRoomFromFirestore(
        id: roomSnapshot.id,
        data: roomSnapshot.data()!,
      );

      if (enforceHostPermission && room.hostPlayerId != actingPlayerId) {
        throw StateError('Só o anfitrião pode remover jogadores da sala.');
      }

      final updatedPlayers = room.players
          .where((player) => player.id != removedPlayerId)
          .toList();

      if (updatedPlayers.isEmpty) {
        transaction.delete(_roomRef(roomId));
        transaction.delete(_currentSessionRef(roomId));
        return;
      }

      final updatedRoom = _normalizeRoom(
        room.copyWith(players: updatedPlayers),
      );

      final sessionSnapshot = await transaction.get(_currentSessionRef(roomId));

      if (!sessionSnapshot.exists || sessionSnapshot.data() == null) {
        transaction.set(
          _roomRef(roomId),
          onlineRoomToFirestore(updatedRoom),
          SetOptions(merge: true),
        );
        return;
      }

      final currentSession = onlineGameSessionFromFirestore(
        room: room,
        data: sessionSnapshot.data()!,
      );
      final updatedSession = _sessionAfterRemovingPlayer(
        session: currentSession,
        updatedRoom: updatedRoom,
        removedPlayerId: removedPlayerId,
      );

      transaction.set(
        _currentSessionRef(roomId),
        onlineGameSessionToFirestore(updatedSession),
      );
      transaction.set(
        _roomRef(roomId),
        onlineRoomToFirestore(updatedSession.room),
        SetOptions(merge: true),
      );
    });
  }

  OnlineRoom _roomWithCurrentPlayer(OnlineGameSession session) {
    return session.room.copyWith(
      currentPlayerId: session.gameState.players.isEmpty
          ? null
          : session.gameState.currentPlayer.id,
    );
  }

  OnlineRoom _normalizeRoom(OnlineRoom room) {
    if (room.players.isEmpty) {
      return room;
    }

    var hostPlayerId = room.hostPlayerId;
    final hostStillExists = room.players.any((player) => player.id == hostPlayerId);
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

  Future<void> _syncRoomIntoExistingSession(OnlineRoom room) async {
    final sessionSnapshot = await _currentSessionRef(room.id).get();

    if (!sessionSnapshot.exists || sessionSnapshot.data() == null) {
      return;
    }

    final session = onlineGameSessionFromFirestore(
      room: room,
      data: sessionSnapshot.data()!,
    );

    await _currentSessionRef(room.id).set(
      onlineGameSessionToFirestore(session.copyWith(room: room)),
    );
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
      remainingPlayerIds: updatedPlayers.map((player) => player.id).toSet(),
    );

    if (session.pendingEffect != null &&
        pendingEffect == null &&
        !updatedGameState.roundFinished) {
      updatedGameState.moveToNextPlayer();
    }

    final sanitizedRoom = updatedRoom.copyWith(
      currentPlayerId: updatedGameState.currentPlayer.id,
      players: updatedRoom.players
          .where((roomPlayer) => updatedPlayers.any((player) => player.id == roomPlayer.id))
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
    required Set<String> remainingPlayerIds,
  }) {
    if (effect == null) {
      return null;
    }

    if (effect.actingPlayerId == removedPlayerId) {
      return null;
    }

    if (effect.resultMessage == null &&
        (effect.targetPlayerId == removedPlayerId ||
            effect.secondaryCardId == removedPlayerId ||
            effect.participantPlayerIds.contains(removedPlayerId))) {
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

    return effect.copyWith(
      targetPlayerId: effect.targetPlayerId == removedPlayerId
          ? null
          : effect.targetPlayerId,
      secondaryCardId: effect.secondaryCardId == removedPlayerId
          ? null
          : effect.secondaryCardId,
      secondaryCardName:
          effect.secondaryCardId == removedPlayerId ? null : effect.secondaryCardName,
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

  Future<String> _createUniqueRoomCode() async {
    for (int attempt = 0; attempt < 10; attempt++) {
      final code = _createRoomCode();
      final existing = await _rooms
          .where('code', isEqualTo: code)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        return code;
      }
    }

    throw StateError('Não foi possível criar um código de sala.');
  }

  String _createRoomCode() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    return List.generate(
      6,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }
}
