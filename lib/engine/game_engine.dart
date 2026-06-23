import 'dart:math';

import '../data/card_database.dart';
import '../data/official_setup_rules.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/game_setup.dart';
import '../models/player.dart';
import '../models/player_type.dart';
import '../models/round_result.dart';
import '../models/round_result_type.dart';

GameState createInitialGameState(GameSetup setup) {
  final random = Random();

  final playerCount = setup.playerNames.length;
  final cardsToDeal = playerCount * setup.initialCards;

  final pool = [
    ...CardDatabase.originalDeck(),
    ...CardDatabase.expansionDeck(setup),
  ];

  final selectedCards = <GameCard>[];

  final mandatoryCards =
  OfficialSetupRules.mandatoryCardsForPlayerCount(playerCount);

  for (final entry in mandatoryCards.entries) {
    final templateId = entry.key;
    final quantity = entry.value;

    for (int i = 0; i < quantity; i++) {
      final cardIndex = pool.indexWhere(
            (card) => card.templateId == templateId,
      );

      if (cardIndex == -1) {
        throw StateError('Carta obrigatória não encontrada: $templateId');
      }

      selectedCards.add(pool.removeAt(cardIndex));
    }
  }

  final additionalCardsNeeded = cardsToDeal - selectedCards.length;

  if (additionalCardsNeeded < 0) {
    throw StateError(
      'Há mais cartas obrigatórias do que cartas para distribuir.',
    );
  }

  if (additionalCardsNeeded > pool.length) {
    throw StateError(
      'Não há cartas suficientes para distribuir $cardsToDeal cartas.',
    );
  }

  pool.shuffle(random);

  selectedCards.addAll(pool.take(additionalCardsNeeded));
  pool.removeRange(0, additionalCardsNeeded);

  selectedCards.shuffle(random);
  pool.shuffle(random);

  final players = setup.playerNames.asMap().entries.map((entry) {
    final index = entry.key;
    final name = entry.value;

    return Player(
      id: 'player_$index',
      name: name,
      type: PlayerType.localHuman,
      hand: [],
      playedCards: [],
    );
  }).toList();

  for (int i = 0; i < selectedCards.length; i++) {
    final playerIndex = i % players.length;
    players[playerIndex].hand.add(selectedCards[i]);
  }

  final firstPlayerIndex = players.indexWhere(
        (player) => player.hand.any(
          (card) => card.templateId == 'primeiro_na_cena',
    ),
  );

  return GameState(
    setup: setup,
    players: players,
    deck: pool,
    currentPlayerIndex: firstPlayerIndex == -1 ? 0 : firstPlayerIndex,
    initialDeckSize: pool.length,
  );
}

GameState createNextRoundGameState(GameState previousState) {
  final nextState = createInitialGameState(previousState.setup);

  for (int i = 0; i < nextState.players.length; i++) {
    nextState.players[i].score = previousState.players[i].score;
  }

  return nextState;
}

void playCard({
  required GameState gameState,
  required GameCard card,
}) {
  _applyPlayedCard(
    gameState: gameState,
    card: card,
    removeFromCurrentPlayerHand: true,
    addCardToCurrentPlayerTable: true,
  );
}

void playExternalCard({
  required GameState gameState,
  required GameCard card,
  bool addCardToCurrentPlayerTable = true,
}) {
  _applyPlayedCard(
    gameState: gameState,
    card: card,
    removeFromCurrentPlayerHand: false,
    addCardToCurrentPlayerTable: addCardToCurrentPlayerTable,
  );
}

