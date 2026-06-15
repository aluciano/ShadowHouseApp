import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_mode.dart';
import '../models/online_game_session.dart';
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

  DocumentReference<Map<String, dynamic>> _currentSessionRef(String roomId) {
    return _rooms.doc(roomId).collection('sessions').doc('current');
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
    );
    final room = OnlineRoom(
      id: roomRef.id,
      code: await _createUniqueRoomCode(),
      hostPlayerId: player.id,
      players: [player],
      gameMode: gameMode,
      createdAt: now,
      status: OnlineRoomStatus.waiting,
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
      throw StateError('Esta sala já iniciou uma partida.');
    }

    final now = DateTime.now();
    final player = OnlinePlayer(
      id: 'player_${now.microsecondsSinceEpoch}',
      name: playerName,
      isHost: false,
      isReady: true,
    );
    final updatedRoom = OnlineRoom(
      id: room.id,
      code: room.code,
      hostPlayerId: room.hostPlayerId,
      players: [
        ...room.players,
        player,
      ],
      gameMode: room.gameMode,
      createdAt: room.createdAt,
      status: room.status,
      currentPlayerId: room.currentPlayerId,
    );

    await roomDoc.reference.update(onlineRoomToFirestore(updatedRoom));

    return updatedRoom;
  }

  @override
  Future<OnlineGameSession> startGame(OnlineRoom room) async {
    final session = createOnlineGameSessionForRoom(room);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(room.id),
        onlineGameSessionToFirestore(session),
      );
      transaction.set(
        _rooms.doc(room.id),
        onlineRoomToFirestore(session.room),
        SetOptions(merge: true),
      );
    });

    return session;
  }

  @override
  Future<OnlineGameSession> startNewMatchInSameRoom(OnlineRoom room) async {
    final resetRoom = OnlineRoom(
      id: room.id,
      code: room.code,
      hostPlayerId: room.hostPlayerId,
      players: room.players,
      gameMode: room.gameMode,
      createdAt: room.createdAt,
      status: OnlineRoomStatus.waiting,
    );
    final session = createOnlineGameSessionForRoom(resetRoom);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(room.id),
        onlineGameSessionToFirestore(session),
      );
      transaction.set(
        _rooms.doc(room.id),
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
    final updatedRoom = _roomWithCurrentPlayer(session);
    final updatedSession = session.copyWith(room: updatedRoom);

    await firestore.runTransaction((transaction) async {
      transaction.set(
        _currentSessionRef(session.room.id),
        onlineGameSessionToFirestore(updatedSession),
      );
      transaction.set(
        _rooms.doc(session.room.id),
        onlineRoomToFirestore(updatedRoom),
        SetOptions(merge: true),
      );
    });
  }

  @override
  Stream<OnlineRoom> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().where((snapshot) {
      return snapshot.exists && snapshot.data() != null;
    }).map((snapshot) {
      return onlineRoomFromFirestore(
        id: snapshot.id,
        data: snapshot.data()!,
      );
    });
  }

  OnlineRoom _roomWithCurrentPlayer(OnlineGameSession session) {
    return OnlineRoom(
      id: session.room.id,
      code: session.room.code,
      hostPlayerId: session.room.hostPlayerId,
      players: session.room.players,
      gameMode: session.room.gameMode,
      createdAt: session.room.createdAt,
      status: session.room.status,
      currentPlayerId: session.gameState.currentPlayer.id,
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
