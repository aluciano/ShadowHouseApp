import 'fake_match_history_repository.dart';
import 'fake_online_game_repository.dart';
import 'match_history_repository.dart';
import 'online_game_repository.dart';

class RepositoryRegistry {
  const RepositoryRegistry._();

  static OnlineGameRepository onlineGame = FakeOnlineGameRepository.instance;
  static MatchHistoryRepository matchHistory =
      FakeMatchHistoryRepository.instance;
}