void _applyPlayedCard({
  required GameState gameState,
  required GameCard card,
  required bool removeFromCurrentPlayerHand,
  required bool addCardToCurrentPlayerTable,
}) {
  final currentPlayer = gameState.currentPlayer;

  if (removeFromCurrentPlayerHand) {
    currentPlayer.hand.removeWhere((item) => item.id == card.id);
  }

  if (addCardToCurrentPlayerTable) {
    currentPlayer.playedCards.add(card);
  }

  final accompliceWasPlayed = card.templateId == 'cumplice';

  if (accompliceWasPlayed) {
    currentPlayer.isAccomplice = true;
    return;
  }

  final poisonedCupWasPlayed = card.templateId == 'taca_envenenada';

  if (poisonedCupWasPlayed) {
    return;
  }

  final detectiveWasPlayed = card.templateId == 'detetive';

  if (detectiveWasPlayed) {
    return;
  }

  final totoWasPlayed = card.templateId == 'toto';

  if (totoWasPlayed) {
    return;
  }

  final sheriffWasPlayed = card.templateId == 'xerife';

  if (sheriffWasPlayed) {
    return;
  }

  final rustyKeyWasPlayed = card.templateId == 'chave_enferrujada';

  if (rustyKeyWasPlayed) {
    return;
  }

  final familyBabyWasPlayed = card.templateId == 'bebe_da_familia';

  if (familyBabyWasPlayed) {
    return;
  }

  final butlerWasPlayed = card.templateId == 'mordomo';

  if (butlerWasPlayed) {
    return;
  }

  final portraitWasPlayed = card.templateId == 'retrato_na_parede';

  if (portraitWasPlayed) {
    return;
  }

  final spyWasPlayed = card.templateId == 'espiao';

  if (spyWasPlayed) {
    return;
  }

  final ghostWasPlayed = card.templateId == 'fantasma_do_visconde';

  if (ghostWasPlayed) {
    return;
  }

  final witnessWasPlayed = card.templateId == 'testemunha';

  if (witnessWasPlayed) {
    return;
  }

  final finalWordWasPlayed = card.templateId == 'palavra_final';

  if (finalWordWasPlayed) {
    return;
  }

  final brokenMaskWasPlayed = card.templateId == 'mascara_quebrada';

  if (brokenMaskWasPlayed) {
    return;
  }

  final unfinishedBusinessWasPlayed = card.templateId == 'assunto_inacabado';

  if (unfinishedBusinessWasPlayed) {
    return;
  }

  final lullabyWasPlayed = card.templateId == 'cancao_de_ninar';

  if (lullabyWasPlayed) {
    return;
  }

  final sealedCardWasPlayed = card.templateId == 'carta_selada';

  if (sealedCardWasPlayed) {
    return;
  }

  final secretOathWasPlayed = card.templateId == 'juramento_secreto';

  if (secretOathWasPlayed) {
    return;
  }

  final silenceWasPlayed = card.templateId == 'silencio_na_mansao';

  if (silenceWasPlayed) {
    return;
  }

  final betrayalWasPlayed = card.templateId == 'traicao_no_salao';

  if (betrayalWasPlayed) {
    return;
  }

  final threeDestiniesWasPlayed = card.templateId == 'tres_destinos';

  if (threeDestiniesWasPlayed) {
    return;
  }

  final pianoWasPlayed = card.templateId == 'piano_desafinado';

  if (pianoWasPlayed) {
    return;
  }

  final swapWasPlayed = card.templateId == 'trocar';

  if (swapWasPlayed) {
    return;
  }

  final frenzyWasPlayed = card.templateId == 'frenesi';

  if (frenzyWasPlayed) {
    return;
  }

  final shareWasPlayed = card.templateId == 'compartilhar';

  if (shareWasPlayed) {
    return;
  }

  final rumorsWasPlayed = card.templateId == 'rumores';

  if (rumorsWasPlayed) {
    return;
  }

  final guiltyWasPlayed = card.templateId == 'culpado';

  if (guiltyWasPlayed) {
    if (currentPlayer.hasHandcuffs) {
      finishRoundWithHandcuffsWin(
        gameState: gameState,
        guiltyPlayer: currentPlayer,
        reason:
        '${currentPlayer.name} revelou o Culpado como última carta, mas estava com algemas.',
      );

      return;
    }

    finishRoundWithGuiltyWin(
      gameState: gameState,
      guiltyPlayer: currentPlayer,
      reason: '${currentPlayer.name} jogou o Culpado como última carta da mão.',
    );

    return;
  }

  gameState.moveToNextPlayer();
}

