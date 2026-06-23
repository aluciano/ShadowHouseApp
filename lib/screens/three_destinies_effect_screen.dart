import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'played_card_effect_router.dart';

class ThreeDestiniesEffectScreen extends StatefulWidget {
  const ThreeDestiniesEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<ThreeDestiniesEffectScreen> createState() =>
      _ThreeDestiniesEffectScreenState();
}

class _ThreeDestiniesEffectScreenState extends State<ThreeDestiniesEffectScreen> {
  late final List<GameCard> offeredCards;

  @override
  void initState() {
    super.initState();
    offeredCards = drawCardsFromDeck(
      gameState: widget.gameState,
      count: 3,
    );
  }

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.actingPlayerId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Três Destinos'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Três Destinos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha uma das cartas compradas do monte para baixar e resolver. As demais serão baixadas sem efeito.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (offeredCards.isEmpty)
                _ThreeDestiniesActionCard(
                  text: 'Não havia cartas disponíveis no monte.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    widget.gameState.moveToNextPlayer();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => PassDeviceScreen(
                          gameState: widget.gameState,
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                )
              else
                Card(
                  color: const Color(0xFF221229),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Escolha a carta que será resolvida',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...offeredCards.map((card) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              onPressed: () {
                                final currentPlayer = widget.gameState.players
                                    .firstWhere(
                                  (player) => player.id == widget.actingPlayerId,
                                );
                                final discardedCards = offeredCards
                                    .where((item) => item.id != card.id)
                                    .toList();

                                placeCardsAsNoEffect(
                                  player: currentPlayer,
                                  cards: discardedCards,
                                );
                                playExternalCard(
                                  gameState: widget.gameState,
                                  card: card,
                                );

                                continueAfterPlayedCard(
                                  context: context,
                                  gameState: widget.gameState,
                                  actingPlayerId: widget.actingPlayerId,
                                  card: card,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      card.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(card.shortText),
                                  ],
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

class _ThreeDestiniesActionCard extends StatelessWidget {
  const _ThreeDestiniesActionCard({
    required this.text,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String text;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
