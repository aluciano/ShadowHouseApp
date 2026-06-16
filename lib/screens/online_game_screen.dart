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
      final hasPendingResolution =
          isDetectiveCard ||
          isTotoCard ||
          isHandcuffsCard ||
          isAccompliceCard ||
          isPoisonedCupCard;

      playCard(
        gameState: gameState,
        card: card,
      );

      if (!gameState.roundFinished &&
          !hasPendingResolution &&
          gameState.currentPlayer.id == previousPlayerId) {
        gameState.moveToNextPlayer();
      }

      final pendingEffect = _pendingEffectForCard(
        card: card,
        actingPlayerId: player.id,
      );

      await RepositoryRegistry.onlineGame.saveCurrentSession(
        session.copyWith(
          gameState: gameState,
          pendingEffect: pendingEffect,
        ),
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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
      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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
      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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

      await RepositoryRegistry.onlineGame.saveCurrentSession(
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
      await RepositoryRegistry.onlineGame.saveCurrentSession(
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
      'bebe_da_familia',
      'testemunha',
      'trocar',
      'compartilhar',
      'rumores',
    }.contains(card.templateId);
  }

  Player _playerById(GameState gameState, String playerId) {
    return gameState.players.firstWhere((player) => player.id == playerId);
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
    }
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

      if (!hasCardsInHand) {
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

      return !isTotoPlayer && hasCardsInHand;
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

      return !isDetective && hasCardsInHand;
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
  });

  final GameState gameState;
  final Player currentPlayer;

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
