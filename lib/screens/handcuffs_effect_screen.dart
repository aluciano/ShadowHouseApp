import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class HandcuffsEffectScreen extends StatelessWidget {
  const HandcuffsEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
    required this.effectTitle,
    required this.instructionText,
    required this.allowSelfTarget,
  });

  final GameState gameState;
  final String actingPlayerId;
  final String effectTitle;
  final String instructionText;
  final bool allowSelfTarget;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = gameState.players.firstWhere(
          (player) => player.id == actingPlayerId,
    );

    final availableTargets = gameState.players.where((player) {
      final isActingPlayer = player.id == actingPlayerId;
      final hasCardsInHand = player.hand.isNotEmpty;

      if (!hasCardsInHand) {
        return false;
      }

      if (!allowSelfTarget && isActingPlayer) {
        return false;
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(effectTitle),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                effectTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}: $instructionText',
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
                        final alreadyHasHandcuffs = target.hasHandcuffs;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: OutlinedButton.icon(
                            onPressed: () {
                              resolveHandcuffsEffect(
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
                            icon: Icon(
                              alreadyHasHandcuffs ? Icons.link_off : Icons.link,
                            ),
                            label: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                alreadyHasHandcuffs
                                    ? '${target.name} — já está com algemas'
                                    : '${target.name} — ${target.hand.length} carta${target.hand.length == 1 ? '' : 's'} na mão',
                              ),
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