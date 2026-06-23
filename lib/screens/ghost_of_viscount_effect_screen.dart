import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'played_card_effect_router.dart';

class GhostOfViscountEffectScreen extends StatefulWidget {
  const GhostOfViscountEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<GhostOfViscountEffectScreen> createState() =>
      _GhostOfViscountEffectScreenState();
}

class _GhostOfViscountEffectScreenState extends State<GhostOfViscountEffectScreen> {
  bool copiedGhostAgain = false;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.actingPlayerId,
    );
    final availableCards = <_GhostSourceCard>[];

    for (final player in widget.gameState.players) {
      for (final card in player.playedCards) {
        if (card.wasDiscarded ||
            card.isFaceDown ||
            card.templateId == 'primeiro_na_cena' ||
            card.templateId == 'culpado') {
          continue;
        }

        availableCards.add(
          _GhostSourceCard(
            owner: player,
            card: card,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver O Fantasma do Visconde'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'O Fantasma do Visconde',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                copiedGhostAgain
                    ? '${actingPlayer.name}, você copiou outro Fantasma do Visconde. Escolha agora a carta cujo efeito será realmente copiado.'
                    : '${actingPlayer.name}, escolha uma carta já jogada à frente de qualquer jogador para copiar o efeito dela.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (availableCards.isEmpty)
                _GhostActionCard(
                  text: 'Não há cartas elegíveis já jogadas na mesa para copiar.',
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
                          'Escolha a carta fonte',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...availableCards.map((source) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: OutlinedButton(
                              onPressed: () {
                                if (source.card.templateId ==
                                    'fantasma_do_visconde') {
                                  setState(() {
                                    copiedGhostAgain = true;
                                  });
                                  return;
                                }

                                playExternalCard(
                                  gameState: widget.gameState,
                                  card: source.card,
                                  addCardToCurrentPlayerTable: false,
                                );

                                continueAfterPlayedCard(
                                  context: context,
                                  gameState: widget.gameState,
                                  actingPlayerId: widget.actingPlayerId,
                                  card: source.card,
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
                                      '${source.card.name} - ${source.owner.name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(source.card.shortText),
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

class _GhostSourceCard {
  const _GhostSourceCard({
    required this.owner,
    required this.card,
  });

  final Player owner;
  final GameCard card;
}

class _GhostActionCard extends StatelessWidget {
  const _GhostActionCard({
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
