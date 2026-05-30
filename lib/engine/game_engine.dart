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
  }

  final guiltyWasPlayed = card.templateId == 'culpado';

  if (guiltyWasPlayed) {
    final winners = gameState.players.where((player) {
      final isGuiltyPlayer = player.id == currentPlayer.id;
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
      winner: currentPlayer,
      reason: '${currentPlayer.name} jogou o Culpado como última carta da mão.',
      scoringSummary: scoringSummary,
      roundPointsByPlayerId: roundPointsByPlayerId,
    );

    return;
  }

  gameState.moveToNextPlayer();
}