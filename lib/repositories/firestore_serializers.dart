import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game_mode.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';

Map<String, Object?> onlinePlayerToFirestore(OnlinePlayer player) {
  return {
    'id': player.id,
    'name': player.name,
    'isHost': player.isHost,
    'isReady': player.isReady,
  };
}

OnlinePlayer onlinePlayerFromFirestore(Map<String, dynamic> data) {
  return OnlinePlayer(
    id: data['id'] as String,
    name: data['name'] as String,
    isHost: data['isHost'] as bool? ?? false,
    isReady: data['isReady'] as bool? ?? false,
  );
}

Map<String, Object?> onlineRoomToFirestore(OnlineRoom room) {
  return {
    'code': room.code,
    'hostPlayerId': room.hostPlayerId,
    'players': room.players.map(onlinePlayerToFirestore).toList(),
    'gameMode': room.gameMode.name,
    'createdAt': Timestamp.fromDate(room.createdAt),
    'status': room.status.name,
    'currentPlayerId': room.currentPlayerId,
  };
}

OnlineRoom onlineRoomFromFirestore({
  required String id,
  required Map<String, dynamic> data,
}) {
  final players = (data['players'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(onlinePlayerFromFirestore)
      .toList();

  return OnlineRoom(
    id: id,
    code: data['code'] as String,
    hostPlayerId: data['hostPlayerId'] as String,
    players: players,
    gameMode: _enumByName(
      GameMode.values,
      data['gameMode'] as String?,
      GameMode.expansionBalanced,
    ),
    createdAt: _dateTimeFromFirestore(data['createdAt']),
    status: _enumByName(
      OnlineRoomStatus.values,
      data['status'] as String?,
      OnlineRoomStatus.waiting,
    ),
    currentPlayerId: data['currentPlayerId'] as String?,
  );
}

Map<String, Object?> matchHistoryEntryToFirestore(MatchHistoryEntry entry) {
  return {
    'playMode': entry.playMode.name,
    'gameMode': entry.gameMode.name,
    'startedAt': Timestamp.fromDate(entry.startedAt),
    'finishedAt': Timestamp.fromDate(entry.finishedAt),
    'playerNames': entry.playerNames,
    'winnerNames': entry.winnerNames,
    'roundsPlayed': entry.roundsPlayed,
    'roomCode': entry.roomCode,
  };
}

MatchHistoryEntry matchHistoryEntryFromFirestore({
  required String id,
  required Map<String, dynamic> data,
}) {
  return MatchHistoryEntry(
    id: id,
    playMode: _enumByName(
      MatchPlayMode.values,
      data['playMode'] as String?,
      MatchPlayMode.online,
    ),
    gameMode: _enumByName(
      GameMode.values,
      data['gameMode'] as String?,
      GameMode.expansionBalanced,
    ),
    startedAt: _dateTimeFromFirestore(data['startedAt']),
    finishedAt: _dateTimeFromFirestore(data['finishedAt']),
    playerNames: List<String>.from(data['playerNames'] as List<dynamic>? ?? []),
    winnerNames: List<String>.from(data['winnerNames'] as List<dynamic>? ?? []),
    roundsPlayed: data['roundsPlayed'] as int? ?? 0,
    roomCode: data['roomCode'] as String?,
  );
}

DateTime _dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.now();
}

T _enumByName<T extends Enum>(
  List<T> values,
  String? name,
  T fallback,
) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }

  return fallback;
}
