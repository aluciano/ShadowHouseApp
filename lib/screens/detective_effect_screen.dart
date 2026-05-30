import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class DetectiveEffectScreen extends StatefulWidget {
  const DetectiveEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<DetectiveEffectScreen> createState() => _DetectiveEffectScreenState();
}

class _DetectiveEffectScreenState extends State<DetectiveEffectScreen> {
  String? resultMessage;

  @override
  Widget build(BuildContext context) {
    final detectivePlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    final availableTargets = widget.gameState.players.where((player) {
      final isDetective = player.id == widget.actingPlayerId;
      return !isDetective;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Detetive'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Efeito do Detetive',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${detectivePlayer.name} deve escolher outro jogador e perguntar: “Você é o culpado?”',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              if (resultMessage == null)
                _DetectiveTargetSelectionCard(
                  targets: availableTargets,
                  onTargetSelected: (target) {
                    final message = resolveDetectiveEffect(
                      gameState: widget.gameState,
                      detectivePlayer: detectivePlayer,
                      targetPlayer: target,
                    );

                    if (widget.gameState.roundFinished) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => RoundResultScreen(
                            gameState: widget.gameState,
                          ),
                        ),
                            (route) => route.isFirst,
                      );

                      return;
                    }

                    setState(() {
                      resultMessage = message;
                    });
                  },
                )
              else
                _DetectiveResultCard(
                  message: resultMessage!,
                  onContinue: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => PassDeviceScreen(
                          gameState: widget.gameState,
                        ),
                      ),
                          (route) => route.isFirst,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetectiveTargetSelectionCard extends StatelessWidget {
  const _DetectiveTargetSelectionCard({
    required this.targets,
    required this.onTargetSelected,
  });

  final List<Player> targets;
  final ValueChanged<Player> onTargetSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Escolha o jogador questionado',
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
                    onTargetSelected(target);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(target.name),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DetectiveResultCard extends StatelessWidget {
  const _DetectiveResultCard({
    required this.message,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.record_voice_over,
              size: 56,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Continuar',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}