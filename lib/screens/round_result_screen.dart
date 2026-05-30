import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/round_result_type.dart';
import '../widgets/shadow_background.dart';
import '../widgets/shadow_scrollable_content.dart';
import 'pass_device_screen.dart';
import 'setup_screen.dart';
import 'table_screen.dart';

class RoundResultScreen extends StatelessWidget {
  const RoundResultScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final result = gameState.roundResult;

    final highestScore = gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);

    final isGameFinished = highestScore >= 5;

    final gameWinners = isGameFinished
        ? gameState.players
        .where((player) => player.score == highestScore)
        .toList()
        : [];

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
                  Icon(
                    isGameFinished ? Icons.workspace_premium : Icons.emoji_events,
                    size: 72,
                    color: const Color(0xFFE7C76F),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isGameFinished ? 'Fim da Partida' : 'Fim da Rodada',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
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
                    'Placar total',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gameState.players.map((player) {
                    final roundPoints =
                        gameState.roundResult?.roundPointsByPlayerId[player.id] ?? 0;

                    final previousScore = player.score - roundPoints;

                    final scoreText = roundPoints > 0
                        ? '${player.name}: $previousScore + $roundPoints = ${player.score} ponto${player.score == 1 ? '' : 's'}'
                        : '${player.name}: $previousScore + 0 = ${player.score} ponto${player.score == 1 ? '' : 's'}';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        scoreText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: isGameFinished && player.score == highestScore
                              ? const Color(0xFFE7C76F)
                              : Colors.white70,
                          fontWeight: isGameFinished && player.score == highestScore
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  if (isGameFinished) ...[
                    const SizedBox(height: 24),
                    Text(
                      gameWinners.length == 1
                          ? 'Vencedor da partida'
                          : 'Vencedores da partida',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      gameWinners.map((player) => player.name).join(', '),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
                  if (isGameFinished)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const SetupScreen(),
                            ),
                                (route) => route.isFirst,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Nova Partida',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final nextRoundState =
                          createNextRoundGameState(gameState);

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => PassDeviceScreen(
                                gameState: nextRoundState,
                              ),
                            ),
                                (route) => route.isFirst,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Próxima Rodada',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).popUntil(
                              (route) => route.isFirst,
                        );
                      },
                      child: const Padding(
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