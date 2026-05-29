import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'table_screen.dart';
import 'round_result_screen.dart';

class HandScreen extends StatelessWidget {
  const HandScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mão de ${currentPlayer.name}'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                currentPlayer.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha uma carta para jogar.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
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
                label: const Text('Ver Mesa'),
              ),
              const SizedBox(height: 24),
              ...currentPlayer.hand.map((card) {
                return Card(
                  color: const Color(0xFF221229),
                  child: ListTile(
                    title: Text(
                      card.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(card.shortText),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final isFirstTurnOfRound = gameState.players.every(
                            (player) => player.playedCards.isEmpty,
                      );

                      final isFirstSceneCard = card.templateId == 'primeiro_na_cena';

                      if (isFirstTurnOfRound && !isFirstSceneCard) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A primeira carta da rodada deve ser Primeiro na Cena.'),
                          ),
                        );

                        return;
                      }

                      final isGuiltyCard = card.templateId == 'culpado';
                      final isLastCardInHand = currentPlayer.hand.length == 1;

                      if (isGuiltyCard && !isLastCardInHand) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Você só pode jogar o Culpado se ele for a última carta da sua mão.'),
                          ),
                        );

                        return;
                      }

                      final shouldPlay = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(card.name),
                            content: Text(
                              '${card.shortText}\n\nDeseja jogar esta carta?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                },
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                },
                                child: const Text('Jogar'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldPlay != true) {
                        return;
                      }

                      playCard(
                        gameState: gameState,
                        card: card,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      if (gameState.roundFinished) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => RoundResultScreen(
                              gameState: gameState,
                            ),
                          ),
                              (route) => route.isFirst,
                        );

                        return;
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => PassDeviceScreen(
                            gameState: gameState,
                          ),
                        ),
                            (route) => route.isFirst,
                      );
                    },
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