void resolveForcedDiscardEffect({
  required GameState gameState,
  required Player targetPlayer,
  required GameCard cardToDiscard,
  required String effectName,
}) {
  final wasLastCardInHand = targetPlayer.hand.length == 1;
  final guiltyWasDiscarded = cardToDiscard.templateId == 'culpado';

  targetPlayer.hand.removeWhere((card) => card.id == cardToDiscard.id);
  targetPlayer.playedCards.add(
    cardToDiscard.copyWith(wasDiscarded: true),
  );

  if (guiltyWasDiscarded && wasLastCardInHand) {
    if (targetPlayer.hasHandcuffs) {
      finishRoundWithHandcuffsWin(
        gameState: gameState,
        guiltyPlayer: targetPlayer,
        reason:
        '${targetPlayer.name} descartou o Culpado como última carta pelo efeito de $effectName, mas estava com algemas.',
      );

      return;
    }

    finishRoundWithGuiltyWin(
      gameState: gameState,
      guiltyPlayer: targetPlayer,
      reason:
      '${targetPlayer.name} descartou o Culpado como última carta da mão pelo efeito de $effectName.',
    );

    return;
  }

  if (gameState.deck.isNotEmpty) {
    targetPlayer.hand.add(gameState.deck.removeAt(0));
  }

  gameState.moveToNextPlayer();
}

void finishRoundWithGuiltyWin({
  required GameState gameState,
  required Player guiltyPlayer,
  required String reason,
}) {
  final winners = gameState.players.where((player) {
    final isGuiltyPlayer = player.id == guiltyPlayer.id;
    final isOtherAccomplice = player.isAccomplice && !isGuiltyPlayer;

    return isGuiltyPlayer || isOtherAccomplice;
  }).toList();

  final roundPointsByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    roundPointsByPlayerId[player.id] = 0;
  }

  for (final player in winners) {
    roundPointsByPlayerId[player.id] = 2;
  }

  _finalizeRoundScoring(
    gameState: gameState,
    roundResultType: RoundResultType.guiltyWins,
    winner: guiltyPlayer,
    reason: reason,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );
}

String resolveDetectiveEffect({
  required GameState gameState,
  required Player detectivePlayer,
  required Player targetPlayer,
}) {
  final targetHasGuilty = targetPlayer.hand.any(
        (card) => card.templateId == 'culpado',
  );

  final targetHasAlibi = targetPlayer.hand.any(
        (card) => card.templateId == 'alibi',
  );

  if (targetHasGuilty && !targetHasAlibi) {
    if (targetPlayer.hasHandcuffs) {
      finishRoundWithHandcuffsWin(
        gameState: gameState,
        guiltyPlayer: targetPlayer,
        reason:
        '${detectivePlayer.name} revelou que ${targetPlayer.name} era o Culpado, mas ele estava com algemas.',
      );

      return '${targetPlayer.name} era o Culpado e estava com algemas!';
    }

    finishRoundWithDetectiveWin(
      gameState: gameState,
      detectivePlayer: detectivePlayer,
      guiltyPlayer: targetPlayer,
    );

    return '${targetPlayer.name} era o Culpado!';
  }

  gameState.moveToNextPlayer();

  return '${targetPlayer.name} respondeu: “Não, eu não sou o culpado.”';
}

