import 'firestore_match_history_repository.dart';
import 'firestore_online_game_repository.dart';
import 'match_history_repository.dart';
import 'online_game_repository.dart';

class RepositoryRegistry {
  const RepositoryRegistry._();

  static OnlineGameRepository onlineGame = FirestoreOnlineGameRepository();
  static MatchHistoryRepository matchHistory =
      FirestoreMatchHistoryRepository();
}
