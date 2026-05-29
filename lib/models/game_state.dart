import 'game_card.dart';
import 'player.dart';
import 'round_result.dart';

class GameState {
  GameState({
    required this.players,
    required this.deck,
    required this.currentPlayerIndex,
    required this.initialCards,
    required this.ghostCopies,
    this.roundFinished = false,
    this.roundResult,
  });

  final List<Player> players;
  final List<GameCard> deck;

  int currentPlayerIndex;
  final int initialCards;
  final int ghostCopies;
  bool roundFinished;
  RoundResult? roundResult;

  Player get currentPlayer => players[currentPlayerIndex];

  void moveToNextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}