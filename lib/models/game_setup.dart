import 'game_mode.dart';

class GameSetup {
  const GameSetup({
    required this.playerNames,
    required this.gameMode,
    required this.initialCards,
    required this.ghostCopies,
    required this.extraSilenceCopies,
    required this.extraSealedCardCopies,
  });

  final List<String> playerNames;
  final GameMode gameMode;
  final int initialCards;
  final int ghostCopies;
  final int extraSilenceCopies;
  final int extraSealedCardCopies;
}