import 'game_mode.dart';
import 'online_player.dart';
import 'online_room_status.dart';

class OnlineRoom {
  const OnlineRoom({
    required this.id,
    required this.code,
    required this.hostPlayerId,
    required this.players,
    required this.gameMode,
    required this.createdAt,
    required this.status,
    this.currentPlayerId,
    this.systemMessage,
    this.systemMessageAt,
  });

  final String id;
  final String code;
  final String hostPlayerId;
  final List<OnlinePlayer> players;
  final GameMode gameMode;
  final DateTime createdAt;
  final OnlineRoomStatus status;
  final String? currentPlayerId;
  final String? systemMessage;
  final DateTime? systemMessageAt;

  OnlineRoom copyWith({
    String? id,
    String? code,
    String? hostPlayerId,
    List<OnlinePlayer>? players,
    GameMode? gameMode,
    DateTime? createdAt,
    OnlineRoomStatus? status,
    String? currentPlayerId,
    String? systemMessage,
    DateTime? systemMessageAt,
    bool clearCurrentPlayerId = false,
    bool clearSystemMessage = false,
  }) {
    return OnlineRoom(
      id: id ?? this.id,
      code: code ?? this.code,
      hostPlayerId: hostPlayerId ?? this.hostPlayerId,
      players: players ?? this.players,
      gameMode: gameMode ?? this.gameMode,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      currentPlayerId: clearCurrentPlayerId
          ? null
          : currentPlayerId ?? this.currentPlayerId,
      systemMessage: clearSystemMessage
          ? null
          : systemMessage ?? this.systemMessage,
      systemMessageAt: clearSystemMessage
          ? null
          : systemMessageAt ?? this.systemMessageAt,
    );
  }
}
