import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class TotoEffectScreen extends StatefulWidget {
  const TotoEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<TotoEffectScreen> createState() => _TotoEffectScreenState();
}

class _TotoEffectScreenState extends State<TotoEffectScreen> {
  Player? selectedTarget;
  GameCard? revealedCard;

  @override
  Widget build(BuildContext context) {
    final totoPlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    final availableTargets = widget.gameState.players.where((player) {
      final isTotoPlayer = player.id == widget.actingPlayerId;
      final hasCardsInHand = player.hand.isNotEmpty;

      return !isTotoPlayer && hasCardsInHand;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Totó'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Efeito do Totó',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${totoPlayer.name} deve escolher outro jogador e revelar uma carta da mão dele sem olhar.',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              if (availableTargets.isEmpty)
                _NoAvailableTargetCard(
                  onContinue: () {
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
              else if (selectedTarget == null)
                _TotoTargetSelectionCard(
                  targets: availableTargets,
                  onTargetSelected: (target) {
                    setState(() {
                      selectedTarget = target;
                      revealedCard = null;
                    });
                  },
                )
              else if (revealedCard == null)
                  _HiddenCardSelectionCard(
                    targetPlayer: selectedTarget!,
                    onBack: () {
                      setState(() {
                        selectedTarget = null;
                        revealedCard = null;
                      });
                    },
                    onCardSelected: (card) {
                      final target = selectedTarget!;

                      resolveTotoEffect(
                        gameState: widget.gameState,
                        totoPlayer: totoPlayer,
                        targetPlayer: target,
                        revealedCard: card,
                      );

                      setState(() {
                        revealedCard = card;
                      });
                    },
                  )
                else
                  _TotoRevealResultCard(
                    targetPlayer: selectedTarget!,
                    revealedCard: revealedCard!,
                    roundFinished: widget.gameState.roundFinished,
                    onContinue: () {
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

class _NoAvailableTargetCard extends StatelessWidget {
  const _NoAvailableTargetCard({
    required this.onContinue,
  });

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Não há outros jogadores com cartas na mão para escolher.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotoTargetSelectionCard extends StatelessWidget {
  const _TotoTargetSelectionCard({
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
              'Escolha o jogador alvo',
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
                    child: Text(
                      '${target.name} — ${target.hand.length} carta${target.hand.length == 1 ? '' : 's'} na mão',
                    ),
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

class _HiddenCardSelectionCard extends StatelessWidget {
  const _HiddenCardSelectionCard({
    required this.targetPlayer,
    required this.onBack,
    required this.onCardSelected,
  });

  final Player targetPlayer;
  final VoidCallback onBack;
  final ValueChanged<GameCard> onCardSelected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cartas de ${targetPlayer.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha uma carta sem olhar para revelar.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(targetPlayer.hand.length, (index) {
                final card = targetPlayer.hand[index];

                return SizedBox(
                  width: 110,
                  height: 90,
                  child: OutlinedButton(
                    onPressed: () {
                      onCardSelected(card);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.help_outline),
                        const SizedBox(height: 8),
                        Text(
                          'Carta ${index + 1}',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onBack,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Escolher outro alvo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotoRevealResultCard extends StatelessWidget {
  const _TotoRevealResultCard({
    required this.targetPlayer,
    required this.revealedCard,
    required this.roundFinished,
    required this.onContinue,
  });

  final Player targetPlayer;
  final GameCard revealedCard;
  final bool roundFinished;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final revealedGuilty = revealedCard.templateId == 'culpado';

    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              revealedGuilty ? Icons.warning_amber : Icons.visibility,
              size: 64,
              color: const Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            const Text(
              'Carta revelada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              revealedCard.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              revealedGuilty
                  ? '${targetPlayer.name} estava com o Culpado!'
                  : 'A carta não era o Culpado. Ela volta para a mão de ${targetPlayer.name}.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    roundFinished ? 'Ver resultado da rodada' : 'Continuar',
                    style: const TextStyle(fontSize: 18),
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