import 'package:flutter/material.dart';

import '../models/game_state.dart';
import '../widgets/shadow_background.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.gameState,
    this.showHands = false,
    this.title = 'Mesa',
  });

  final GameState gameState;
  final bool showHands;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
              Text(
                showHands
                    ? 'Confira as cartas jogadas à frente e as cartas que ainda estavam na mão ao final da rodada.'
                    : 'Veja as cartas já jogadas à frente de cada jogador.',
                style: const TextStyle(
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
                                  '${player.hand.length} carta${player.hand.length == 1 ? '' : 's'} na mão',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                  ),
                                ),
                                Builder(
                                  builder: (context) {
                                    final roundPoints =
                                        gameState.roundResult?.roundPointsByPlayerId[player.id] ?? 0;

                                    final previousScore = player.score - roundPoints;

                                    final scoreText = showHands && gameState.roundResult != null
                                        ? '$previousScore + $roundPoints = ${player.score} ponto${player.score == 1 ? '' : 's'}'
                                        : '${player.score} ponto${player.score == 1 ? '' : 's'}';

                                    return Text(
                                      scoreText,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Cartas à frente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                                avatar: const Icon(
                                  Icons.visibility,
                                  size: 16,
                                  color: Color(0xFFE7C76F),
                                ),
                                label: Text(card.name),
                                backgroundColor: const Color(0xFF120818),
                                side: const BorderSide(
                                  color: Color(0xFFE7C76F),
                                ),
                              );
                            }).toList(),
                          ),
                        if (showHands) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Cartas que estavam na mão',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (player.hand.isEmpty)
                            const Text(
                              'Nenhuma carta restante na mão.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: player.hand.map((card) {
                                return Chip(
                                  avatar: const Icon(
                                    Icons.back_hand,
                                    size: 16,
                                    color: Colors.white70,
                                  ),
                                  label: Text(card.name),
                                  backgroundColor: const Color(0xFF2B2B35),
                                  side: const BorderSide(
                                    color: Colors.white38,
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
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