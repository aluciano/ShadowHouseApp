import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class LullabyEffectScreen extends StatefulWidget {
  const LullabyEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<LullabyEffectScreen> createState() => _LullabyEffectScreenState();
}

class _LullabyEffectScreenState extends State<LullabyEffectScreen> {
  bool revealed = false;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.actingPlayerId,
    );
    final hints = resolveLullabyEffect(gameState: widget.gameState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver A Canção de Ninar'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: Center(
            child: Card(
              color: const Color(0xFF221229),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: !revealed
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.nightlight_round,
                            size: 72,
                            color: Color(0xFFE7C76F),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'A Canção de Ninar',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE7C76F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Somente ${actingPlayer.name} deve olhar esta tela.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'O app vai revelar, em segredo, quem está com Detetive ou Totó.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                setState(() {
                                  revealed = true;
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text('Revelar informação'),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.visibility,
                            size: 72,
                            color: Color(0xFFE7C76F),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Informação secreta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE7C76F),
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (hints.isEmpty)
                            const Text(
                              'Ninguém está com Detetive ou Totó neste momento.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70),
                            )
                          else
                            ...hints.map((hint) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  hint,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              );
                            }),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                finishLullabyEffect(gameState: widget.gameState);
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                    builder: (_) => PassDeviceScreen(
                                      gameState: widget.gameState,
                                    ),
                                  ),
                                  (route) => route.isFirst,
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14),
                                child: Text('Continuar'),
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
    );
  }
}
