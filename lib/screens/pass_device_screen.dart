import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'hand_screen.dart';
import 'table_screen.dart';

class PassDeviceScreen extends StatelessWidget {
  const PassDeviceScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.currentPlayer;

    return Scaffold(
      body: ShadowBackground(
        child: SafeArea(
          child: Center(
            child: Card(
              color: const Color(0xFF221229),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 64,
                      color: Color(0xFFE7C76F),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Passe o celular para',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPlayer.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      gameState.ghostCopies > 0
                          ? '${gameState.initialCards} cartas iniciais • ${gameState.ghostCopies} Fantasmas'
                          : '${gameState.initialCards} cartas iniciais',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cartas na mão: ${currentPlayer.hand.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      'Cartas à frente: ${currentPlayer.playedCards.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HandScreen(
                                gameState: gameState,
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver minha mão',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TableScreen(
                                gameState: gameState,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_bar),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver Mesa',
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
    );
  }
}