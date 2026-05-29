import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../models/round_result_type.dart';
import '../widgets/shadow_background.dart';

class RoundResultScreen extends StatelessWidget {
  const RoundResultScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final result = gameState.roundResult;

    return Scaffold(
      body: ShadowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Center(
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
                        const Text(
                          'Fim da Rodada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${player.name}: ${player.score} ponto${player.score == 1 ? '' : 's'}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          );
                        }),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              Navigator.of(context).popUntil(
                                    (route) => route.isFirst,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              child: Text(
                                'Voltar ao início',
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
          ),
        ),
      ),
    );
  }

  String _titleForResult(RoundResultType type) {
    switch (type) {
      case RoundResultType.guiltyWins:
        return 'O Culpado venceu!';
      case RoundResultType.detectiveWins:
        return 'O Detetive venceu!';
      case RoundResultType.totoWins:
        return 'Totó venceu!';
      case RoundResultType.handcuffsWins:
        return 'As algemas revelaram o Culpado!';
    }
  }
}