void finishRoundWithDetectiveWin({
  required GameState gameState,
  required Player detectivePlayer,
  required Player guiltyPlayer,
}) {
  final detectiveCanScore = !detectivePlayer.isAccomplice;

  final roundPointsByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    roundPointsByPlayerId[player.id] = 0;
  }

  if (detectiveCanScore) {
    roundPointsByPlayerId[detectivePlayer.id] = 2;
  }

  for (final player in gameState.players) {
    final isDetective = player.id == detectivePlayer.id;
    final isGuilty = player.id == guiltyPlayer.id;
    final isAccomplice = player.isAccomplice;

    if (!isDetective && !isGuilty && !isAccomplice) {
      roundPointsByPlayerId[player.id] = 1;
    }
  }

  _applySecretOathScoringImmediate(
    gameState: gameState,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );

  for (final player in gameState.players) {
    player.score += roundPointsByPlayerId[player.id] ?? 0;
  }

  final scoringSummary = gameState.players.map((player) {
    final points = roundPointsByPlayerId[player.id] ?? 0;

    if (points == 0) {
      return '${player.name}: 0 pontos';
    }

    return '${player.name}: +$points ponto${points == 1 ? '' : 's'}';
  }).join('\n');

  gameState.roundFinished = true;
  gameState.roundResult = RoundResult(
    type: RoundResultType.detectiveWins,
    winner: detectivePlayer,
    reason: detectiveCanScore
        ? '${detectivePlayer.name} revelou corretamente o Culpado.'
        : '${detectivePlayer.name} revelou o Culpado, mas já era Cúmplice e não venceu a rodada.',
    scoringSummary: scoringSummary,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );
}

void resolveTotoEffect({
  required GameState gameState,
  required Player totoPlayer,
  required Player targetPlayer,
  required GameCard revealedCard,
}) {
  final revealedGuilty = revealedCard.templateId == 'culpado';

  if (revealedGuilty) {
    if (targetPlayer.hasHandcuffs) {
      finishRoundWithHandcuffsWin(
        gameState: gameState,
        guiltyPlayer: targetPlayer,
        reason:
        '${totoPlayer.name} revelou o Culpado com Totó, mas ${targetPlayer.name} estava com algemas.',
      );

      return;
    }

    finishRoundWithTotoWin(
      gameState: gameState,
      totoPlayer: totoPlayer,
      guiltyPlayer: targetPlayer,
    );

    return;
  }

  gameState.moveToNextPlayer();
}

void finishRoundWithTotoWin({
  required GameState gameState,
  required Player totoPlayer,
  required Player guiltyPlayer,
}) {
  final totoCanScore = !totoPlayer.isAccomplice;

  final roundPointsByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    roundPointsByPlayerId[player.id] = 0;
  }

  if (totoCanScore) {
    roundPointsByPlayerId[totoPlayer.id] = 3;
  }

  for (final player in gameState.players) {
    final isTotoPlayer = player.id == totoPlayer.id;
    final isGuilty = player.id == guiltyPlayer.id;
    final isAccomplice = player.isAccomplice;

    if (!isTotoPlayer && !isGuilty && !isAccomplice) {
      roundPointsByPlayerId[player.id] = 1;
    }
  }

  _applySecretOathScoringImmediate(
    gameState: gameState,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );

  for (final player in gameState.players) {
    player.score += roundPointsByPlayerId[player.id] ?? 0;
  }

  final scoringSummary = gameState.players.map((player) {
    final points = roundPointsByPlayerId[player.id] ?? 0;

    if (points == 0) {
      return '${player.name}: 0 pontos';
    }

    return '${player.name}: +$points ponto${points == 1 ? '' : 's'}';
  }).join('\n');

  gameState.roundFinished = true;
  gameState.roundResult = RoundResult(
    type: RoundResultType.totoWins,
    winner: totoPlayer,
    reason: totoCanScore
        ? '${totoPlayer.name} revelou o Culpado com Totó.'
        : '${totoPlayer.name} revelou o Culpado com Totó, mas já era Cúmplice e não venceu a rodada.',
    scoringSummary: scoringSummary,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );
}

void resolveHandcuffsEffect({
  required GameState gameState,
  required Player targetPlayer,
}) {
  for (final player in gameState.players) {
    player.hasHandcuffs = false;
  }

  targetPlayer.hasHandcuffs = true;

  gameState.moveToNextPlayer();
}

