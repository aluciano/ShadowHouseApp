class GameSetupRecommendation {
  const GameSetupRecommendation({
    required this.initialCards,
    required this.ghostCopies,
    required this.extraSilenceCopies,
    required this.extraSealedCardCopies,
  });

  final int initialCards;
  final int ghostCopies;
  final int extraSilenceCopies;
  final int extraSealedCardCopies;
}