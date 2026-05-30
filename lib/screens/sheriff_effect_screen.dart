import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class SheriffEffectScreen extends StatelessWidget {
  const SheriffEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  Widget build(BuildContext context) {
    final sheriffPlayer = gameState.players.firstWhere(
          (player) => player.id == actingPlayerId,
    );

    final availableTargets = gameState.players.where((player) {
      return player.id != actingPlayerId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Xerife'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Efeito do Xerife',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${sheriffPlayer.name} deve escolher outro jogador para receber as algemas.',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Escolha quem receberá as algemas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...availableTargets.map((target) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              resolveSheriffEffect(
                                gameState: gameState,
                                targetPlayer: target,
                              );

                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => PassDeviceScreen(
                                    gameState: gameState,
                                  ),
                                ),
                                    (route) => route.isFirst,
                              );
                            },
                            icon: const Icon(Icons.lock),
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
            ],
          ),
        ),
      ),
    );
  }
}