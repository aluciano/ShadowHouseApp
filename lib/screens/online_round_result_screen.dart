import 'package:flutter/material.dart';

import '../models/online_game_session.dart';
import '../models/player.dart';
import '../models/round_result_type.dart';
import '../repositories/online_game_session_factory.dart';
import '../repositories/repository_registry.dart';
import '../widgets/shadow_background.dart';
import '../widgets/shadow_scrollable_content.dart';
import 'match_history_screen.dart';
import 'online_game_screen.dart';
import 'table_screen.dart';

class OnlineRoundResultScreen extends StatefulWidget {
  const OnlineRoundResultScreen({
    super.key,
    required this.session,
    required this.currentPlayerId,
  });

  final OnlineGameSession session;
  final String currentPlayerId;

  @override
  State<OnlineRoundResultScreen> createState() =>
      _OnlineRoundResultScreenState();
}

class _OnlineRoundResultScreenState extends State<OnlineRoundResultScreen> {
  bool isStartingNextRound = false;
  bool isStartingRematch = false;
  bool isOpeningStartedRound = false;

  OnlineGameSession get session => widget.session;

  Future<void> confirmReadyForNextRound(
    OnlineGameSession session,
    String playerId,
  ) async {
    final readyPlayerIds = {
      ...session.nextRoundReadyPlayerIds,
      playerId,
    }.toList();

    await RepositoryRegistry.onlineGame.saveCurrentSession(
      session.copyWith(nextRoundReadyPlayerIds: readyPlayerIds),
    );
  }

  Future<void> startNextRound(OnlineGameSession session) async {
    setState(() {
      isStartingNextRound = true;
    });

    final nextSession = createNextOnlineRoundSession(session);

    await RepositoryRegistry.onlineGame.saveCurrentSession(nextSession);

    if (!mounted) {
      return;
    }

    openGame(nextSession);
  }

  Future<void> proposeRematch(
    OnlineGameSession session,
    String playerId,
  ) async {
    final proposals = {
      ...session.rematchProposalPlayerIds,
      playerId,
    }.toList();

    await RepositoryRegistry.onlineGame.saveCurrentSession(
      session.copyWith(rematchProposalPlayerIds: proposals),
    );
  }

  Future<void> startRematch(OnlineGameSession session) async {
    setState(() {
      isStartingRematch = true;
    });

    final nextSession = await RepositoryRegistry.onlineGame
        .startNewMatchInSameRoom(session.room);

    if (!mounted) {
      return;
    }

    openGame(nextSession);
  }

