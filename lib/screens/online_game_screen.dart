import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import '../models/online_game_session.dart';
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
    if (isSavingMove) {
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

      playCard(
        gameState: gameState,
        card: card,
      );

      if (!gameState.roundFinished &&
          gameState.currentPlayer.id == previousPlayerId) {
        gameState.moveToNextPlayer();
      }

      await RepositoryRegistry.onlineGame.saveCurrentSession(
        session.copyWith(gameState: gameState),
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
      'cumplice',
      'taca_envenenada',
      'detetive',
      'toto',
      'xerife',
      'chave_enferrujada',
      'bebe_da_familia',
      'testemunha',
      'trocar',
      'compartilhar',
      'rumores',
    }.contains(card.templateId);
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

              if (gameState.roundFinished) {
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
                    'Vez de ${currentPlayer.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFFE7C76F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    color: const Color(0xFF221229),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sua mão',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE7C76F),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isCurrentPlayer
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
                                    isCurrentPlayer && !isSavingMove
                                        ? Icons.play_arrow
                                        : Icons.lock,
                                  ),
                                  onTap: isCurrentPlayer && !isSavingMove
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
                  Card(
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
                          const SizedBox(height: 12),
                          ...gameState.players.map((tablePlayer) {
                            final isCurrent =
                                tablePlayer.id == currentPlayer.id;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        isCurrent
                                            ? Icons.play_arrow
                                            : Icons.person,
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
                                      children:
                                          tablePlayer.playedCards.map((card) {
                                        return Chip(
                                          label: Text(card.name),
                                          backgroundColor:
                                              const Color(0xFF120818),
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
