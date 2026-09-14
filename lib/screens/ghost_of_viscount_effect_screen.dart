import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/game_card_carousel.dart';
import '../widgets/game_card_preview_dialog.dart';
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

class _GhostOfViscountEffectScreenState
    extends State<GhostOfViscountEffectScreen> {
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
            card.templateId == 'culpado' ||
            card.templateId == 'fantasma_do_visconde') {
          continue;
        }

        availableCards.add(_GhostSourceCard(owner: player, card: card));
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
                  text:
                      'Não há cartas elegíveis já jogadas na mesa para copiar.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    widget.gameState.moveToNextPlayer();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) =>
                            PassDeviceScreen(gameState: widget.gameState),
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
                        GameCardCarousel(
                          cards: availableCards.map((source) {
                            return source.card;
                          }).toList(),
                          cardWidth: 132,
                          labelBuilder: (card) {
                            final source = availableCards.firstWhere(
                              (source) => source.card.id == card.id,
                            );

                            return '${card.name} - ${source.owner.name}';
                          },
                          onCardTap: (card) async {
                            if (card.templateId == 'fantasma_do_visconde') {
                              setState(() {
                                copiedGhostAgain = true;
                              });
                              return;
                            }

                            final shouldCopy = await showGameCardPreviewDialog(
                              context: context,
                              card: card,
                              playLabel: 'Copiar e Jogar',
                            );

                            if (!context.mounted || !shouldCopy) {
                              return;
                            }

                            playExternalCard(
                              gameState: widget.gameState,
                              card: card,
                              addCardToCurrentPlayerTable: false,
                            );

                            continueAfterPlayedCard(
                              context: context,
                              gameState: widget.gameState,
                              actingPlayerId: widget.actingPlayerId,
                              card: card,
                            );
                          },
                        ),
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
  const _GhostSourceCard({required this.owner, required this.card});

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