  void openGame(OnlineGameSession nextSession) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          session: nextSession,
          currentPlayerId: widget.currentPlayerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OnlineGameSession>(
      stream: RepositoryRegistry.onlineGame.watchCurrentSession(session.room),
      initialData: session,
      builder: (context, snapshot) {
        final visibleSession = snapshot.data ?? session;
        final expectedPlayerIds = _expectedPlayerIds(visibleSession);
        final currentDeviceIsHost =
            widget.currentPlayerId == visibleSession.room.hostPlayerId;
        final matchFinished = _isMatchFinished(visibleSession);
        final proposalsAreComplete = expectedPlayerIds.every(
          visibleSession.rematchProposalPlayerIds.contains,
        );
        final readyForNextRoundIsComplete = expectedPlayerIds.every(
          visibleSession.nextRoundReadyPlayerIds.contains,
        );

        if (!visibleSession.gameState.roundFinished && !isOpeningStartedRound) {
          isOpeningStartedRound = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              openGame(visibleSession);
            }
          });
        } else if (visibleSession.gameState.roundFinished &&
            matchFinished &&
            proposalsAreComplete &&
            currentDeviceIsHost &&
            !isStartingRematch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              startRematch(visibleSession);
            }
          });
        } else if (visibleSession.gameState.roundFinished &&
            !matchFinished &&
            readyForNextRoundIsComplete &&
            currentDeviceIsHost &&
            !isStartingNextRound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              startNextRound(visibleSession);
            }
          });
        }

        return buildContent(context, visibleSession);
      },
    );
  }

  Widget buildContent(BuildContext context, OnlineGameSession session) {
    final gameState = session.gameState;
    final result = gameState.roundResult;
    final highestScore = gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);
    final isMatchFinished = highestScore >= 5;
    final winners = gameState.players
        .where((player) => player.score == highestScore)
        .toList();
    final expectedPlayerIds = _expectedPlayerIds(session);
    final currentPlayer = gameState.players.firstWhere(
      (player) => player.id == widget.currentPlayerId,
      orElse: () => gameState.players.first,
    );
    final currentPlayerProposed =
        session.rematchProposalPlayerIds.contains(currentPlayer.id);
    final currentPlayerIsReadyForNextRound =
        session.nextRoundReadyPlayerIds.contains(currentPlayer.id);
    final rematchProposalCount = expectedPlayerIds
        .where(session.rematchProposalPlayerIds.contains)
        .length;
    final readyForNextRoundCount = expectedPlayerIds
        .where(session.nextRoundReadyPlayerIds.contains)
        .length;

    return Scaffold(
      body: ShadowBackground(
        child: ShadowScrollableContent(
          child: Card(
            color: const Color(0xFF221229),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 72,
                    color: Color(0xFFE7C76F),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isMatchFinished
                        ? 'Fim da Partida Online'
                        : 'Fim da Rodada Online',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sala ${session.room.code}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    result == null
                        ? 'A rodada terminou.'
                        : _titleForResult(result.type),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFFE7C76F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      result.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pontuação da rodada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.scoringSummary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Placar atual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gameState.players.map((player) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${player.name}: ${player.score} ponto${player.score == 1 ? '' : 's'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: player.score == highestScore
                              ? const Color(0xFFE7C76F)
                              : Colors.white70,
                          fontWeight: player.score == highestScore
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    isMatchFinished ? 'Vencedor' : 'Liderança',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winners.map((player) => player.name).join(', '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TableScreen(
                              gameState: gameState,
                              showHands: true,
                              title: 'Mesa Final',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_bar),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Ver Mesa Final',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isMatchFinished)
                    _RematchCard(
                      currentPlayer: currentPlayer,
                      proposalCount: rematchProposalCount,
                      expectedCount: expectedPlayerIds.length,
                      currentPlayerProposed: currentPlayerProposed,
                      isStartingRematch: isStartingRematch,
                      onPropose: () {
                        proposeRematch(session, currentPlayer.id);
                      },
                    )
                  else
                    _NextRoundReadyCard(
                      readyCount: readyForNextRoundCount,
                      expectedCount: expectedPlayerIds.length,
                      currentPlayerIsReady: currentPlayerIsReadyForNextRound,
                      isStartingNextRound: isStartingNextRound,
                      onConfirmReady: () {
                        confirmReadyForNextRound(session, currentPlayer.id);
                      },
                    ),
                  const SizedBox(height: 12),
                  if (isMatchFinished)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MatchHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver Histórico',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(Icons.home),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Voltar ao Menu Inicial',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _titleForResult(RoundResultType type) {
    switch (type) {
      case RoundResultType.guiltyWins:
        return 'O Culpado venceu a rodada!';
      case RoundResultType.detectiveWins:
        return 'O Detetive venceu a rodada!';
      case RoundResultType.totoWins:
        return 'Totó venceu a rodada!';
      case RoundResultType.handcuffsWins:
        return 'As Algemas venceram!';
    }
  }

  List<String> _expectedPlayerIds(OnlineGameSession session) {
    return session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
  }

  bool _isMatchFinished(OnlineGameSession session) {
    final highestScore = session.gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);

    return highestScore >= 5;
  }
}

class _NextRoundReadyCard extends StatelessWidget {
  const _NextRoundReadyCard({
    required this.readyCount,
    required this.expectedCount,
    required this.currentPlayerIsReady,
    required this.isStartingNextRound,
    required this.onConfirmReady,
  });

  final int readyCount;
  final int expectedCount;
  final bool currentPlayerIsReady;
  final bool isStartingNextRound;
  final VoidCallback onConfirmReady;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Próxima rodada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$readyCount de $expectedCount jogadores estão prontos.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: currentPlayerIsReady || isStartingNextRound
                  ? null
                  : onConfirmReady,
              icon: Icon(
                currentPlayerIsReady ? Icons.check_circle : Icons.visibility,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  currentPlayerIsReady
                      ? 'Você está pronto'
                      : 'Estou pronto para a próxima rodada',
                ),
              ),
            ),
            if (isStartingNextRound) ...[
              const SizedBox(height: 12),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'A próxima rodada começa quando todos estiverem prontos.',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RematchCard extends StatelessWidget {
  const _RematchCard({
    required this.currentPlayer,
    required this.proposalCount,
    required this.expectedCount,
    required this.currentPlayerProposed,
    required this.isStartingRematch,
    required this.onPropose,
  });

  final Player currentPlayer;
  final int proposalCount;
  final int expectedCount;
  final bool currentPlayerProposed;
  final bool isStartingRematch;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nova partida na mesma sala',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quando todos aceitarem, uma nova partida com os mesmos jogadores será iniciada.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              '$proposalCount de $expectedCount jogadores aceitaram.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  currentPlayerProposed || isStartingRematch ? null : onPropose,
              icon: Icon(
                currentPlayerProposed ? Icons.check_circle : Icons.how_to_vote,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  currentPlayerProposed
                      ? '${currentPlayer.name} aceitou'
                      : '${currentPlayer.name} propor nova partida',
                ),
              ),
            ),
            if (isStartingRematch) ...[
              const SizedBox(height: 8),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
