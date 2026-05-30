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
  final currentPlayer = gameState.currentPlayer;

  currentPlayer.hand.removeWhere((item) => item.id == card.id);
  currentPlayer.playedCards.add(card);

  final accompliceWasPlayed = card.templateId == 'cumplice';

  if (accompliceWasPlayed) {
    currentPlayer.isAccomplice = true;

    // O turno só avança depois que o efeito do Cúmplice for resolvido.
    return;
  }

  final poisonedCupWasPlayed = card.templateId == 'taca_envenenada';

  if (poisonedCupWasPlayed) {
    // O turno só avança depois que o efeito da Taça Envenenada for resolvido.
    return;
  }

  final detectiveWasPlayed = card.templateId == 'detetive';

  if (detectiveWasPlayed) {
    // O turno só avança depois que o efeito do Detetive for resolvido.
    return;
  }

  final guiltyWasPlayed = card.templateId == 'culpado';

  if (guiltyWasPlayed) {
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
    player.score += 2;
    roundPointsByPlayerId[player.id] = 2;
  }

  final scoringSummary = gameState.players.map((player) {
    final points = roundPointsByPlayerId[player.id] ?? 0;

    if (points == 0) {
      return '${player.name}: 0 pontos';
    }

    return '${player.name}: +$points pontos';
  }).join('\n');

  gameState.roundFinished = true;
  gameState.roundResult = RoundResult(
    type: RoundResultType.guiltyWins,
    winner: guiltyPlayer,
    reason: reason,
    scoringSummary: scoringSummary,
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
    detectivePlayer.score += 2;
    roundPointsByPlayerId[detectivePlayer.id] = 2;
  }

  for (final player in gameState.players) {
    final isDetective = player.id == detectivePlayer.id;
    final isGuilty = player.id == guiltyPlayer.id;
    final isAccomplice = player.isAccomplice;

    if (!isDetective && !isGuilty && !isAccomplice) {
      player.score += 1;
      roundPointsByPlayerId[player.id] = 1;
    }
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