void finishRoundWithHandcuffsWin({
  required GameState gameState,
  required Player guiltyPlayer,
  required String reason,
}) {
  final roundPointsByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    roundPointsByPlayerId[player.id] = 0;
  }

  for (final player in gameState.players) {
    final isGuilty = player.id == guiltyPlayer.id;
    final isAccomplice = player.isAccomplice;

    if (!isGuilty && !isAccomplice) {
      roundPointsByPlayerId[player.id] = 1;
    }
  }

  _applySecretOathScoringImmediate(
    gameState: gameState,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );

  for (final player in gameState.players) {
    player.score += roundPointsByPlayerId[player.id] ?? 0;
  }

  final scoringSummary = gameState.players.map((player) {
    final points = roundPointsByPlayerId[player.id] ?? 0;

    if (points == 0) {
      return '${player.name}: 0 pontos';
    }

    return '${player.name}: +$points ponto${points == 1 ? '' : 's'}';
  }).join('\n');

  gameState.roundFinished = true;
  gameState.roundResult = RoundResult(
    type: RoundResultType.handcuffsWins,
    reason: reason,
    scoringSummary: scoringSummary,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );
}

void _finalizeRoundScoring({
  required GameState gameState,
  required RoundResultType roundResultType,
  required Player? winner,
  required String reason,
  required Map<String, int> roundPointsByPlayerId,
}) {
  _applySecretOathScoringImmediate(
    gameState: gameState,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );

  for (final player in gameState.players) {
    player.score += roundPointsByPlayerId[player.id] ?? 0;
  }

  final scoringSummary = gameState.players.map((player) {
    final points = roundPointsByPlayerId[player.id] ?? 0;

    if (points == 0) {
      return '${player.name}: 0 pontos';
    }

    return '${player.name}: +$points ponto${points == 1 ? '' : 's'}';
  }).join('\n');

  gameState.roundFinished = true;
  gameState.roundResult = RoundResult(
    type: roundResultType,
    winner: winner,
    reason: reason,
    scoringSummary: scoringSummary,
    roundPointsByPlayerId: roundPointsByPlayerId,
  );
}

void _applySecretOathScoringImmediate({
  required GameState gameState,
  required Map<String, int> roundPointsByPlayerId,
}) {
  final firstPlayerId = gameState.secretOathPlayerId;
  final secondPlayerId = gameState.secretOathPartnerPlayerId;

  if (firstPlayerId == null || secondPlayerId == null) {
    return;
  }

  final firstPoints = roundPointsByPlayerId[firstPlayerId] ?? 0;
  final secondPoints = roundPointsByPlayerId[secondPlayerId] ?? 0;

  if (firstPoints > 0 && secondPoints == 0) {
    final bonus = max(0, firstPoints - 1);
    roundPointsByPlayerId[secondPlayerId] = bonus;
    return;
  }

  if (secondPoints > 0 && firstPoints == 0) {
    final bonus = max(0, secondPoints - 1);
    roundPointsByPlayerId[firstPlayerId] = bonus;
  }
}

Player findGuiltyPlayer(GameState gameState) {
  return gameState.players.firstWhere(
        (player) => player.hand.any(
          (card) => card.templateId == 'culpado',
    ),
  );
}

void resolveFamilyBabyEffect({
  required GameState gameState,
}) {
  gameState.moveToNextPlayer();
}

bool playerHandHasGuiltyOrAccomplice(Player player) {
  return player.hand.any((card) {
    return card.templateId == 'culpado' || card.templateId == 'cumplice';
  });
}

void resolveWitnessWithoutExchange({
  required GameState gameState,
}) {
  gameState.moveToNextPlayer();
}

void resolveWitnessExchange({
  required GameState gameState,
  required Player witnessPlayer,
  required GameCard witnessCard,
  required Player targetPlayer,
  required GameCard targetCard,
}) {
  witnessPlayer.hand.removeWhere((card) => card.id == witnessCard.id);
  targetPlayer.hand.removeWhere((card) => card.id == targetCard.id);

  witnessPlayer.hand.add(targetCard);
  targetPlayer.hand.add(witnessCard);

  gameState.moveToNextPlayer();
}

void resolveCardExchange({
  required GameState gameState,
  required Player actingPlayer,
  required GameCard actingPlayerCard,
  required Player targetPlayer,
  required GameCard targetPlayerCard,
}) {
  actingPlayer.hand.removeWhere((card) => card.id == actingPlayerCard.id);
  targetPlayer.hand.removeWhere((card) => card.id == targetPlayerCard.id);

  actingPlayer.hand.add(targetPlayerCard);
  targetPlayer.hand.add(actingPlayerCard);

  gameState.moveToNextPlayer();
}

