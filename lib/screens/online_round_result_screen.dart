import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/online_game_session.dart';
import '../models/round_result_type.dart';
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
  });

  final OnlineGameSession session;

  @override
  State<OnlineRoundResultScreen> createState() =>
      _OnlineRoundResultScreenState();
}

class _OnlineRoundResultScreenState extends State<OnlineRoundResultScreen> {
  final Set<String> rematchProposalPlayerIds = {};
  bool isStartingRematch = false;

  OnlineGameSession get session => widget.session;

  Future<void> proposeRematch(String playerId) async {
    setState(() {
      rematchProposalPlayerIds.add(playerId);
    });

    if (rematchProposalPlayerIds.length != session.gameState.players.length) {
      return;
    }

    setState(() {
      isStartingRematch = true;
    });

    final nextSession = await RepositoryRegistry.onlineGame
        .startNewMatchInSameRoom(session.room);

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          session: nextSession,
          initialViewedPlayerId: nextSession.gameState.currentPlayer.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = session.gameState;
    final result = gameState.roundResult;
    final highestScore = gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);
    final isMatchFinished = highestScore >= 5;
    final winners = gameState.players
        .where((player) => player.score == highestScore)
        .toList();

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
                  if (isMatchFinished) ...[
                    const SizedBox(height: 24),
                    Card(
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
                            ...gameState.players.map((player) {
                              final proposed = rematchProposalPlayerIds
                                  .contains(player.id);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: OutlinedButton.icon(
                                  onPressed: proposed || isStartingRematch
                                      ? null
                                      : () => proposeRematch(player.id),
                                  icon: Icon(
                                    proposed
                                        ? Icons.check_circle
                                        : Icons.how_to_vote,
                                  ),
                                  label: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Text(
                                      proposed
                                          ? '${player.name} aceitou'
                                          : '${player.name} propor nova partida',
                                    ),
                                  ),
                                ),
                              );
                            }),
                            if (isStartingRematch) ...[
                              const SizedBox(height: 8),
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
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
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: isMatchFinished
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const MatchHistoryScreen(),
                                ),
                              );
                            }
                          : () {
                              final nextRoundState = createNextRoundGameState(
                                gameState,
                              );
                              final nextSession = OnlineGameSession(
                                room: session.room,
                                gameState: nextRoundState,
                                startedAt: session.startedAt,
                                roundsPlayed: session.roundsPlayed + 1,
                              );

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => OnlineGameScreen(
                                    session: nextSession,
                                    initialViewedPlayerId:
                                        nextRoundState.currentPlayer.id,
                                  ),
                                ),
                              );
                            },
                      icon: Icon(
                        isMatchFinished ? Icons.history : Icons.skip_next,
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          isMatchFinished ? 'Ver Histórico' : 'Próxima Rodada',
                          style: const TextStyle(fontSize: 18),
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
}
