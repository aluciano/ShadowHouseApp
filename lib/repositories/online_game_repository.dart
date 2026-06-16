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

  Future<OnlineRoom> reconnectToRoom({
    required String roomId,
    required String playerId,
  });

  Future<OnlineGameSession> startGame(OnlineRoom room);

  Future<OnlineGameSession> startNewMatchInSameRoom(OnlineRoom room);

  Future<OnlineGameSession> loadCurrentSession(OnlineRoom room);

  Stream<OnlineGameSession> watchCurrentSession(OnlineRoom room);

  Future<void> saveCurrentSession(OnlineGameSession session);

  Stream<OnlineRoom> watchRoom(String roomId);

  Future<void> updatePlayerConnection({
    required String roomId,
    required String playerId,
    required bool isConnected,
  });

  Future<void> leaveRoom({
    required String roomId,
    required String playerId,
  });

  Future<void> removePlayer({
    required String roomId,
    required String actingPlayerId,
    required String removedPlayerId,
  });
}
