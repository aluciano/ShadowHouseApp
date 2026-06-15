import '../models/match_history_entry.dart';

abstract class MatchHistoryRepository {
  Future<List<MatchHistoryEntry>> loadHistory();

  Future<void> saveMatch(MatchHistoryEntry entry);
}
