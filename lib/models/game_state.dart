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
    List<int>? deckDrawGroups,
    this.roundFinished = false,
    this.roundResult,
    this.silenceOwnerPlayerId,
    this.secretOathPlayerId,
    this.secretOathPartnerPlayerId,
    this.pianoControllerPlayerId,
    this.pianoTargetPlayerId,
  }) : deckDrawGroups = deckDrawGroups ?? [];

  final GameSetup setup;
  final List<Player> players;
  final List<GameCard> deck;

  final int initialDeckSize;
  final List<int> deckDrawGroups;
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

  void registerDeckDraw(int count) {
    if (count > 0) {
      deckDrawGroups.add(count);
    }
  }

  void moveToNextPlayer() {
    if (players.every((player) => !_canReceiveTurn(player))) {
      return;
    }

    var nextIndex = currentPlayerIndex;

    do {
      nextIndex = (nextIndex + 1) % players.length;
    } while (!_canReceiveTurn(players[nextIndex]));

    _restoreSealedCardsIfNeeded(players[nextIndex]);

    if (players[nextIndex].id == silenceOwnerPlayerId) {
      silenceOwnerPlayerId = null;
    }

    currentPlayerIndex = nextIndex;
  }

  bool _canReceiveTurn(Player player) {
    if (player.hand.isNotEmpty) {
      return true;
    }

    return player.playedCards.any((card) => card.isFaceDown);
  }

  void _restoreSealedCardsIfNeeded(Player player) {
    final onlyHasGuiltyInHand =
        player.hand.length == 1 && player.hand.single.templateId == 'culpado';

    if (player.hand.isNotEmpty && !onlyHasGuiltyInHand) {
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
