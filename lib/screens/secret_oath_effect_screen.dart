import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class SecretOathEffectScreen extends StatelessWidget {
  const SecretOathEffectScreen({
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
        title: const Text('Resolver O Juramento Secreto'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'O Juramento Secreto',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha outro jogador para formar o vínculo até o fim da rodada.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              ...targets.map((target) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      resolveSecretOathEffect(
                        gameState: gameState,
                        actingPlayer: actingPlayer,
                        targetPlayer: target,
                      );

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => PassDeviceScreen(gameState: gameState),
                        ),
                        (route) => route.isFirst,
                      );
                    },
                    icon: const Icon(Icons.handshake),
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