Map<String, int> resolveCircularCardPassEffect({
  required GameState gameState,
  required Map<String, GameCard> selectedCardByPlayerId,
  required bool passToLeft,
}) {
  final cardsToMove = <String, GameCard>{};

  final receivedCardsCountByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    receivedCardsCountByPlayerId[player.id] = 0;
  }

  for (final entry in selectedCardByPlayerId.entries) {
    final playerId = entry.key;
    final selectedCard = entry.value;

    final player = gameState.players.firstWhere(
          (player) => player.id == playerId,
    );

    player.hand.removeWhere((card) => card.id == selectedCard.id);
    cardsToMove[playerId] = selectedCard;
  }

  for (final entry in cardsToMove.entries) {
    final sourcePlayerId = entry.key;
    final card = entry.value;

    final sourceIndex = gameState.players.indexWhere(
          (player) => player.id == sourcePlayerId,
    );

    final targetIndex = passToLeft
        ? (sourceIndex + 1) % gameState.players.length
        : (sourceIndex - 1 + gameState.players.length) %
        gameState.players.length;

    final targetPlayer = gameState.players[targetIndex];

    targetPlayer.hand.add(card);
    receivedCardsCountByPlayerId[targetPlayer.id] =
        (receivedCardsCountByPlayerId[targetPlayer.id] ?? 0) + 1;
  }

  gameState.moveToNextPlayer();

  return receivedCardsCountByPlayerId;
}

class RumorCardSelection {
  const RumorCardSelection({
    required this.receiverPlayerId,
    required this.sourcePlayerId,
    required this.card,
  });

  final String receiverPlayerId;
  final String sourcePlayerId;
  final GameCard card;
}

Map<String, int> resolveRumorsEffect({
  required GameState gameState,
  required List<RumorCardSelection> selections,
}) {
  final receivedCardsCountByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    receivedCardsCountByPlayerId[player.id] = 0;
  }

  for (final selection in selections) {
    final sourcePlayer = gameState.players.firstWhere(
          (player) => player.id == selection.sourcePlayerId,
    );

    sourcePlayer.hand.removeWhere(
          (card) => card.id == selection.card.id,
    );
  }

  for (final selection in selections) {
    final receiverPlayer = gameState.players.firstWhere(
          (player) => player.id == selection.receiverPlayerId,
    );

    receiverPlayer.hand.add(selection.card);

    receivedCardsCountByPlayerId[receiverPlayer.id] =
        (receivedCardsCountByPlayerId[receiverPlayer.id] ?? 0) + 1;
  }

  gameState.moveToNextPlayer();

  return receivedCardsCountByPlayerId;
}

List<GameCard> previewFrenzyCards({
  required Iterable<GameCard> cards,
}) {
  final random = Random();
  final shuffledCards = List<GameCard>.from(cards);

  shuffledCards.shuffle(random);

  return shuffledCards;
}

bool playerHasSealedCards(Player player) {
  return player.playedCards.any((card) => card.isFaceDown);
}

bool isDirectQuestionCardBlocked({
  required GameState gameState,
  required GameCard card,
}) {
  if (gameState.silenceOwnerPlayerId == null) {
    return false;
  }

  return card.templateId == 'detetive' || card.templateId == 'toto';
}

void schedulePianoEffect({
  required GameState gameState,
  required Player actingPlayer,
  required Player targetPlayer,
}) {
  gameState.pianoControllerPlayerId = actingPlayer.id;
  gameState.pianoTargetPlayerId = targetPlayer.id;
  gameState.moveToNextPlayer();
}

void clearScheduledPianoEffect({
  required GameState gameState,
}) {
  gameState.pianoControllerPlayerId = null;
  gameState.pianoTargetPlayerId = null;
}

class PianoForcedPlayResult {
  const PianoForcedPlayResult({
    required this.playedCard,
    this.revealedGuiltyCard,
  });

