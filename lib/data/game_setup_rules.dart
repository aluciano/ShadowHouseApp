import '../models/game_mode.dart';
import '../models/game_setup_recommendation.dart';

class GameSetupRules {
  static GameSetupRecommendation recommendation({
    required int playerCount,
    required GameMode gameMode,
  }) {
    switch (gameMode) {
      case GameMode.original:
        return const GameSetupRecommendation(
          initialCards: 4,
          ghostCopies: 0,
          extraSilenceCopies: 0,
          extraSealedCardCopies: 0,
        );

      case GameMode.expansionBalanced:
        return GameSetupRecommendation(
          initialCards: playerCount <= 6 ? 4 : 5,
          ghostCopies: switch (playerCount) {
            3 => 1,
            4 => 1,
            5 => 4,
            6 => 2,
            7 => 1,
            8 => 2,
            _ => 1,
          },
          extraSilenceCopies: 0,
          extraSealedCardCopies: 0,
        );

      case GameMode.expansionFullHand:
        return GameSetupRecommendation(
          initialCards: 6,
          ghostCopies: playerCount >= 7 ? 2 : 1,
          extraSilenceCopies: 1,
          extraSealedCardCopies: 1,
        );
    }
  }

  static String titleForMode(GameMode mode) {
    switch (mode) {
      case GameMode.original:
        return 'Original';
      case GameMode.expansionBalanced:
        return 'Ecos da Mansão — Balanceado';
      case GameMode.expansionFullHand:
        return 'Ecos da Mansão — Mão Cheia';
    }
  }

  static String descriptionForMode(GameMode mode) {
    switch (mode) {
      case GameMode.original:
        return 'Jogo base, sem cartas da expansão, usando 4 cartas iniciais.';
      case GameMode.expansionBalanced:
        return 'Expansão com ajuste automático para manter o Culpado levemente favorecido.';
      case GameMode.expansionFullHand:
        return 'Mais cartas na mão, mais estratégia, mais efeitos e mais caos controlado.';
    }
  }
}