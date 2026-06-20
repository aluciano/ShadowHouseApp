import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class BetrayalEffectScreen extends StatelessWidget {
  const BetrayalEffectScreen({
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
    final targets = gameState.players.where((player) {
      return player.playedCards.any((card) => card.templateId == 'cumplice');
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Traição no Salão'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Traição no Salão',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha um jogador com Cúmplice à frente para cancelar esse efeito até o fim da rodada.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (targets.isEmpty)
                Card(
                  color: const Color(0xFF221229),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Não há jogador com Cúmplice à frente neste momento.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              gameState.moveToNextPlayer();
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PassDeviceScreen(gameState: gameState),
                                ),
                                (route) => route.isFirst,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Continuar'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...targets.map((target) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        resolveBetrayalEffect(
                          gameState: gameState,
                          targetPlayer: target,
                        );

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) =>
                                PassDeviceScreen(gameState: gameState),
                          ),
                          (route) => route.isFirst,
                        );
                      },
                      icon: const Icon(Icons.heart_broken),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(target.name),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}
