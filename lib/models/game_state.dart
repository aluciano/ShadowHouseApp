import 'game_card.dart';
import 'game_setup.dart';
import 'player.dart';
import 'round_result.dart';

class GameState {
  GameState({
    required this.setup,
    required this.players,
    required this.deck,
    required this.currentPlayerIndex,
    required this.initialDeckSize,
    this.roundFinished = false,
    this.roundResult,
  });

  final GameSetup setup;
  final List<Player> players;
  final List<GameCard> deck;

  final int initialDeckSize;
  int currentPlayerIndex;
  bool roundFinished;
  RoundResult? roundResult;

  Player get currentPlayer => players[currentPlayerIndex];

  int get drawnCardsCount => initialDeckSize - deck.length;

  void moveToNextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}