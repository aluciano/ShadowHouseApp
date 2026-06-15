import '../models/game_mode.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import 'match_history_repository.dart';

class FakeMatchHistoryRepository implements MatchHistoryRepository {
  FakeMatchHistoryRepository._();

  static final FakeMatchHistoryRepository instance =
      FakeMatchHistoryRepository._();

  final List<MatchHistoryEntry> _history = [
    MatchHistoryEntry(
      id: 'history_1',
      playMode: MatchPlayMode.local,
      gameMode: GameMode.expansionBalanced,
      startedAt: DateTime.now().subtract(
        const Duration(days: 1, hours: 4, minutes: 25),
      ),
      finishedAt: DateTime.now().subtract(
        const Duration(days: 1, hours: 3, minutes: 50),
      ),
      playerNames: const ['Alice', 'Bruno', 'Carla', 'Diego'],
      winnerNames: const ['Carla'],
      roundsPlayed: 3,
    ),
    MatchHistoryEntry(
      id: 'history_2',
      playMode: MatchPlayMode.online,
      gameMode: GameMode.expansionFullHand,
      startedAt: DateTime.now().subtract(
        const Duration(days: 5, hours: 2, minutes: 10),
      ),
      finishedAt: DateTime.now().subtract(
        const Duration(days: 5, hours: 1, minutes: 18),
      ),
      playerNames: const ['Lia', 'Mateus', 'Nina'],
      winnerNames: const ['Lia', 'Nina'],
      roundsPlayed: 4,
      roomCode: 'NOITE7',
    ),
  ];

  @override
  Future<List<MatchHistoryEntry>> loadHistory() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return List.unmodifiable(_history);
  }

  @override
  Future<void> saveMatch(MatchHistoryEntry entry) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));

    _history.insert(0, entry);
  }
}
