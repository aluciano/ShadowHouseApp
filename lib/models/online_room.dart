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
  });

  final String id;
  final String code;
  final String hostPlayerId;
  final List<OnlinePlayer> players;
  final GameMode gameMode;
  final DateTime createdAt;
  final OnlineRoomStatus status;
  final String? currentPlayerId;
}
