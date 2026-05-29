import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../widgets/shadow_background.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesa'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Estado da Mesa',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veja as cartas já jogadas à frente de cada jogador.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ...gameState.players.map((player) {
                final isCurrentPlayer = player.id == gameState.currentPlayer.id;

                return Card(
                  color: isCurrentPlayer
                      ? const Color(0xFF3A1A4A)
                      : const Color(0xFF221229),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isCurrentPlayer
                          ? const Color(0xFFE7C76F)
                          : Colors.white12,
                      width: isCurrentPlayer ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCurrentPlayer
                                  ? Icons.play_arrow
                                  : Icons.person,
                              color: isCurrentPlayer
                                  ? const Color(0xFFE7C76F)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${player.hand.length} na mão',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '${player.score} ponto${player.score == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (player.playedCards.isEmpty)
                          const Text(
                            'Nenhuma carta à frente.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: player.playedCards.map((card) {
                              return Chip(
                                label: Text(card.name),
                                backgroundColor: const Color(0xFF120818),
                                side: const BorderSide(
                                  color: Color(0xFFE7C76F),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
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