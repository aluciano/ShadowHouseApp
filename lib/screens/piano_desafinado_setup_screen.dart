import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class PianoDesafinadoSetupScreen extends StatelessWidget {
  const PianoDesafinadoSetupScreen({
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver O Piano Desafinado'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'O Piano Desafinado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha quem terá a próxima vez sabotada pelo piano.',
                style: const TextStyle(color: Colors.white70),
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
                        'Escolha o alvo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...gameState.players.map((target) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton(
                            onPressed: () {
                              schedulePianoEffect(
                                gameState: gameState,
                                actingPlayer: actingPlayer,
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
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
