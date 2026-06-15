import '../models/game_mode.dart';
import '../models/online_game_session.dart';
import '../models/online_room.dart';

abstract class OnlineGameRepository {
  Future<OnlineRoom> createRoom({
    required String hostName,
    required GameMode gameMode,
  });

  Future<OnlineRoom> joinRoom({
    required String roomCode,
    required String playerName,
  });

  Future<OnlineGameSession> startGame(OnlineRoom room);

  Future<OnlineGameSession> startNewMatchInSameRoom(OnlineRoom room);
}
