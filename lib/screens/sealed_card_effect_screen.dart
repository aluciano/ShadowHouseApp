import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class SealedCardEffectScreen extends StatefulWidget {
  const SealedCardEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<SealedCardEffectScreen> createState() => _SealedCardEffectScreenState();
}

class _SealedCardEffectScreenState extends State<SealedCardEffectScreen> {
  Player? selectedTarget;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.actingPlayerId,
    );
    final targets = widget.gameState.players.where((player) {
      return player.id != widget.actingPlayerId && player.hand.isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver A Carta Selada'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'A Carta Selada',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha um jogador. Uma carta aleatória da mão dele será selada sem ser revelada.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (targets.isEmpty)
                _SealedActionCard(
                  text: 'Não há outros jogadores com cartas na mão para selar.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    widget.gameState.moveToNextPlayer();
                    _continueAfterEffect(context);
                  },
                )
              else if (selectedTarget == null)
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
                                sealRandomCardFromHand(
                                  gameState: widget.gameState,
                                  targetPlayer: target,
                                );

                                setState(() {
                                  selectedTarget = target;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  '${target.name} — ${target.hand.length} carta${target.hand.length == 1 ? '' : 's'} na mão',
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                )
              else
                _SealedActionCard(
                  text: widget.gameState.roundFinished
                      ? widget.gameState.roundResult?.reason ??
                          '${selectedTarget!.name} teve uma carta selada.'
                      : '${selectedTarget!.name} teve uma carta da mão colocada virada para baixo à frente dele.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    _continueAfterEffect(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueAfterEffect(BuildContext context) {
    if (widget.gameState.roundFinished) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoundResultScreen(gameState: widget.gameState),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(gameState: widget.gameState),
      ),
      (route) => route.isFirst,
    );
  }
}

class _SealedActionCard extends StatelessWidget {
  const _SealedActionCard({
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
