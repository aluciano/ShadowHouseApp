import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import '../models/online_game_session.dart';
import '../models/online_pending_effect.dart';
import '../models/player.dart';
import '../repositories/repository_registry.dart';
import '../widgets/shadow_background.dart';
import 'online_round_result_screen.dart';

OnlineActiveProtection? _blockingProtectionForPlayer({
  required OnlineGameSession session,
  required Player player,
  required OnlineEffectType effectType,
}) {
  for (final protection in session.activeProtections) {
    if (protection.playerId != player.id) {
      continue;
    }

    if (protection.cardTemplateId == 'criada' &&
        effectType == OnlineEffectType.detective) {
      return protection;
    }

    if (protection.cardTemplateId == 'governanta' &&
        (effectType == OnlineEffectType.toto ||
            effectType == OnlineEffectType.handcuffs)) {
      return protection;
    }
  }

  return null;
}

Player _playerToRightInGameState({
  required GameState gameState,
  required Player currentPlayer,
}) {
  final currentIndex = gameState.players.indexWhere(
    (player) => player.id == currentPlayer.id,
  );
  final rightIndex =
      (currentIndex - 1 + gameState.players.length) % gameState.players.length;

  return gameState.players[rightIndex];
}

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({
    super.key,
    required this.session,
    required this.currentPlayerId,
  });

  final OnlineGameSession session;
  final String currentPlayerId;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  bool isSavingMove = false;
  bool isResolvingEffect = false;
  bool isOpeningRoundResult = false;
  bool finishedMatchWasRecorded = false;

  Player currentDevicePlayer(GameState gameState) {
    return gameState.players.firstWhere(
      (player) => player.id == widget.currentPlayerId,
      orElse: () => gameState.currentPlayer,
    );
  }

  Future<void> _saveCurrentSession(
    OnlineGameSession session, {
    bool clearExpiredProtections = true,
  }) async {
    final updatedSession = clearExpiredProtections
        ? session.copyWith(
            activeProtections: _clearExpiredProtections(session),
          )
        : session;

    await RepositoryRegistry.onlineGame.saveCurrentSession(updatedSession);
  }

  List<OnlineActiveProtection> _clearExpiredProtections(
    OnlineGameSession session,
  ) {
    final currentPlayerId = session.gameState.currentPlayer.id;

    return session.activeProtections.where((protection) {
      return protection.playerId.isNotEmpty &&
          protection.playerId != currentPlayerId;
    }).toList();
  }

  List<OnlineActiveProtection> _activeProtectionsAfterCard({
    required OnlineGameSession session,
    required GameState gameState,
    required Player player,
    required GameCard card,
  }) {
    final updatedSession = session.copyWith(gameState: gameState);
    final protections = _clearExpiredProtections(updatedSession);
    final newProtection = _protectionForCard(
      player: player,
      card: card,
    );

    if (newProtection == null) {
      return protections;
    }

    return [
      ...protections.where((protection) {
        return protection.playerId != newProtection.playerId ||
            protection.cardTemplateId != newProtection.cardTemplateId;
      }),
      newProtection,
    ];
  }

  OnlineActiveProtection? _protectionForCard({
    required Player player,
    required GameCard card,
  }) {
    if (card.templateId == 'criada') {
      return OnlineActiveProtection(
        playerId: player.id,
        cardTemplateId: card.templateId,
        cardName: card.name,
        description:
            'O Detetive não pode questionar ${player.name} até a próxima vez de ${player.name}.',
      );
    }

    if (card.templateId == 'governanta') {
      return OnlineActiveProtection(
        playerId: player.id,
        cardTemplateId: card.templateId,
        cardName: card.name,
        description:
            'Totó e Xerife não podem escolher ${player.name} até a próxima vez de ${player.name}.',
      );
    }

    return null;
  }

  List<String> _shareParticipantPlayerIds(GameState gameState) {
    return gameState.players
        .where((player) => player.hand.isNotEmpty)
        .map((player) => player.id)
        .toList();
  }

  List<String> _rumorsParticipantPlayerIds(GameState gameState) {
    return gameState.players.where((player) {
      final sourcePlayer = _playerToRightInGameState(
        gameState: gameState,
        currentPlayer: player,
      );
 
      return sourcePlayer.hand.isNotEmpty;
    }).map((player) => player.id).toList();
  }

  OnlinePendingEffect? _preparePendingEffect({
    required GameState gameState,
    required OnlinePendingEffect? effect,
  }) {
    if (effect == null) {
      return null;
    }

    switch (effect.type) {
      case OnlineEffectType.share:
        return effect.copyWith(
          participantPlayerIds: _shareParticipantPlayerIds(gameState),
        );
      case OnlineEffectType.rumors:
        return effect.copyWith(
          participantPlayerIds: _rumorsParticipantPlayerIds(gameState),
        );
      case OnlineEffectType.frenzy:
        return effect.copyWith(
          participantPlayerIds: _shareParticipantPlayerIds(gameState),
        );
      default:
        return effect;
    }
  }

  Future<void> playOnlineCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    if (isSavingMove || session.pendingEffect != null) {
      return;
    }

    final gameState = session.gameState;
    final player = currentDevicePlayer(gameState);
    final isCurrentPlayer = player.id == gameState.currentPlayer.id;

    if (!isCurrentPlayer) {
      showMessage('Aguarde sua vez para jogar.');
      return;
    }

    final isFirstTurnOfRound = gameState.players.every(
      (player) => player.playedCards.isEmpty,
    );
    final isFirstSceneCard = card.templateId == 'primeiro_na_cena';

    if (isFirstTurnOfRound && !isFirstSceneCard) {
      showMessage('A primeira carta da rodada deve ser Primeiro na Cena.');
      return;
    }

    final isGuiltyCard = card.templateId == 'culpado';
    final isLastCardInHand = player.hand.length == 1;

    if (isGuiltyCard && !isLastCardInHand) {
      showMessage('Você só pode jogar o Culpado como última carta da mão.');
      return;
    }

    final shouldPlay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(card.name),
          content: Text('${card.shortText}\n\nDeseja jogar esta carta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Jogar'),
            ),
          ],
        );
      },
    );

    if (shouldPlay != true) {
      return;
    }

    setState(() {
      isSavingMove = true;
    });

    try {
      final previousPlayerId = gameState.currentPlayer.id;
      final isDetectiveCard = card.templateId == 'detetive';
      final isTotoCard = card.templateId == 'toto';
      final isHandcuffsCard =
          card.templateId == 'xerife' ||
          card.templateId == 'chave_enferrujada';
      final isAccompliceCard = card.templateId == 'cumplice';
      final isPoisonedCupCard = card.templateId == 'taca_envenenada';
      final isProtectionCancelCard = card.templateId == 'palavra_final';
      final createsPendingEffect =
          _pendingEffectForCard(
            card: card,
            actingPlayerId: player.id,
          ) != null;
      final hasPendingResolution =
          isDetectiveCard ||
          isTotoCard ||
          isHandcuffsCard ||
          isAccompliceCard ||
          isPoisonedCupCard ||
          isProtectionCancelCard ||
          createsPendingEffect;

      playCard(
        gameState: gameState,
        card: card,
      );

      if (!gameState.roundFinished &&
          !hasPendingResolution &&
          gameState.currentPlayer.id == previousPlayerId) {
        gameState.moveToNextPlayer();
      }

      final pendingEffect = _preparePendingEffect(
        gameState: gameState,
        effect: _pendingEffectForCard(
        card: card,
        actingPlayerId: player.id,
        ),
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: gameState,
          pendingEffect: pendingEffect,
          activeProtections: _activeProtectionsAfterCard(
            session: session,
            gameState: gameState,
            player: player,
            card: card,
          ),
        ),
        clearExpiredProtections: true,
      );

      if (_cardNeedsOnlineResolution(card)) {
        showMessage(
          'Efeito de ${card.name} será resolvido online em uma próxima etapa.',
        );
      }
    } catch (error) {
      showMessage('Não foi possível salvar a jogada: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSavingMove = false;
        });
      }
    }
  }

  OnlinePendingEffect? _pendingEffectForCard({
    required GameCard card,
    required String actingPlayerId,
  }) {
    if (card.templateId == 'detetive') {
      return OnlinePendingEffect(
        type: OnlineEffectType.detective,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'toto') {
      return OnlinePendingEffect(
        type: OnlineEffectType.toto,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'xerife') {
      return OnlinePendingEffect(
        type: OnlineEffectType.handcuffs,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
        allowSelfTarget: false,
      );
    }

    if (card.templateId == 'chave_enferrujada') {
      return OnlinePendingEffect(
        type: OnlineEffectType.handcuffs,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
        allowSelfTarget: true,
      );
    }

    if (card.templateId == 'cumplice') {
      return OnlinePendingEffect(
        type: OnlineEffectType.accomplice,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'taca_envenenada') {
      return OnlinePendingEffect(
        type: OnlineEffectType.poisonedCup,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'testemunha') {
      return OnlinePendingEffect(
        type: OnlineEffectType.witness,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'bebe_da_familia') {
      return OnlinePendingEffect(
        type: OnlineEffectType.familyBaby,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'adivinho') {
      return OnlinePendingEffect(
        type: OnlineEffectType.publicNotice,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'palavra_final') {
      return OnlinePendingEffect(
        type: OnlineEffectType.protectionCancel,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'trocar') {
      return OnlinePendingEffect(
        type: OnlineEffectType.swap,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'compartilhar') {
      return OnlinePendingEffect(
        type: OnlineEffectType.share,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'rumores') {
      return OnlinePendingEffect(
        type: OnlineEffectType.rumors,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    if (card.templateId == 'frenesi') {
      return OnlinePendingEffect(
        type: OnlineEffectType.frenzy,
        actingPlayerId: actingPlayerId,
        cardName: card.name,
      );
    }

    return null;
  }

  Future<void> resolveDetectiveTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final detectivePlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final resultMessage = resolveDetectiveEffect(
        gameState: session.gameState,
        detectivePlayer: detectivePlayer,
        targetPlayer: target,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            resultMessage: resultMessage,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível resolver o Detetive: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectTotoTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher o alvo do Totó: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipTotoWithoutTarget(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar o efeito do Totó: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveTotoCard({
    required OnlineGameSession session,
    required GameCard revealedCard,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || effect.targetPlayerId == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final totoPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final targetPlayer = _playerById(
        session.gameState,
        effect.targetPlayerId!,
      );

      resolveTotoEffect(
        gameState: session.gameState,
        totoPlayer: totoPlayer,
        targetPlayer: targetPlayer,
        revealedCard: revealedCard,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            revealedCardId: revealedCard.id,
            revealedCardName: revealedCard.name,
            revealedCardTemplateId: revealedCard.templateId,
            resultMessage: _totoResultMessage(
              targetPlayer: targetPlayer,
              revealedCard: revealedCard,
            ),
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível resolver o Totó: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveHandcuffsTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final actingPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );

      resolveHandcuffsEffect(
        gameState: session.gameState,
        targetPlayer: target,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            resultMessage:
                '${actingPlayer.name} colocou as algemas em ${target.name}.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível resolver as Algemas: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipHandcuffsWithoutTarget(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar o efeito de Algemas: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectForcedDiscardTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher o alvo: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveForcedDiscardCard({
    required OnlineGameSession session,
    required GameCard cardToDiscard,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || effect.targetPlayerId == null || isResolvingEffect) {
      return;
    }

    final targetPlayer = _playerById(
      session.gameState,
      effect.targetPlayerId!,
    );
    final isGuiltyCard = cardToDiscard.templateId == 'culpado';
    final isLastCardInHand = targetPlayer.hand.length == 1;

    if (isGuiltyCard && !isLastCardInHand) {
      showMessage(
        'O Culpado só pode ser descartado se for a última carta da mão.',
      );
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final hadCardInDeck = session.gameState.deck.isNotEmpty;

      resolveForcedDiscardEffect(
        gameState: session.gameState,
        targetPlayer: targetPlayer,
        cardToDiscard: cardToDiscard,
        effectName: effect.cardName,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            revealedCardId: cardToDiscard.id,
            revealedCardName: cardToDiscard.name,
            revealedCardTemplateId: cardToDiscard.templateId,
            resultMessage: _forcedDiscardResultMessage(
              gameState: session.gameState,
              targetPlayer: targetPlayer,
              discardedCard: cardToDiscard,
              hadCardInDeck: hadCardInDeck,
            ),
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível resolver o descarte: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipForcedDiscardWithoutTarget(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar o efeito: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectWitnessTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher o alvo da Testemunha: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> finishWitnessWithoutExchange(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || effect.targetPlayerId == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final witnessPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final targetPlayer = _playerById(
        session.gameState,
        effect.targetPlayerId!,
      );

      resolveWitnessWithoutExchange(gameState: session.gameState);

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            resultMessage:
                '${witnessPlayer.name} investigou ${targetPlayer.name} e não fez troca.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível resolver a Testemunha: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectWitnessCardForExchange({
    required OnlineGameSession session,
    required GameCard witnessCard,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            revealedCardId: witnessCard.id,
            revealedCardName: witnessCard.name,
            revealedCardTemplateId: witnessCard.templateId,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher a carta da Testemunha: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveWitnessExchangeCard({
    required OnlineGameSession session,
    required GameCard targetCard,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null ||
        effect.targetPlayerId == null ||
        effect.revealedCardId == null ||
        isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final witnessPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final targetPlayer = _playerById(
        session.gameState,
        effect.targetPlayerId!,
      );
      final witnessCard = _cardById(witnessPlayer.hand, effect.revealedCardId!);

      resolveWitnessExchange(
        gameState: session.gameState,
        witnessPlayer: witnessPlayer,
        witnessCard: witnessCard,
        targetPlayer: targetPlayer,
        targetCard: targetCard,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            secondaryCardId: targetCard.id,
            secondaryCardName: targetCard.name,
            secondaryCardTemplateId: targetCard.templateId,
            resultMessage:
                '${witnessPlayer.name} e ${targetPlayer.name} trocaram cartas pela Testemunha.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir a troca da Testemunha: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipWitnessWithoutTarget(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar a Testemunha: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> revealFamilyBaby(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final guiltyPlayer = findGuiltyPlayer(session.gameState);

      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            targetPlayerId: guiltyPlayer.id,
            resultMessage: 'O Culpado está com ${guiltyPlayer.name}.',
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível revelar o Bebê da Família: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> finishFamilyBaby(OnlineGameSession session) async {
    if (isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      resolveFamilyBabyEffect(gameState: session.gameState);

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar o Bebê da Família: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveProtectionCancelTarget({
    required OnlineGameSession session,
    required OnlineActiveProtection protection,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final actingPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final targetPlayer = _playerById(
        session.gameState,
        protection.playerId,
      );
      final activeProtections = session.activeProtections.where((item) {
        return item.playerId != protection.playerId ||
            item.cardTemplateId != protection.cardTemplateId;
      }).toList();

      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          activeProtections: activeProtections,
          pendingEffect: effect.copyWith(
            targetPlayerId: targetPlayer.id,
            revealedCardName: protection.cardName,
            revealedCardTemplateId: protection.cardTemplateId,
            resultMessage:
                '${actingPlayer.name} desativou ${protection.cardName} de ${targetPlayer.name}.',
            acknowledgedPlayerIds: const [],
          ),
        ),
        clearExpiredProtections: true,
      );
    } catch (error) {
      showMessage('Não foi possível desativar a proteção: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipProtectionCancelWithoutTarget(
    OnlineGameSession session,
  ) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
        clearExpiredProtections: true,
      );
    } catch (error) {
      showMessage('Não foi possível encerrar a Palavra Final: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectSwapTarget({
    required OnlineGameSession session,
    required Player target,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            targetPlayerId: target.id,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher o alvo da troca: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectSwapActingCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            revealedCardId: card.id,
            revealedCardName: card.name,
            revealedCardTemplateId: card.templateId,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível escolher a carta da troca: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> resolveSwapTargetCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null ||
        effect.targetPlayerId == null ||
        effect.revealedCardId == null ||
        isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final actingPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );
      final targetPlayer = _playerById(
        session.gameState,
        effect.targetPlayerId!,
      );
      final actingPlayerCard = _cardById(
        actingPlayer.hand,
        effect.revealedCardId!,
      );

      resolveCardExchange(
        gameState: session.gameState,
        actingPlayer: actingPlayer,
        actingPlayerCard: actingPlayerCard,
        targetPlayer: targetPlayer,
        targetPlayerCard: card,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            secondaryCardId: card.id,
            secondaryCardName: card.name,
            secondaryCardTemplateId: card.templateId,
            resultMessage:
                '${actingPlayer.name} e ${targetPlayer.name} trocaram uma carta.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir a troca: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipSwapWithoutTarget(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar a troca: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectShareCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    final selectedCardIdsByPlayerId = Map<String, String>.from(
      effect.selectedCardIdsByPlayerId,
    );
    final selectedCardNamesByPlayerId = Map<String, String>.from(
      effect.selectedCardNamesByPlayerId,
    );
    final completedPlayerIds = {
      ...effect.completedPlayerIds,
      widget.currentPlayerId,
    }.toList();

    selectedCardIdsByPlayerId[widget.currentPlayerId] = card.id;
    selectedCardNamesByPlayerId[widget.currentPlayerId] = card.name;

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final everyoneSelected = effect.participantPlayerIds.every(
        completedPlayerIds.contains,
      );

      if (!everyoneSelected) {
        await _saveCurrentSession(
          session.copyWith(
            pendingEffect: effect.copyWith(
              completedPlayerIds: completedPlayerIds,
              selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
              selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            ),
          ),
        );
        return;
      }

      final previewCards = previewFrenzyCards(
        cards: effect.participantPlayerIds.map((playerId) {
          final player = _playerById(session.gameState, playerId);
          final selectedCardId = selectedCardIdsByPlayerId[playerId];

          if (selectedCardId == null) {
            throw StateError('Carta do Frenesi não encontrada para $playerId.');
          }

          return _cardById(player.hand, selectedCardId);
        }),
      );

      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            completedPlayerIds: completedPlayerIds,
            selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
            selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            previewCardNames: previewCards.map((card) => card.name).toList(),
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir Frenesi!!!: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipShareWithoutParticipants(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar Compartilhar: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectRumorsCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    final selectedCardIdsByPlayerId = Map<String, String>.from(
      effect.selectedCardIdsByPlayerId,
    );
    final selectedCardNamesByPlayerId = Map<String, String>.from(
      effect.selectedCardNamesByPlayerId,
    );
    final completedPlayerIds = {
      ...effect.completedPlayerIds,
      widget.currentPlayerId,
    }.toList();

    selectedCardIdsByPlayerId[widget.currentPlayerId] = card.id;
    selectedCardNamesByPlayerId[widget.currentPlayerId] = card.name;

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final everyoneSelected = effect.participantPlayerIds.every(
        completedPlayerIds.contains,
      );

      if (!everyoneSelected) {
        await _saveCurrentSession(
          session.copyWith(
            pendingEffect: effect.copyWith(
              completedPlayerIds: completedPlayerIds,
              selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
              selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            ),
          ),
        );
        return;
      }

      final selections = <RumorCardSelection>[];

      for (final playerId in effect.participantPlayerIds) {
        final receiverPlayer = _playerById(session.gameState, playerId);
        final sourcePlayer = _playerToRightInGameState(
          gameState: session.gameState,
          currentPlayer: receiverPlayer,
        );
        final selectedCardId = selectedCardIdsByPlayerId[playerId];

        if (selectedCardId == null) {
          continue;
        }

        selections.add(
          RumorCardSelection(
            receiverPlayerId: receiverPlayer.id,
            sourcePlayerId: sourcePlayer.id,
            card: _cardById(sourcePlayer.hand, selectedCardId),
          ),
        );
      }

      final summary = resolveRumorsEffect(
        gameState: session.gameState,
        selections: selections,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            completedPlayerIds: completedPlayerIds,
            selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
            selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            receivedCardCountByPlayerId: summary,
            resultMessage:
                'Cada jogador recebeu, quando possível, uma carta do jogador à direita.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir Rumores: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipRumorsWithoutCards(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    final completedPlayerIds = {
      ...effect.completedPlayerIds,
      widget.currentPlayerId,
    }.toList();

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final everyoneSelected = effect.participantPlayerIds.every(
        completedPlayerIds.contains,
      );

      if (!everyoneSelected) {
        await _saveCurrentSession(
          session.copyWith(
            pendingEffect: effect.copyWith(
              completedPlayerIds: completedPlayerIds,
            ),
          ),
        );
        return;
      }

      final summary = resolveRumorsEffect(
        gameState: session.gameState,
        selections: const [],
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            completedPlayerIds: completedPlayerIds,
            receivedCardCountByPlayerId: summary,
            resultMessage:
                'Cada jogador recebeu, quando possível, uma carta do jogador à direita.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível continuar Rumores: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> selectFrenzyCard({
    required OnlineGameSession session,
    required GameCard card,
  }) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    final selectedCardIdsByPlayerId = Map<String, String>.from(
      effect.selectedCardIdsByPlayerId,
    );
    final selectedCardNamesByPlayerId = Map<String, String>.from(
      effect.selectedCardNamesByPlayerId,
    );
    final completedPlayerIds = {
      ...effect.completedPlayerIds,
      widget.currentPlayerId,
    }.toList();

    selectedCardIdsByPlayerId[widget.currentPlayerId] = card.id;
    selectedCardNamesByPlayerId[widget.currentPlayerId] = card.name;

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final everyoneSelected = effect.participantPlayerIds.every(
        completedPlayerIds.contains,
      );

      if (!everyoneSelected) {
        await _saveCurrentSession(
          session.copyWith(
            pendingEffect: effect.copyWith(
              completedPlayerIds: completedPlayerIds,
              selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
              selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            ),
          ),
        );
        return;
      }

      final previewCards = previewFrenzyCards(
        cards: effect.participantPlayerIds.map((playerId) {
          final player = _playerById(session.gameState, playerId);
          final selectedCardId = selectedCardIdsByPlayerId[playerId];

          if (selectedCardId == null) {
            throw StateError('Carta do Frenesi não encontrada para $playerId.');
          }

          return _cardById(player.hand, selectedCardId);
        }),
      );

      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            completedPlayerIds: completedPlayerIds,
            selectedCardIdsByPlayerId: selectedCardIdsByPlayerId,
            selectedCardNamesByPlayerId: selectedCardNamesByPlayerId,
            previewCardNames: previewCards.map((card) => card.name).toList(),
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir Frenesi!!!: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> finalizeFrenzyShuffle(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final selectedCardsByPlayerId = <String, GameCard>{};

      for (final playerId in effect.participantPlayerIds) {
        final player = _playerById(session.gameState, playerId);
        final selectedCardId = effect.selectedCardIdsByPlayerId[playerId];

        if (selectedCardId == null) {
          continue;
        }

        selectedCardsByPlayerId[playerId] = _cardById(
          player.hand,
          selectedCardId,
        );
      }

      final frenzyResolution = resolveFrenzyEffect(
        gameState: session.gameState,
        selectedCardByPlayerId: selectedCardsByPlayerId,
      );

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          pendingEffect: effect.copyWith(
            receivedCardCountByPlayerId:
                frenzyResolution.receivedCardCountByPlayerId,
            receivedCardNamesByPlayerId:
                frenzyResolution.receivedCardNameByPlayerId,
            previewCardNames: const [],
            resultMessage:
                'As cartas escolhidas foram embaralhadas e redistribuídas entre os participantes.',
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível concluir Frenesi!!!: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> skipFrenzyWithoutParticipants(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      session.gameState.moveToNextPlayer();

      await _saveCurrentSession(
        session.copyWith(
          gameState: session.gameState,
          clearPendingEffect: true,
        ),
      );
    } catch (error) {
      showMessage('Não foi possível encerrar Frenesi!!!: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  String _forcedDiscardResultMessage({
    required GameState gameState,
    required Player targetPlayer,
    required GameCard discardedCard,
    required bool hadCardInDeck,
  }) {
    if (gameState.roundFinished) {
      return gameState.roundResult?.reason ??
          '${targetPlayer.name} descartou ${discardedCard.name}.';
    }

    if (hadCardInDeck) {
      return '${targetPlayer.name} descartou ${discardedCard.name} e comprou uma carta.';
    }

    return '${targetPlayer.name} descartou ${discardedCard.name}.';
  }

  String _totoResultMessage({
    required Player targetPlayer,
    required GameCard revealedCard,
  }) {
    if (revealedCard.templateId == 'culpado') {
      return '${targetPlayer.name} estava com o Culpado!';
    }

    return 'A carta não era o Culpado. Ela volta para a mão de ${targetPlayer.name}.';
  }

  Future<void> submitPublicNoticeMessage({
    required OnlineGameSession session,
    required String message,
    bool allowEmptyMessage = false,
  }) async {
    final effect = session.pendingEffect;
    final trimmedMessage = message.trim();

    if (effect == null || isResolvingEffect) {
      return;
    }

    if (trimmedMessage.isEmpty && !allowEmptyMessage) {
      showMessage('Escreva a mensagem que será compartilhada com todos.');
      return;
    }

    setState(() {
      isResolvingEffect = true;
    });

    try {
      final actingPlayer = _playerById(
        session.gameState,
        effect.actingPlayerId,
      );

      final resultMessage = trimmedMessage.isEmpty
          ? '${actingPlayer.name} decidiu não compartilhar impressões com a mesa.'
          : '${actingPlayer.name} compartilhou: "$trimmedMessage"';

      await _saveCurrentSession(
        session.copyWith(
          pendingEffect: effect.copyWith(
            resultMessage: resultMessage,
            acknowledgedPlayerIds: const [],
          ),
        ),
      );
    } catch (error) {
      showMessage('Não foi possível compartilhar a mensagem: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> acknowledgePendingEffect(OnlineGameSession session) async {
    final effect = session.pendingEffect;

    if (effect == null || isResolvingEffect) {
      return;
    }

    final acknowledgedPlayerIds = {
      ...effect.acknowledgedPlayerIds,
      widget.currentPlayerId,
    }.toList();
    final expectedViewerIds = _expectedViewerIds(session);
    final everyoneAcknowledged =
        expectedViewerIds.every(acknowledgedPlayerIds.contains);

    setState(() {
      isResolvingEffect = true;
    });

    try {
      if (everyoneAcknowledged && effect.type == OnlineEffectType.publicNotice) {
        session.gameState.moveToNextPlayer();
      }

      await _saveCurrentSession(
        everyoneAcknowledged
            ? session.copyWith(clearPendingEffect: true)
            : session.copyWith(
                pendingEffect: effect.copyWith(
                  acknowledgedPlayerIds: acknowledgedPlayerIds,
                ),
              ),
      );
    } catch (error) {
      showMessage('Não foi possível confirmar a visualização: $error');
    } finally {
      if (mounted) {
        setState(() {
          isResolvingEffect = false;
        });
      }
    }
  }

  Future<void> openRoundResult(OnlineGameSession session) async {
    if (isOpeningRoundResult) {
      return;
    }

    isOpeningRoundResult = true;

    await recordFinishedMatchIfNeeded(session);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineRoundResultScreen(
          session: session,
          currentPlayerId: widget.currentPlayerId,
        ),
      ),
    );
  }

  Future<void> recordFinishedMatchIfNeeded(OnlineGameSession session) async {
    final gameState = session.gameState;
    final highestScore = gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);
    final isMatchFinished = highestScore >= 5;
    final currentDeviceIsHost = widget.currentPlayerId == session.room.hostPlayerId;

    if (!isMatchFinished || !currentDeviceIsHost || finishedMatchWasRecorded) {
      return;
    }

    finishedMatchWasRecorded = true;

    final finishedAt = DateTime.now();
    final winnerNames = gameState.players
        .where((player) => player.score == highestScore)
        .map((player) => player.name)
        .toList();

    await RepositoryRegistry.matchHistory.saveMatch(
      MatchHistoryEntry(
        id: _historyEntryIdForSession(session),
        playMode: MatchPlayMode.online,
        gameMode: gameState.setup.gameMode,
        startedAt: session.startedAt,
        finishedAt: finishedAt,
        playerNames: gameState.players.map((player) => player.name).toList(),
        winnerNames: winnerNames,
        roundsPlayed: session.roundsPlayed,
        roomCode: session.room.code,
      ),
    );
  }

  String _historyEntryIdForSession(OnlineGameSession session) {
    return [
      'online',
      session.room.id,
      session.startedAt.microsecondsSinceEpoch,
    ].join('_');
  }

  bool _cardNeedsOnlineResolution(GameCard card) {
    return {
      'testemunha',
    }.contains(card.templateId);
  }

  Player _playerById(GameState gameState, String playerId) {
    return gameState.players.firstWhere((player) => player.id == playerId);
  }

  GameCard _cardById(List<GameCard> cards, String cardId) {
    return cards.firstWhere((card) => card.id == cardId);
  }

  List<String> _expectedViewerIds(OnlineGameSession session) {
    return session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala ${widget.session.room.code}'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: StreamBuilder<OnlineGameSession>(
            stream: RepositoryRegistry.onlineGame.watchCurrentSession(
              widget.session.room,
            ),
            initialData: widget.session,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Não foi possível atualizar a partida: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final session = snapshot.data ?? widget.session;
              final gameState = session.gameState;
              final currentPlayer = gameState.currentPlayer;
              final player = currentDevicePlayer(gameState);
              final isCurrentPlayer = player.id == currentPlayer.id;
              final hasPendingEffect = session.pendingEffect != null;

              if (gameState.roundFinished && !hasPendingEffect) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    openRoundResult(session);
                  }
                });
              }

              return ListView(
                children: [
                  const Text(
                    'Partida Online',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Você está jogando como ${player.name}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasPendingEffect
                        ? 'Resolvendo efeito'
                        : 'Vez de ${currentPlayer.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFE7C76F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (session.pendingEffect != null) ...[
                    _OnlinePendingEffectCard(
                      session: session,
                      currentPlayerId: widget.currentPlayerId,
                      isResolvingEffect: isResolvingEffect,
                      onDetectiveTargetSelected: (target) {
                        resolveDetectiveTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onTotoTargetSelected: (target) {
                        selectTotoTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onTotoCardSelected: (card) {
                        resolveTotoCard(
                          session: session,
                          revealedCard: card,
                        );
                      },
                      onTotoWithoutTarget: () {
                        skipTotoWithoutTarget(session);
                      },
                      onHandcuffsTargetSelected: (target) {
                        resolveHandcuffsTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onHandcuffsWithoutTarget: () {
                        skipHandcuffsWithoutTarget(session);
                      },
                      onAccompliceTargetSelected: (target) {
                        selectForcedDiscardTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onAccompliceCardSelected: (card) {
                        resolveForcedDiscardCard(
                          session: session,
                          cardToDiscard: card,
                        );
                      },
                      onAccompliceWithoutTarget: () {
                        skipForcedDiscardWithoutTarget(session);
                      },
                      onPoisonedCupTargetSelected: (target) {
                        selectForcedDiscardTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onPoisonedCupCardSelected: (card) {
                        resolveForcedDiscardCard(
                          session: session,
                          cardToDiscard: card,
                        );
                      },
                      onPoisonedCupWithoutTarget: () {
                        skipForcedDiscardWithoutTarget(session);
                      },
                      onWitnessTargetSelected: (target) {
                        selectWitnessTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onWitnessContinueWithoutExchange: () {
                        finishWitnessWithoutExchange(session);
                      },
                      onWitnessCardSelected: (card) {
                        selectWitnessCardForExchange(
                          session: session,
                          witnessCard: card,
                        );
                      },
                      onWitnessExchangeCardSelected: (card) {
                        resolveWitnessExchangeCard(
                          session: session,
                          targetCard: card,
                        );
                      },
                      onWitnessWithoutTarget: () {
                        skipWitnessWithoutTarget(session);
                      },
                      onFamilyBabyReveal: () {
                        revealFamilyBaby(session);
                      },
                      onFamilyBabyContinue: () {
                        finishFamilyBaby(session);
                      },
                      onProtectionCancelSelected: (protection) {
                        resolveProtectionCancelTarget(
                          session: session,
                          protection: protection,
                        );
                      },
                      onProtectionCancelWithoutTarget: () {
                        skipProtectionCancelWithoutTarget(session);
                      },
                      onSwapTargetSelected: (target) {
                        selectSwapTarget(
                          session: session,
                          target: target,
                        );
                      },
                      onSwapActingCardSelected: (card) {
                        selectSwapActingCard(
                          session: session,
                          card: card,
                        );
                      },
                      onSwapTargetCardSelected: (card) {
                        resolveSwapTargetCard(
                          session: session,
                          card: card,
                        );
                      },
                      onSwapWithoutTarget: () {
                        skipSwapWithoutTarget(session);
                      },
                      onShareCardSelected: (card) {
                        selectShareCard(
                          session: session,
                          card: card,
                        );
                      },
                      onShareWithoutParticipants: () {
                        skipShareWithoutParticipants(session);
                      },
                      onRumorsCardSelected: (card) {
                        selectRumorsCard(
                          session: session,
                          card: card,
                        );
                      },
                      onRumorsWithoutCards: () {
                        skipRumorsWithoutCards(session);
                      },
                      onFrenzyCardSelected: (card) {
                        selectFrenzyCard(
                          session: session,
                          card: card,
                        );
                      },
                      onFrenzyWithoutParticipants: () {
                        skipFrenzyWithoutParticipants(session);
                      },
                      onFrenzyFinalize: () {
                        finalizeFrenzyShuffle(session);
                      },
                      onPublicNoticeSubmitted: (message) {
                        submitPublicNoticeMessage(
                          session: session,
                          message: message,
                        );
                      },
                      onPublicNoticeSkipped: () {
                        submitPublicNoticeMessage(
                          session: session,
                          message: '',
                          allowEmptyMessage: true,
                        );
                      },
                      onAcknowledge: () {
                        acknowledgePendingEffect(session);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Card(
                    color: const Color(0xFF221229),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sua mão',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE7C76F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hasPendingEffect
                                ? 'Aguarde a resolução do efeito.'
                                : isCurrentPlayer
                                    ? 'Escolha uma carta para jogar.'
                                    : 'Aguardando ${currentPlayer.name} jogar.',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          if (player.hand.isEmpty)
                            const Text(
                              'Nenhuma carta na mão.',
                              style: TextStyle(color: Colors.white54),
                            )
                          else
                            ...player.hand.map((card) {
                              final canPlay = isCurrentPlayer &&
                                  !isSavingMove &&
                                  !hasPendingEffect;

                              return Card(
                                color: const Color(0xFF120818),
                                child: ListTile(
                                  title: Text(
                                    card.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(card.shortText),
                                  trailing: Icon(
                                    canPlay ? Icons.play_arrow : Icons.lock,
                                  ),
                                  onTap: canPlay
                                      ? () => playOnlineCard(
                                            session: session,
                                            card: card,
                                          )
                                      : null,
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _OnlineTableCard(
                    gameState: gameState,
                    currentPlayer: currentPlayer,
                    activeProtections: session.activeProtections,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnlinePendingEffectCard extends StatelessWidget {
  const _OnlinePendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onDetectiveTargetSelected,
    required this.onTotoTargetSelected,
    required this.onTotoCardSelected,
    required this.onTotoWithoutTarget,
    required this.onHandcuffsTargetSelected,
    required this.onHandcuffsWithoutTarget,
    required this.onAccompliceTargetSelected,
    required this.onAccompliceCardSelected,
    required this.onAccompliceWithoutTarget,
    required this.onPoisonedCupTargetSelected,
    required this.onPoisonedCupCardSelected,
    required this.onPoisonedCupWithoutTarget,
    required this.onWitnessTargetSelected,
    required this.onWitnessContinueWithoutExchange,
    required this.onWitnessCardSelected,
    required this.onWitnessExchangeCardSelected,
    required this.onWitnessWithoutTarget,
    required this.onFamilyBabyReveal,
    required this.onFamilyBabyContinue,
    required this.onProtectionCancelSelected,
    required this.onProtectionCancelWithoutTarget,
    required this.onSwapTargetSelected,
    required this.onSwapActingCardSelected,
    required this.onSwapTargetCardSelected,
    required this.onSwapWithoutTarget,
    required this.onShareCardSelected,
    required this.onShareWithoutParticipants,
    required this.onRumorsCardSelected,
    required this.onRumorsWithoutCards,
    required this.onFrenzyCardSelected,
    required this.onFrenzyWithoutParticipants,
    required this.onFrenzyFinalize,
    required this.onPublicNoticeSubmitted,
    required this.onPublicNoticeSkipped,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onDetectiveTargetSelected;
  final ValueChanged<Player> onTotoTargetSelected;
  final ValueChanged<GameCard> onTotoCardSelected;
  final VoidCallback onTotoWithoutTarget;
  final ValueChanged<Player> onHandcuffsTargetSelected;
  final VoidCallback onHandcuffsWithoutTarget;
  final ValueChanged<Player> onAccompliceTargetSelected;
  final ValueChanged<GameCard> onAccompliceCardSelected;
  final VoidCallback onAccompliceWithoutTarget;
  final ValueChanged<Player> onPoisonedCupTargetSelected;
  final ValueChanged<GameCard> onPoisonedCupCardSelected;
  final VoidCallback onPoisonedCupWithoutTarget;
  final ValueChanged<Player> onWitnessTargetSelected;
  final VoidCallback onWitnessContinueWithoutExchange;
  final ValueChanged<GameCard> onWitnessCardSelected;
  final ValueChanged<GameCard> onWitnessExchangeCardSelected;
  final VoidCallback onWitnessWithoutTarget;
  final VoidCallback onFamilyBabyReveal;
  final VoidCallback onFamilyBabyContinue;
  final ValueChanged<OnlineActiveProtection> onProtectionCancelSelected;
  final VoidCallback onProtectionCancelWithoutTarget;
  final ValueChanged<Player> onSwapTargetSelected;
  final ValueChanged<GameCard> onSwapActingCardSelected;
  final ValueChanged<GameCard> onSwapTargetCardSelected;
  final VoidCallback onSwapWithoutTarget;
  final ValueChanged<GameCard> onShareCardSelected;
  final VoidCallback onShareWithoutParticipants;
  final ValueChanged<GameCard> onRumorsCardSelected;
  final VoidCallback onRumorsWithoutCards;
  final ValueChanged<GameCard> onFrenzyCardSelected;
  final VoidCallback onFrenzyWithoutParticipants;
  final VoidCallback onFrenzyFinalize;
  final ValueChanged<String> onPublicNoticeSubmitted;
  final VoidCallback onPublicNoticeSkipped;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;

    switch (effect.type) {
      case OnlineEffectType.detective:
        return _DetectivePendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onTargetSelected: onDetectiveTargetSelected,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.toto:
        return _TotoPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onTargetSelected: onTotoTargetSelected,
          onCardSelected: onTotoCardSelected,
          onWithoutTarget: onTotoWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.handcuffs:
        return _HandcuffsPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onTargetSelected: onHandcuffsTargetSelected,
          onWithoutTarget: onHandcuffsWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.accomplice:
        return _ForcedDiscardPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          title: 'Efeito do Cúmplice',
          icon: Icons.group_add,
          initialStatusBuilder: (actingPlayer) {
            return '${actingPlayer.name} virou Cúmplice e deve escolher um jogador para descartar uma carta.';
          },
          waitingForTargetText:
              'Aguardando o Cúmplice escolher quem descartará uma carta.',
          targetSelectedStatusBuilder: (actingPlayer, targetPlayer) {
            return '${actingPlayer.name} escolheu ${targetPlayer.name}.';
          },
          resolvedStatusBuilder: (targetPlayer) {
            return '${targetPlayer.name} descartou uma carta pelo efeito do Cúmplice.';
          },
          onTargetSelected: onAccompliceTargetSelected,
          onCardSelected: onAccompliceCardSelected,
          onWithoutTarget: onAccompliceWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.poisonedCup:
        return _ForcedDiscardPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          title: 'Efeito da Taça Envenenada',
          icon: Icons.wine_bar,
          initialStatusBuilder: (actingPlayer) {
            return '${actingPlayer.name} deve escolher um jogador para beber da Taça Envenenada.';
          },
          waitingForTargetText:
              'Aguardando a escolha de quem descartará uma carta.',
          targetSelectedStatusBuilder: (actingPlayer, targetPlayer) {
            return '${actingPlayer.name} escolheu ${targetPlayer.name}.';
          },
          resolvedStatusBuilder: (targetPlayer) {
            return '${targetPlayer.name} descartou uma carta pela Taça Envenenada.';
          },
          onTargetSelected: onPoisonedCupTargetSelected,
          onCardSelected: onPoisonedCupCardSelected,
          onWithoutTarget: onPoisonedCupWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.witness:
        return _WitnessPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onTargetSelected: onWitnessTargetSelected,
          onContinueWithoutExchange: onWitnessContinueWithoutExchange,
          onWitnessCardSelected: onWitnessCardSelected,
          onTargetCardSelected: onWitnessExchangeCardSelected,
          onWithoutTarget: onWitnessWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.familyBaby:
        return _FamilyBabyPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onReveal: onFamilyBabyReveal,
          onContinue: onFamilyBabyContinue,
        );
      case OnlineEffectType.publicNotice:
        return _PublicNoticePendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onSubmit: onPublicNoticeSubmitted,
          onSkip: onPublicNoticeSkipped,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.protectionCancel:
        return _ProtectionCancelPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onProtectionSelected: onProtectionCancelSelected,
          onWithoutTarget: onProtectionCancelWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.swap:
        return _SwapPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onTargetSelected: onSwapTargetSelected,
          onActingCardSelected: onSwapActingCardSelected,
          onTargetCardSelected: onSwapTargetCardSelected,
          onWithoutTarget: onSwapWithoutTarget,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.share:
        return _SharePendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onCardSelected: onShareCardSelected,
          onWithoutParticipants: onShareWithoutParticipants,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.rumors:
        return _RumorsPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onCardSelected: onRumorsCardSelected,
          onWithoutCards: onRumorsWithoutCards,
          onAcknowledge: onAcknowledge,
        );
      case OnlineEffectType.frenzy:
        return _FrenzyPendingEffectCard(
          session: session,
          currentPlayerId: currentPlayerId,
          isResolvingEffect: isResolvingEffect,
          onCardSelected: onFrenzyCardSelected,
          onWithoutParticipants: onFrenzyWithoutParticipants,
          onFinalize: onFrenzyFinalize,
          onAcknowledge: onAcknowledge,
        );
    }
  }
}

class _ProtectionCancelPendingEffectCard extends StatelessWidget {
  const _ProtectionCancelPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onProtectionSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<OnlineActiveProtection> onProtectionSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final currentDeviceIsActingPlayer = currentPlayerId == actingPlayer.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final effectWasResolved = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.gavel, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'A Palavra Final',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Carta jogada: ${effect.cardName}',
              style: const TextStyle(
                color: Color(0xFFE7C76F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!effectWasResolved)
              _ProtectionCancelTargetStep(
                session: session,
                actingPlayer: actingPlayer,
                currentDeviceIsActingPlayer: currentDeviceIsActingPlayer,
                isResolvingEffect: isResolvingEffect,
                onProtectionSelected: onProtectionSelected,
                onWithoutTarget: onWithoutTarget,
              )
            else ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProtectionCancelTargetStep extends StatelessWidget {
  const _ProtectionCancelTargetStep({
    required this.session,
    required this.actingPlayer,
    required this.currentDeviceIsActingPlayer,
    required this.isResolvingEffect,
    required this.onProtectionSelected,
    required this.onWithoutTarget,
  });

  final OnlineGameSession session;
  final Player actingPlayer;
  final bool currentDeviceIsActingPlayer;
  final bool isResolvingEffect;
  final ValueChanged<OnlineActiveProtection> onProtectionSelected;
  final VoidCallback onWithoutTarget;

  @override
  Widget build(BuildContext context) {
    if (session.activeProtections.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Não há proteções ativas para desativar.',
            style: TextStyle(color: Colors.white60),
          ),
          if (currentDeviceIsActingPlayer) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isResolvingEffect ? null : onWithoutTarget,
              icon: const Icon(Icons.skip_next),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continuar'),
              ),
            ),
          ],
        ],
      );
    }

    if (!currentDeviceIsActingPlayer) {
      return Text(
        'Aguardando ${actingPlayer.name} escolher qual proteção será desativada.',
        style: const TextStyle(color: Colors.white60),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${actingPlayer.name}, escolha uma proteção ativa para desativar.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        ...session.activeProtections.map((protection) {
          final targetPlayer = session.gameState.players.firstWhere(
            (player) => player.id == protection.playerId,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: isResolvingEffect
                  ? null
                  : () {
                      onProtectionSelected(protection);
                    },
              icon: const Icon(Icons.shield),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '${targetPlayer.name} - ${protection.cardName}',
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _PublicNoticePendingEffectCard extends StatefulWidget {
  const _PublicNoticePendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onSubmit,
    required this.onSkip,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<String> onSubmit;
  final VoidCallback onSkip;
  final VoidCallback onAcknowledge;

  @override
  State<_PublicNoticePendingEffectCard> createState() =>
      _PublicNoticePendingEffectCardState();
}

class _PublicNoticePendingEffectCardState
    extends State<_PublicNoticePendingEffectCard> {
  final TextEditingController messageController = TextEditingController();

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final currentDeviceIsActingPlayer =
        widget.currentPlayerId == actingPlayer.id;
    final messageWasSubmitted = effect.resultMessage != null;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(widget.currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.campaign, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Informação pública',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!messageWasSubmitted) ...[
              if (!currentDeviceIsActingPlayer)
                Text(
                  'Aguardando ${actingPlayer.name} escrever a mensagem do Adivinho.',
                  style: const TextStyle(color: Colors.white60),
                )
              else ...[
                const Text(
                  'Escreva a mensagem que será compartilhada com todos.',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  enabled: !widget.isResolvingEffect,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Mensagem para a mesa',
                    hintText: 'Ex.: Vi algo suspeito na mão da Luísa...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: widget.isResolvingEffect
                      ? null
                      : () {
                          widget.onSubmit(messageController.text);
                        },
                  icon: const Icon(Icons.send),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Compartilhar mensagem'),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: widget.isResolvingEffect ? null : widget.onSkip,
                  icon: const Icon(Icons.visibility_off),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Não compartilhar impressões'),
                  ),
                ),
              ],
            ] else ...[
              Text(
                effect.resultMessage!,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || widget.isResolvingEffect
                    ? null
                    : widget.onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged ? Icons.check_circle : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SwapPendingEffectCard extends StatelessWidget {
  const _SwapPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onActingCardSelected,
    required this.onTargetCardSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final ValueChanged<GameCard> onActingCardSelected;
  final ValueChanged<GameCard> onTargetCardSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsActingPlayer = currentPlayerId == actingPlayer.id;
    final currentDeviceIsTarget = currentPlayerId == targetPlayer?.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      return player.id != actingPlayer.id && player.hand.isNotEmpty;
    }).toList();
    final actingPlayerCardWasSelected = effect.revealedCardId != null;
    final effectWasResolved = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.swap_horiz, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Trocar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (effectWasResolved) ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged ? Icons.check_circle : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ] else if (actingPlayer.hand.isEmpty) ...[
              const Text(
                'Quem jogou Trocar não tem mais cartas na mão. A carta fica sem efeito.',
                style: TextStyle(color: Colors.white70),
              ),
              if (currentDeviceIsActingPlayer) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isResolvingEffect ? null : onWithoutTarget,
                  icon: const Icon(Icons.skip_next),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continuar'),
                  ),
                ),
              ],
            ] else if (targetPlayer == null) ...[
              if (availableTargets.isEmpty) ...[
                const Text(
                  'Não há outros jogadores com cartas na mão para trocar.',
                  style: TextStyle(color: Colors.white70),
                ),
                if (currentDeviceIsActingPlayer) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: isResolvingEffect ? null : onWithoutTarget,
                    icon: const Icon(Icons.skip_next),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Continuar'),
                    ),
                  ),
                ],
              ] else if (currentDeviceIsActingPlayer) ...[
                Text(
                  '${actingPlayer.name}, escolha com quem trocar.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...availableTargets.map((target) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onTargetSelected(target);
                            },
                      icon: const Icon(Icons.person_search),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          '${target.name} (${target.hand.length} carta${target.hand.length == 1 ? '' : 's'})',
                        ),
                      ),
                    ),
                  );
                }),
              ] else
                Text(
                  'Aguardando ${actingPlayer.name} escolher com quem trocar.',
                  style: const TextStyle(color: Colors.white60),
                ),
            ] else if (!actingPlayerCardWasSelected) ...[
              if (currentDeviceIsActingPlayer) ...[
                Text(
                  '${actingPlayer.name}, escolha uma carta da sua mão para trocar com ${targetPlayer.name}.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...actingPlayer.hand.map((card) {
                  return Card(
                    color: const Color(0xFF120818),
                    child: ListTile(
                      title: Text(
                        card.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(card.shortText),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: isResolvingEffect
                          ? null
                          : () {
                              onActingCardSelected(card);
                            },
                    ),
                  );
                }),
              ] else
                Text(
                  'Aguardando ${actingPlayer.name} escolher a própria carta para a troca.',
                  style: const TextStyle(color: Colors.white60),
                ),
            ] else if (effect.secondaryCardId == null) ...[
              if (currentDeviceIsTarget) ...[
                Text(
                  '${targetPlayer.name}, escolha uma carta da sua mão para entregar na troca.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...targetPlayer.hand.map((card) {
                  return Card(
                    color: const Color(0xFF120818),
                    child: ListTile(
                      title: Text(
                        card.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(card.shortText),
                      trailing: const Icon(Icons.swap_horiz),
                      onTap: isResolvingEffect
                          ? null
                          : () {
                              onTargetCardSelected(card);
                            },
                    ),
                  );
                }),
              ] else
                Text(
                  'Aguardando ${targetPlayer.name} escolher a carta da troca.',
                  style: const TextStyle(color: Colors.white60),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SharePendingEffectCard extends StatelessWidget {
  const _SharePendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onCardSelected,
    required this.onWithoutParticipants,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onWithoutParticipants;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final currentPlayer = session.gameState.players.firstWhere(
      (player) => player.id == currentPlayerId,
      orElse: () => session.gameState.currentPlayer,
    );
    final currentPlayerAlreadySelected =
        effect.completedPlayerIds.contains(currentPlayerId);
    final currentPlayerIsParticipant =
        effect.participantPlayerIds.contains(currentPlayerId);
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final selectedCount = effect.completedPlayerIds.length;
    final effectWasResolved = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.compare_arrows, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Compartilhar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (effectWasResolved) ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...session.gameState.players.map((player) {
                final receivedCount =
                    effect.receivedCardCountByPlayerId[player.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(player.name)),
                      Text(
                        '$receivedCount carta${receivedCount == 1 ? '' : 's'} recebida${receivedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: receivedCount > 0
                              ? const Color(0xFFE7C76F)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged ? Icons.check_circle : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ] else if (effect.participantPlayerIds.isEmpty) ...[
              const Text(
                'Nenhum jogador tem cartas disponíveis para Compartilhar.',
                style: TextStyle(color: Colors.white70),
              ),
              if (currentPlayerId == actingPlayer.id) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isResolvingEffect ? null : onWithoutParticipants,
                  icon: const Icon(Icons.skip_next),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continuar'),
                  ),
                ),
              ],
            ] else if (currentPlayerIsParticipant &&
                !currentPlayerAlreadySelected) ...[
              Text(
                '${currentPlayer.name}, escolha uma carta da sua mão para passar à esquerda.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              ...currentPlayer.hand.map((card) {
                return Card(
                  color: const Color(0xFF120818),
                  child: ListTile(
                    title: Text(
                      card.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(card.shortText),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: isResolvingEffect
                        ? null
                        : () {
                            onCardSelected(card);
                          },
                  ),
                );
              }),
            ] else ...[
              Text(
                currentPlayerAlreadySelected
                    ? 'Sua carta já foi registrada. Aguardando os demais jogadores.'
                    : 'Aguardando os jogadores escolherem suas cartas para Compartilhar.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RumorsPendingEffectCard extends StatelessWidget {
  const _RumorsPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onCardSelected,
    required this.onWithoutCards,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onWithoutCards;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final currentPlayer = session.gameState.players.firstWhere(
      (player) => player.id == currentPlayerId,
      orElse: () => session.gameState.currentPlayer,
    );
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final sourcePlayer = _playerToRightInGameState(
      gameState: session.gameState,
      currentPlayer: currentPlayer,
    );
    final currentPlayerAlreadySelected =
        effect.completedPlayerIds.contains(currentPlayerId);
    final currentPlayerIsParticipant =
        effect.participantPlayerIds.contains(currentPlayerId);
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final selectedCount = effect.completedPlayerIds.length;
    final effectWasResolved = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.record_voice_over, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rumores',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (effectWasResolved) ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...session.gameState.players.map((player) {
                final receivedCount =
                    effect.receivedCardCountByPlayerId[player.id] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text(player.name)),
                      Text(
                        '$receivedCount carta${receivedCount == 1 ? '' : 's'} recebida${receivedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: receivedCount > 0
                              ? const Color(0xFFE7C76F)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged ? Icons.check_circle : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ] else if (effect.participantPlayerIds.isEmpty) ...[
              const Text(
                'Ninguém tem cartas disponíveis para Rumores nesta rodada.',
                style: TextStyle(color: Colors.white70),
              ),
              if (currentPlayerId == actingPlayer.id) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isResolvingEffect ? null : onWithoutCards,
                  icon: const Icon(Icons.skip_next),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continuar'),
                  ),
                ),
              ],
            ] else if (currentPlayerIsParticipant &&
                !currentPlayerAlreadySelected) ...[
              Text(
                '${currentPlayer.name}, escolha sem olhar uma carta da mão de ${sourcePlayer.name}.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(sourcePlayer.hand.length, (index) {
                  final card = sourcePlayer.hand[index];

                  return SizedBox(
                    width: 110,
                    height: 90,
                    child: OutlinedButton(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onCardSelected(card);
                            },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.help_outline),
                          const SizedBox(height: 8),
                          Text(
                            'Carta ${index + 1}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ] else ...[
              Text(
                currentPlayerAlreadySelected
                    ? 'Sua escolha em Rumores já foi registrada. Aguardando os demais jogadores.'
                    : 'Aguardando os jogadores concluírem Rumores.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FrenzyPendingEffectCard extends StatelessWidget {
  const _FrenzyPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onCardSelected,
    required this.onWithoutParticipants,
    required this.onFinalize,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onWithoutParticipants;
  final VoidCallback onFinalize;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final currentPlayer = session.gameState.players.firstWhere(
      (player) => player.id == currentPlayerId,
      orElse: () => session.gameState.currentPlayer,
    );
    final currentPlayerAlreadySelected =
        effect.completedPlayerIds.contains(currentPlayerId);
    final currentPlayerIsParticipant =
        effect.participantPlayerIds.contains(currentPlayerId);
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final selectedCount = effect.completedPlayerIds.length;
    final effectWasResolved = effect.resultMessage != null;
    final previewWasPrepared = effect.previewCardNames.isNotEmpty;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.shuffle, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frenesi!!!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (effectWasResolved) ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...session.gameState.players.map((player) {
                final receivedCount =
                    effect.receivedCardCountByPlayerId[player.id] ?? 0;
                final receivedCardName =
                    effect.receivedCardNamesByPlayerId[player.id];
                final isCurrentViewer = player.id == currentPlayerId;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isCurrentViewer && receivedCardName != null
                              ? '${player.name} - sua nova carta: $receivedCardName'
                              : player.name,
                          style: TextStyle(
                            color: isCurrentViewer && receivedCardName != null
                                ? const Color(0xFFE7C76F)
                                : null,
                            fontWeight: isCurrentViewer && receivedCardName != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '$receivedCount carta${receivedCount == 1 ? '' : 's'} recebida${receivedCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: receivedCount > 0
                              ? const Color(0xFFE7C76F)
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged ? Icons.check_circle : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ] else if (effect.participantPlayerIds.isEmpty) ...[
              const Text(
                'Nenhum jogador tem cartas disponíveis para Frenesi!!!',
                style: TextStyle(color: Colors.white70),
              ),
              if (currentPlayerId == actingPlayer.id) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isResolvingEffect ? null : onWithoutParticipants,
                  icon: const Icon(Icons.skip_next),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Continuar'),
                  ),
                ),
              ],
            ] else if (previewWasPrepared) ...[
              if (currentPlayerId == actingPlayer.id) ...[
                const Text(
                  'Prévia embaralhada das cartas escolhidas:',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                ...effect.previewCardNames.map((cardName) {
                  return Card(
                    color: const Color(0xFF120818),
                    child: ListTile(
                      leading: const Icon(
                        Icons.visibility,
                        color: Color(0xFFE7C76F),
                      ),
                      title: Text(
                        cardName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isResolvingEffect ? null : onFinalize,
                  icon: const Icon(Icons.shuffle),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('Embaralhar e redistribuir'),
                  ),
                ),
              ] else
                Text(
                  'Aguardando ${actingPlayer.name} revisar o embaralhamento e liberar a redistribuição final.',
                  style: const TextStyle(color: Colors.white70),
                ),
            ] else if (currentPlayerIsParticipant &&
                !currentPlayerAlreadySelected) ...[
              Text(
                '${currentPlayer.name}, escolha uma carta da sua mão para embaralhar.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 12),
              ...currentPlayer.hand.map((card) {
                return Card(
                  color: const Color(0xFF120818),
                  child: ListTile(
                    title: Text(
                      card.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(card.shortText),
                    trailing: const Icon(Icons.shuffle),
                    onTap: isResolvingEffect
                        ? null
                        : () {
                            onCardSelected(card);
                          },
                  ),
                );
              }),
            ] else ...[
              Text(
                currentPlayerAlreadySelected
                    ? 'Sua carta para o Frenesi já foi registrada. Aguardando os demais jogadores.'
                    : 'Aguardando os jogadores escolherem suas cartas para o Frenesi.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Text(
                '$selectedCount de ${effect.participantPlayerIds.length} jogadores já escolheram.',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FamilyBabyPendingEffectCard extends StatelessWidget {
  const _FamilyBabyPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onReveal,
    required this.onContinue,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final VoidCallback onReveal;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final currentDeviceIsActingPlayer = currentPlayerId == actingPlayer.id;
    final culpritWasRevealed = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.child_care, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'O Bebê da Família',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!currentDeviceIsActingPlayer)
              Text(
                'Somente ${actingPlayer.name} deve visualizar esta informação.',
                style: const TextStyle(color: Colors.white60),
              )
            else if (!culpritWasRevealed) ...[
              const Text(
                'O app vai revelar secretamente quem está com o Culpado.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isResolvingEffect ? null : onReveal,
                icon: const Icon(Icons.visibility),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Revelar Culpado'),
                ),
              ),
            ] else ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Guarde essa informação em segredo.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: isResolvingEffect ? null : onContinue,
                icon: const Icon(Icons.check_circle),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Continuar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WitnessPendingEffectCard extends StatelessWidget {
  const _WitnessPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onContinueWithoutExchange,
    required this.onWitnessCardSelected,
    required this.onTargetCardSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final VoidCallback onContinueWithoutExchange;
  final ValueChanged<GameCard> onWitnessCardSelected;
  final ValueChanged<GameCard> onTargetCardSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final witnessPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsWitness = currentPlayerId == witnessPlayer.id;
    final currentDeviceIsTarget = currentPlayerId == targetPlayer?.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      return player.id != witnessPlayer.id && player.hand.isNotEmpty;
    }).toList();
    final targetWasSelected = targetPlayer != null;
    final witnessCardWasSelected = effect.revealedCardId != null;
    final effectWasResolved = effect.resultMessage != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.visibility, color: Color(0xFFE7C76F)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Efeito da Testemunha',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!targetWasSelected)
              _WitnessTargetStep(
                witnessPlayer: witnessPlayer,
                availableTargets: availableTargets,
                currentDeviceIsWitness: currentDeviceIsWitness,
                isResolvingEffect: isResolvingEffect,
                onTargetSelected: onTargetSelected,
                onWithoutTarget: onWithoutTarget,
              )
            else if (!effectWasResolved && !witnessCardWasSelected)
              _WitnessInspectStep(
                witnessPlayer: witnessPlayer,
                targetPlayer: targetPlayer,
                currentDeviceIsWitness: currentDeviceIsWitness,
                isResolvingEffect: isResolvingEffect,
                onContinueWithoutExchange: onContinueWithoutExchange,
                onWitnessCardSelected: onWitnessCardSelected,
              )
            else if (!effectWasResolved)
              _WitnessTargetExchangeStep(
                witnessCardName: effect.revealedCardName!,
                targetPlayer: targetPlayer,
                currentDeviceIsTarget: currentDeviceIsTarget,
                isResolvingEffect: isResolvingEffect,
                onTargetCardSelected: onTargetCardSelected,
              )
            else ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class _WitnessTargetStep extends StatelessWidget {
  const _WitnessTargetStep({
    required this.witnessPlayer,
    required this.availableTargets,
    required this.currentDeviceIsWitness,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onWithoutTarget,
  });

  final Player witnessPlayer;
  final List<Player> availableTargets;
  final bool currentDeviceIsWitness;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final VoidCallback onWithoutTarget;

  @override
  Widget build(BuildContext context) {
    if (availableTargets.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Não há outros jogadores com cartas na mão para investigar.',
            style: TextStyle(color: Colors.white60),
          ),
          if (currentDeviceIsWitness) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isResolvingEffect ? null : onWithoutTarget,
              icon: const Icon(Icons.skip_next),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Continuar'),
              ),
            ),
          ],
        ],
      );
    }

    if (!currentDeviceIsWitness) {
      return Text(
        'Aguardando ${witnessPlayer.name} escolher quem vai investigar.',
        style: const TextStyle(color: Colors.white60),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${witnessPlayer.name}, escolha quem investigar.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        ...availableTargets.map((target) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton.icon(
              onPressed: isResolvingEffect
                  ? null
                  : () {
                      onTargetSelected(target);
                    },
              icon: const Icon(Icons.visibility),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Investigar ${target.name} (${target.hand.length} carta${target.hand.length == 1 ? '' : 's'})',
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _WitnessInspectStep extends StatelessWidget {
  const _WitnessInspectStep({
    required this.witnessPlayer,
    required this.targetPlayer,
    required this.currentDeviceIsWitness,
    required this.isResolvingEffect,
    required this.onContinueWithoutExchange,
    required this.onWitnessCardSelected,
  });

  final Player witnessPlayer;
  final Player targetPlayer;
  final bool currentDeviceIsWitness;
  final bool isResolvingEffect;
  final VoidCallback onContinueWithoutExchange;
  final ValueChanged<GameCard> onWitnessCardSelected;

  @override
  Widget build(BuildContext context) {
    final foundSuspiciousCard = playerHandHasGuiltyOrAccomplice(targetPlayer);
    final witnessCanExchange = witnessPlayer.hand.isNotEmpty;

    if (!currentDeviceIsWitness) {
      return Text(
        'Somente ${witnessPlayer.name} deve olhar a mão de ${targetPlayer.name}.',
        style: const TextStyle(color: Colors.white60),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Informação secreta para ${witnessPlayer.name}',
          style: const TextStyle(
            color: Color(0xFFE7C76F),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _EffectHandPanel(
          title: 'Mão de ${targetPlayer.name}',
          cards: targetPlayer.hand,
          highlightSuspiciousCards: true,
          emptyMessage: 'Nenhuma carta na mão.',
        ),
        const SizedBox(height: 12),
        _EffectHandPanel(
          title: 'Sua mão',
          cards: witnessPlayer.hand,
          highlightSuspiciousCards: false,
          emptyMessage: 'Você não tem cartas para trocar.',
        ),
        const SizedBox(height: 12),
        if (!foundSuspiciousCard)
          const Text(
            'Nenhum Culpado ou Cúmplice foi encontrado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          )
        else if (!witnessCanExchange)
          const Text(
            'Você encontrou Culpado ou Cúmplice, mas não tem cartas para trocar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          )
        else ...[
          const Text(
            'Culpado ou Cúmplice encontrado. Escolha uma carta sua para trocar.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          ...witnessPlayer.hand.map((card) {
            return Card(
              color: const Color(0xFF120818),
              child: ListTile(
                title: Text(
                  card.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(card.shortText),
                trailing: const Icon(Icons.swap_horiz),
                onTap: isResolvingEffect
                    ? null
                    : () {
                        onWitnessCardSelected(card);
                      },
              ),
            );
          }),
        ],
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: isResolvingEffect ? null : onContinueWithoutExchange,
          icon: const Icon(Icons.skip_next),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              foundSuspiciousCard && witnessCanExchange
                  ? 'Não trocar'
                  : 'Continuar',
            ),
          ),
        ),
      ],
    );
  }
}

class _WitnessTargetExchangeStep extends StatelessWidget {
  const _WitnessTargetExchangeStep({
    required this.witnessCardName,
    required this.targetPlayer,
    required this.currentDeviceIsTarget,
    required this.isResolvingEffect,
    required this.onTargetCardSelected,
  });

  final String witnessCardName;
  final Player targetPlayer;
  final bool currentDeviceIsTarget;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onTargetCardSelected;

  @override
  Widget build(BuildContext context) {
    if (!currentDeviceIsTarget) {
      return Text(
        'Aguardando ${targetPlayer.name} escolher uma carta para entregar em troca.',
        style: const TextStyle(color: Colors.white60),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${targetPlayer.name}, escolha uma carta da sua mão para trocar por $witnessCardName.',
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        ...targetPlayer.hand.map((card) {
          return Card(
            color: const Color(0xFF120818),
            child: ListTile(
              title: Text(
                card.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(card.shortText),
              trailing: const Icon(Icons.swap_horiz),
              onTap: isResolvingEffect
                  ? null
                  : () {
                      onTargetCardSelected(card);
                    },
            ),
          );
        }),
      ],
    );
  }
}

class _EffectHandPanel extends StatelessWidget {
  const _EffectHandPanel({
    required this.title,
    required this.cards,
    required this.highlightSuspiciousCards,
    required this.emptyMessage,
  });

  final String title;
  final List<GameCard> cards;
  final bool highlightSuspiciousCards;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF120818),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE7C76F),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (cards.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...cards.map((card) {
              final suspicious =
                  card.templateId == 'culpado' ||
                  card.templateId == 'cumplice';
              final highlighted = highlightSuspiciousCards && suspicious;

              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  highlighted ? Icons.warning_amber : Icons.visibility,
                  color: highlighted
                      ? const Color(0xFFE7C76F)
                      : Colors.white70,
                ),
                title: Text(card.name),
                subtitle: Text(card.shortText),
              );
            }),
        ],
      ),
    );
  }
}

class _HandcuffsPendingEffectCard extends StatelessWidget {
  const _HandcuffsPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsActingPlayer = currentPlayerId == actingPlayer.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      final isActingPlayer = player.id == actingPlayer.id;
      final hasCardsInHand = player.hand.isNotEmpty;
      final isProtected = _blockingProtectionForPlayer(
            session: session,
            player: player,
            effectType: OnlineEffectType.handcuffs,
          ) !=
          null;

      if (!hasCardsInHand) {
        return false;
      }

      if (isProtected) {
        return false;
      }

      if (!effect.allowSelfTarget && isActingPlayer) {
        return false;
      }

      return true;
    }).toList();

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.link,
                  color: Color(0xFFE7C76F),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Efeito de Algemas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Carta jogada: ${effect.cardName}',
              style: const TextStyle(
                color: Color(0xFFE7C76F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              targetPlayer == null
                  ? '${actingPlayer.name} deve escolher quem receberá as algemas.'
                  : '${actingPlayer.name} colocou as algemas em ${targetPlayer.name}.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (targetPlayer == null) ...[
              if (availableTargets.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Não há jogadores com cartas na mão para receber as algemas.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    if (currentDeviceIsActingPlayer) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: isResolvingEffect ? null : onWithoutTarget,
                        icon: const Icon(Icons.skip_next),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Continuar'),
                        ),
                      ),
                    ],
                  ],
                )
              else if (currentDeviceIsActingPlayer)
                ...availableTargets.map((target) {
                  final alreadyHasHandcuffs = target.hasHandcuffs;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onTargetSelected(target);
                            },
                      icon: Icon(
                        alreadyHasHandcuffs ? Icons.link_off : Icons.link,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          alreadyHasHandcuffs
                              ? '${target.name} — já está com algemas'
                              : '${target.name} (${target.hand.length} carta${target.hand.length == 1 ? '' : 's'})',
                        ),
                      ),
                    ),
                  );
                })
              else
                const Text(
                  'Aguardando a escolha de quem receberá as algemas.',
                  style: TextStyle(color: Colors.white60),
                ),
            ] else ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

typedef InitialForcedDiscardStatusBuilder = String Function(Player actingPlayer);
typedef TargetSelectedForcedDiscardStatusBuilder = String Function(
  Player actingPlayer,
  Player targetPlayer,
);
typedef ResolvedForcedDiscardStatusBuilder = String Function(
  Player targetPlayer,
);

class _ForcedDiscardPendingEffectCard extends StatelessWidget {
  const _ForcedDiscardPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.title,
    required this.icon,
    required this.initialStatusBuilder,
    required this.waitingForTargetText,
    required this.targetSelectedStatusBuilder,
    required this.resolvedStatusBuilder,
    required this.onTargetSelected,
    required this.onCardSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final String title;
  final IconData icon;
  final InitialForcedDiscardStatusBuilder initialStatusBuilder;
  final String waitingForTargetText;
  final TargetSelectedForcedDiscardStatusBuilder targetSelectedStatusBuilder;
  final ResolvedForcedDiscardStatusBuilder resolvedStatusBuilder;
  final ValueChanged<Player> onTargetSelected;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final actingPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsActingPlayer = currentPlayerId == actingPlayer.id;
    final currentDeviceIsTarget = currentPlayerId == targetPlayer?.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      final isActingPlayer = player.id == actingPlayer.id;
      final hasCardsInHand = player.hand.isNotEmpty;

      return !isActingPlayer && hasCardsInHand;
    }).toList();
    final targetWasSelected = targetPlayer != null;
    final cardWasDiscarded = effect.revealedCardName != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: const Color(0xFFE7C76F),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Carta jogada: ${effect.cardName}',
              style: const TextStyle(
                color: Color(0xFFE7C76F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusText(
                actingPlayer: actingPlayer,
                targetPlayer: targetPlayer,
                cardWasDiscarded: cardWasDiscarded,
              ),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (!targetWasSelected) ...[
              if (availableTargets.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Não há outros jogadores com cartas na mão para escolher.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    if (currentDeviceIsActingPlayer) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: isResolvingEffect ? null : onWithoutTarget,
                        icon: const Icon(Icons.skip_next),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Continuar'),
                        ),
                      ),
                    ],
                  ],
                )
              else if (currentDeviceIsActingPlayer)
                ...availableTargets.map((target) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onTargetSelected(target);
                            },
                      icon: const Icon(Icons.person_remove),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Escolher ${target.name} (${target.hand.length} carta${target.hand.length == 1 ? '' : 's'})',
                        ),
                      ),
                    ),
                  );
                })
              else
                Text(
                  waitingForTargetText,
                  style: const TextStyle(color: Colors.white60),
                ),
            ] else if (!cardWasDiscarded) ...[
              if (currentDeviceIsTarget)
                _AccompliceDiscardCards(
                  targetPlayer: targetPlayer,
                  isResolvingEffect: isResolvingEffect,
                  onCardSelected: onCardSelected,
                )
              else
                Text(
                  'Aguardando ${targetPlayer.name} escolher uma carta da própria mão para descartar.',
                  style: const TextStyle(color: Colors.white60),
                ),
            ] else ...[
              Text(
                effect.revealedCardName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText({
    required Player actingPlayer,
    required Player? targetPlayer,
    required bool cardWasDiscarded,
  }) {
    if (targetPlayer == null) {
      return initialStatusBuilder(actingPlayer);
    }

    if (!cardWasDiscarded) {
      return targetSelectedStatusBuilder(actingPlayer, targetPlayer);
    }

    return resolvedStatusBuilder(targetPlayer);
  }
}

class _AccompliceDiscardCards extends StatelessWidget {
  const _AccompliceDiscardCards({
    required this.targetPlayer,
    required this.isResolvingEffect,
    required this.onCardSelected,
  });

  final Player targetPlayer;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onCardSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Escolha uma carta da sua mão para descartar.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        ...targetPlayer.hand.map((card) {
          final isBlockedGuilty =
              card.templateId == 'culpado' && targetPlayer.hand.length > 1;

          return Card(
            color: const Color(0xFF120818),
            child: ListTile(
              title: Text(
                card.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                isBlockedGuilty
                    ? 'O Culpado só pode ser descartado como última carta.'
                    : card.shortText,
              ),
              trailing: Icon(
                isBlockedGuilty ? Icons.lock : Icons.delete_outline,
              ),
              onTap: isBlockedGuilty || isResolvingEffect
                  ? null
                  : () {
                      onCardSelected(card);
                    },
            ),
          );
        }),
      ],
    );
  }
}

class _TotoPendingEffectCard extends StatelessWidget {
  const _TotoPendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onCardSelected,
    required this.onWithoutTarget,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onWithoutTarget;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final totoPlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsToto = currentPlayerId == totoPlayer.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      final isTotoPlayer = player.id == totoPlayer.id;
      final hasCardsInHand = player.hand.isNotEmpty;
      final isProtected = _blockingProtectionForPlayer(
            session: session,
            player: player,
            effectType: OnlineEffectType.toto,
          ) !=
          null;

      return !isTotoPlayer && hasCardsInHand && !isProtected;
    }).toList();
    final targetWasSelected = targetPlayer != null;
    final cardWasRevealed = effect.revealedCardName != null;

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.pets,
                  color: Color(0xFFE7C76F),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Efeito do Totó',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _statusText(
                totoPlayer: totoPlayer,
                targetPlayer: targetPlayer,
                cardWasRevealed: cardWasRevealed,
              ),
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (!targetWasSelected) ...[
              if (availableTargets.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Não há jogadores com cartas na mão para investigar.',
                      style: TextStyle(color: Colors.white60),
                    ),
                    if (currentDeviceIsToto) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: isResolvingEffect ? null : onWithoutTarget,
                        icon: const Icon(Icons.skip_next),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Continuar'),
                        ),
                      ),
                    ],
                  ],
                )
              else if (currentDeviceIsToto)
                ...availableTargets.map((target) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onTargetSelected(target);
                            },
                      icon: const Icon(Icons.record_voice_over),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'Investigar ${target.name} (${target.hand.length} carta${target.hand.length == 1 ? '' : 's'})',
                        ),
                      ),
                    ),
                  );
                })
              else
                const Text(
                  'Aguardando o Totó escolher quem vai investigar.',
                  style: TextStyle(color: Colors.white60),
                ),
            ] else if (!cardWasRevealed) ...[
              if (currentDeviceIsToto)
                _HiddenTotoCards(
                  targetPlayer: targetPlayer,
                  isResolvingEffect: isResolvingEffect,
                  onCardSelected: onCardSelected,
                )
              else
                const Text(
                  'Aguardando o Totó revelar uma carta escondida.',
                  style: TextStyle(color: Colors.white60),
                ),
            ] else ...[
              Text(
                effect.revealedCardName!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusText({
    required Player totoPlayer,
    required Player? targetPlayer,
    required bool cardWasRevealed,
  }) {
    if (targetPlayer == null) {
      return '${totoPlayer.name} deve escolher quem o Totó vai investigar.';
    }

    if (!cardWasRevealed) {
      return '${totoPlayer.name} está investigando ${targetPlayer.name}.';
    }

    return '${totoPlayer.name} investigou ${targetPlayer.name} com Totó.';
  }
}

class _HiddenTotoCards extends StatelessWidget {
  const _HiddenTotoCards({
    required this.targetPlayer,
    required this.isResolvingEffect,
    required this.onCardSelected,
  });

  final Player targetPlayer;
  final bool isResolvingEffect;
  final ValueChanged<GameCard> onCardSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(targetPlayer.hand.length, (index) {
        final card = targetPlayer.hand[index];

        return SizedBox(
          width: 120,
          height: 96,
          child: OutlinedButton(
            onPressed: isResolvingEffect
                ? null
                : () {
                    onCardSelected(card);
                  },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.help_outline),
                const SizedBox(height: 8),
                Text(
                  'Carta ${index + 1}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _DetectivePendingEffectCard extends StatelessWidget {
  const _DetectivePendingEffectCard({
    required this.session,
    required this.currentPlayerId,
    required this.isResolvingEffect,
    required this.onTargetSelected,
    required this.onAcknowledge,
  });

  final OnlineGameSession session;
  final String currentPlayerId;
  final bool isResolvingEffect;
  final ValueChanged<Player> onTargetSelected;
  final VoidCallback onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final effect = session.pendingEffect!;
    final detectivePlayer = session.gameState.players.firstWhere(
      (player) => player.id == effect.actingPlayerId,
    );
    final targetPlayer = effect.targetPlayerId == null
        ? null
        : session.gameState.players.firstWhere(
            (player) => player.id == effect.targetPlayerId,
          );
    final currentDeviceIsDetective = currentPlayerId == detectivePlayer.id;
    final alreadyAcknowledged =
        effect.acknowledgedPlayerIds.contains(currentPlayerId);
    final expectedViewerIds = session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
    final acknowledgedCount =
        expectedViewerIds.where(effect.acknowledgedPlayerIds.contains).length;
    final availableTargets = session.gameState.players.where((player) {
      final isDetective = player.id == detectivePlayer.id;
      final hasCardsInHand = player.hand.isNotEmpty;
      final isProtected = _blockingProtectionForPlayer(
            session: session,
            player: player,
            effectType: OnlineEffectType.detective,
          ) !=
          null;

      return !isDetective && hasCardsInHand && !isProtected;
    }).toList();

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.manage_search,
                  color: Color(0xFFE7C76F),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Efeito do Detetive',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              effect.wasResolved
                  ? '${detectivePlayer.name} acusou ${targetPlayer!.name}.'
                  : '${detectivePlayer.name} deve escolher quem vai acusar.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            if (!effect.wasResolved) ...[
              if (currentDeviceIsDetective)
                ...availableTargets.map((target) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: isResolvingEffect
                          ? null
                          : () {
                              onTargetSelected(target);
                            },
                      icon: const Icon(Icons.record_voice_over),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text('Acusar ${target.name}'),
                      ),
                    ),
                  );
                })
              else
                const Text(
                  'Aguardando a acusação do Detetive.',
                  style: TextStyle(color: Colors.white60),
                ),
            ] else ...[
              Text(
                effect.resultMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$acknowledgedCount de ${expectedViewerIds.length} jogadores visualizaram.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: alreadyAcknowledged || isResolvingEffect
                    ? null
                    : onAcknowledge,
                icon: Icon(
                  alreadyAcknowledged
                      ? Icons.check_circle
                      : Icons.visibility,
                ),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    alreadyAcknowledged
                        ? 'Você já visualizou'
                        : 'Confirmar visualização',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OnlineTableCard extends StatelessWidget {
  const _OnlineTableCard({
    required this.gameState,
    required this.currentPlayer,
    required this.activeProtections,
  });

  final GameState gameState;
  final Player currentPlayer;
  final List<OnlineActiveProtection> activeProtections;

  String deckSummaryText() {
    final initialDeckSize = gameState.initialDeckSize;
    final currentDeckSize = gameState.deck.length;
    final drawnCards = gameState.drawnCardsCount;

    if (drawnCards <= 0) {
      return 'Monte de compras: $currentDeckSize carta${currentDeckSize == 1 ? '' : 's'}';
    }

    final subtractions = List.generate(drawnCards, (_) => '1').join(' - ');

    return 'Monte de compras: $initialDeckSize - $subtractions = $currentDeckSize carta${currentDeckSize == 1 ? '' : 's'}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mesa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              deckSummaryText(),
              style: const TextStyle(
                color: Color(0xFFE7C76F),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...gameState.players.map((tablePlayer) {
              final isCurrent = tablePlayer.id == currentPlayer.id;
              final playerProtections = activeProtections.where((protection) {
                return protection.playerId == tablePlayer.id;
              }).toList();

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCurrent ? Icons.play_arrow : Icons.person,
                          size: 18,
                          color: isCurrent
                              ? const Color(0xFFE7C76F)
                              : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            tablePlayer.name,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${tablePlayer.hand.length} carta${tablePlayer.hand.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    if (tablePlayer.hasHandcuffs) ...[
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(
                            Icons.link,
                            size: 18,
                            color: Color(0xFFE7C76F),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Algemas',
                            style: TextStyle(
                              color: Color(0xFFE7C76F),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (playerProtections.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF120818),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFE7C76F),
                          ),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.shield,
                                  size: 18,
                                  color: Color(0xFFE7C76F),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Proteções ativas',
                                  style: TextStyle(
                                    color: Color(0xFFE7C76F),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...playerProtections.map((protection) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      protection.cardName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      protection.description,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (tablePlayer.playedCards.isEmpty)
                      const Text(
                        'Nenhuma carta à frente.',
                        style: TextStyle(
                          color: Colors.white54,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tablePlayer.playedCards.map((card) {
                          return Chip(
                            label: Text(card.name),
                            backgroundColor: const Color(0xFF120818),
                            side: const BorderSide(
                              color: Color(0xFFE7C76F),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

