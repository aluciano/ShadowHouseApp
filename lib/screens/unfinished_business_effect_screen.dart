import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class UnfinishedBusinessEffectScreen extends StatelessWidget {
  const UnfinishedBusinessEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = gameState.players.firstWhere(
      (player) => player.id == actingPlayerId,
    );
    final targets = gameState.players
        .where((player) => player.id != actingPlayerId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Assunto Inacabado'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Assunto Inacabado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha um jogador para comprar 1 carta do monte.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (targets.isEmpty)
                _ActionCard(
                  text: 'Não há outros jogadores para escolher.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    gameState.moveToNextPlayer();
                    _continueAfterEffect(context);
                  },
                )
              else if (gameState.deck.isEmpty)
                _ActionCard(
                  text: 'O monte está vazio. Ninguém compra carta.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    gameState.moveToNextPlayer();
                    _continueAfterEffect(context);
                  },
                )
              else
                Card(
                  color: const Color(0xFF221229),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Escolha o jogador alvo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...targets.map((target) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              onPressed: () {
                                final drewCard = resolveUnfinishedBusinessEffect(
                                  gameState: gameState,
                                  targetPlayer: target,
                                );

                                showDialog<void>(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Assunto Inacabado'),
                                      content: Text(
                                        drewCard
                                            ? '${target.name} comprou 1 carta do monte.'
                                            : 'O monte estava vazio. ${target.name} não comprou carta.',
                                      ),
                                      actions: [
                                        FilledButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                            _continueAfterEffect(context);
                                          },
                                          child: const Text('Continuar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(target.name),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueAfterEffect(BuildContext context) {
    if (gameState.roundFinished) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoundResultScreen(gameState: gameState),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(gameState: gameState),
      ),
      (route) => route.isFirst,
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
