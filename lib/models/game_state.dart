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
    this.silenceOwnerPlayerId,
    this.secretOathPlayerId,
    this.secretOathPartnerPlayerId,
    this.pianoControllerPlayerId,
    this.pianoTargetPlayerId,
  });

  final GameSetup setup;
  final List<Player> players;
  final List<GameCard> deck;

  final int initialDeckSize;
  int currentPlayerIndex;
  bool roundFinished;
  RoundResult? roundResult;
  String? silenceOwnerPlayerId;
  String? secretOathPlayerId;
  String? secretOathPartnerPlayerId;
  String? pianoControllerPlayerId;
  String? pianoTargetPlayerId;

  Player get currentPlayer => players[currentPlayerIndex];

  int get drawnCardsCount => initialDeckSize - deck.length;

  void moveToNextPlayer() {
    for (final player in players) {
      _restoreSealedCardsIfNeeded(player);
    }

    if (players.every((player) => player.hand.isEmpty)) {
      return;
    }

    var nextIndex = currentPlayerIndex;

    do {
      nextIndex = (nextIndex + 1) % players.length;
    } while (players[nextIndex].hand.isEmpty);

    if (players[nextIndex].id == silenceOwnerPlayerId) {
      silenceOwnerPlayerId = null;
    }

    currentPlayerIndex = nextIndex;
  }

  void _restoreSealedCardsIfNeeded(Player player) {
    if (player.hand.isNotEmpty) {
      return;
    }

    final sealedCards = player.playedCards
        .where((card) => card.isFaceDown)
        .toList();

    if (sealedCards.isEmpty) {
      return;
    }

    player.playedCards.removeWhere((card) => card.isFaceDown);
    player.hand.addAll(
      sealedCards.map((card) => card.copyWith(isFaceDown: false)),
    );
  }

  bool get hasSecretOath =>
      secretOathPlayerId != null && secretOathPartnerPlayerId != null;

  bool get hasPendingPiano =>
      pianoControllerPlayerId != null && pianoTargetPlayerId != null;

  bool get currentTurnIsUnderPiano =>
      hasPendingPiano && currentPlayer.id == pianoTargetPlayerId;
}