  final GameCard playedCard;
  final GameCard? revealedGuiltyCard;
}

PianoForcedPlayResult resolvePianoForcedPlay({
  required GameState gameState,
}) {
  final targetPlayer = gameState.currentPlayer;
  final random = Random();
  final handCards = List<GameCard>.from(targetPlayer.hand);

  if (handCards.isEmpty) {
    throw StateError('O jogador alvo do Piano Desafinado não tem cartas na mão.');
  }

  GameCard? guiltyCard;
  for (final card in handCards) {
    if (card.templateId == 'culpado') {
      guiltyCard = card;
      break;
    }
  }
  GameCard? revealedGuiltyCard;
  late final GameCard playedCard;

  if (handCards.length == 1 && guiltyCard != null) {
    playedCard = guiltyCard;
  } else {
    final randomCard = handCards[random.nextInt(handCards.length)];

    if (randomCard.templateId == 'culpado' && guiltyCard != null) {
      revealedGuiltyCard = guiltyCard;
      final alternativeCards = handCards
          .where((card) => card.templateId != 'culpado')
          .toList();
      playedCard = alternativeCards[random.nextInt(alternativeCards.length)];
    } else {
      playedCard = randomCard;
    }
  }

  clearScheduledPianoEffect(gameState: gameState);
  playCard(
    gameState: gameState,
    card: playedCard,
  );

  return PianoForcedPlayResult(
    playedCard: playedCard,
    revealedGuiltyCard: revealedGuiltyCard,
  );
}

void resolveSecretOathEffect({
  required GameState gameState,
  required Player actingPlayer,
  required Player targetPlayer,
}) {
  gameState.secretOathPlayerId = actingPlayer.id;
  gameState.secretOathPartnerPlayerId = targetPlayer.id;
  gameState.moveToNextPlayer();
}

List<GameCard> drawCardsFromDeck({
  required GameState gameState,
  int count = 1,
}) {
  final drawCount = min(count, gameState.deck.length);
  final drawnCards = gameState.deck.take(drawCount).toList();

  if (drawnCards.isNotEmpty) {
    gameState.deck.removeRange(0, drawCount);
  }

  return drawnCards;
}

void placeCardsAsNoEffect({
  required Player player,
  required Iterable<GameCard> cards,
}) {
  player.playedCards.addAll(
    cards.map((card) => card.copyWith(wasDiscarded: true)),
  );
}

void resolveSilenceEffect({
  required GameState gameState,
  required Player actingPlayer,
}) {
  gameState.silenceOwnerPlayerId = actingPlayer.id;
  gameState.moveToNextPlayer();
}

void resolveBetrayalEffect({
  required GameState gameState,
  required Player targetPlayer,
}) {
  targetPlayer.isAccomplice = false;
  gameState.moveToNextPlayer();
}

List<GameCard> frenzyContributionCards({
  required GameState gameState,
  required Iterable<String> participantPlayerIds,
  required Map<String, GameCard> selectedCardByPlayerId,
}) {
  final cards = <GameCard>[];

  for (final playerId in participantPlayerIds) {
    final player = gameState.players.firstWhere((item) => item.id == playerId);
    final sealedCards = player.playedCards.where((card) => card.isFaceDown).toList();

    if (sealedCards.isNotEmpty) {
      cards.addAll(
        sealedCards.map(
          (card) => card.copyWith(isFaceDown: false),
        ),
      );
      continue;
    }

    final selectedCard = selectedCardByPlayerId[playerId];

    if (selectedCard != null) {
      cards.add(selectedCard);
    }
  }

  return cards;
}

class FrenzyResolution {
  const FrenzyResolution({
    required this.receivedCardCountByPlayerId,
    required this.receivedCardNameByPlayerId,
  });

  final Map<String, int> receivedCardCountByPlayerId;
  final Map<String, String> receivedCardNameByPlayerId;
}

