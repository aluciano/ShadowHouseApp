class OfficialSetupRules {
  static Map<String, int> mandatoryCardsForPlayerCount(int playerCount) {
    switch (playerCount) {
      case 3:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 0,
          'xerife': 1,
          'alibi': 1,
        };
      case 4:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 1,
          'xerife': 1,
          'alibi': 1,
        };
      case 5:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 1,
          'xerife': 1,
          'alibi': 2,
        };
      case 6:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 2,
          'cumplice': 2,
          'xerife': 1,
          'alibi': 2,
        };
      case 7:
      case 8:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 2,
          'cumplice': 2,
          'xerife': 1,
          'alibi': 3,
        };
      default:
        throw ArgumentError('Quantidade de jogadores inválida: $playerCount');
    }
  }
}