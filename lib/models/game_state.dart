import 'game_card.dart';
import 'player.dart';

class GameState {
  GameState({
    required this.players,
    required this.deck,
    required this.currentPlayerIndex,
    required this.initialCards,
    required this.ghostCopies,
    this.roundFinished = false,
  });

  final List<Player> players;
  final List<GameCard> deck;

  int currentPlayerIndex;
  final int initialCards;
  final int ghostCopies;
  bool roundFinished;

  Player get currentPlayer => players[currentPlayerIndex];

  void moveToNextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}