FrenzyResolution resolveFrenzyEffect({
  required GameState gameState,
  required List<String> participantPlayerIds,
  required Map<String, GameCard> selectedCardByPlayerId,
}) {
  final random = Random();
  final chosenCards = <GameCard>[];
  final receivedCardsCountByPlayerId = <String, int>{};
  final receivedCardNameByPlayerId = <String, String>{};
  final contributionCountByPlayerId = <String, int>{};

  for (final player in gameState.players) {
    receivedCardsCountByPlayerId[player.id] = 0;
    contributionCountByPlayerId[player.id] = 0;
  }

  for (final playerId in participantPlayerIds) {
    final player = gameState.players.firstWhere(
      (item) => item.id == playerId,
    );
    final sealedCards = player.playedCards.where((card) => card.isFaceDown).toList();

    if (sealedCards.isNotEmpty) {
      player.playedCards.removeWhere((card) => card.isFaceDown);
      chosenCards.addAll(
        sealedCards.map((card) => card.copyWith(isFaceDown: false)),
      );
      contributionCountByPlayerId[player.id] =
          (contributionCountByPlayerId[player.id] ?? 0) + sealedCards.length;
      continue;
    }

    final selectedCard = selectedCardByPlayerId[playerId];

    if (selectedCard != null) {
      player.hand.removeWhere((card) => card.id == selectedCard.id);
      chosenCards.add(selectedCard);
      contributionCountByPlayerId[player.id] =
          (contributionCountByPlayerId[player.id] ?? 0) + 1;
    }
  }

  chosenCards.shuffle(random);

  var cardIndex = 0;

  for (final playerId in participantPlayerIds) {
    final player = gameState.players.firstWhere(
      (item) => item.id == playerId,
    );
    final contributionCount = contributionCountByPlayerId[player.id] ?? 0;
    final receivedNames = <String>[];

    for (var count = 0; count < contributionCount; count++) {
      final receivedCard = chosenCards[cardIndex++];

      player.hand.add(receivedCard);
      receivedCardsCountByPlayerId[player.id] =
          (receivedCardsCountByPlayerId[player.id] ?? 0) + 1;
      receivedNames.add(receivedCard.name);
    }

    if (receivedNames.isNotEmpty) {
      receivedCardNameByPlayerId[player.id] = receivedNames.join(', ');
    }
  }

  gameState.moveToNextPlayer();

  return FrenzyResolution(
    receivedCardCountByPlayerId: receivedCardsCountByPlayerId,
    receivedCardNameByPlayerId: receivedCardNameByPlayerId,
  );
}

void resolveBrokenMaskEffect({
  required GameState gameState,
}) {
  gameState.moveToNextPlayer();
}

bool resolveUnfinishedBusinessEffect({
  required GameState gameState,
  required Player targetPlayer,
}) {
  if (gameState.deck.isNotEmpty) {
    targetPlayer.hand.add(gameState.deck.removeAt(0));
    gameState.moveToNextPlayer();
    return true;
  }

  gameState.moveToNextPlayer();
  return false;
}

List<String> resolveLullabyEffect({
  required GameState gameState,
}) {
  final hints = <String>[];

  for (final player in gameState.players) {
    final hasDetective = player.hand.any(
      (card) => card.templateId == 'detetive',
    );
    final hasToto = player.hand.any(
      (card) => card.templateId == 'toto',
    );

    if (hasDetective && hasToto) {
      hints.add('${player.name} está com Detetive e Totó.');
    } else if (hasDetective) {
      hints.add('${player.name} está com Detetive.');
    } else if (hasToto) {
      hints.add('${player.name} está com Totó.');
    }
  }

  return hints;
}

void finishLullabyEffect({
  required GameState gameState,
}) {
  gameState.moveToNextPlayer();
}

GameCard sealRandomCardFromHand({
  required GameState gameState,
  required Player targetPlayer,
}) {
  final random = Random();
  final selectedCard = targetPlayer.hand[random.nextInt(targetPlayer.hand.length)];

  targetPlayer.hand.removeWhere((card) => card.id == selectedCard.id);
  targetPlayer.playedCards.add(
    selectedCard.copyWith(isFaceDown: true),
  );

  gameState.moveToNextPlayer();
  return selectedCard;
}
