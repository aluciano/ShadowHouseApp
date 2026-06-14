import 'game_state.dart';
import 'online_room.dart';

class OnlineGameSession {
  const OnlineGameSession({
    required this.room,
    required this.gameState,
    required this.startedAt,
  });

  final OnlineRoom room;
  final GameState gameState;
  final DateTime startedAt;
}
