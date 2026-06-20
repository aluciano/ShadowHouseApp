import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class BrokenMaskEffectScreen extends StatefulWidget {
  const BrokenMaskEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<BrokenMaskEffectScreen> createState() => _BrokenMaskEffectScreenState();
}

class _BrokenMaskEffectScreenState extends State<BrokenMaskEffectScreen> {
  Player? selectedTarget;
  GameCard? revealedCard;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.actingPlayerId,
    );
    final availableTargets = widget.gameState.players.where((player) {
      return player.id != widget.actingPlayerId && player.hand.isNotEmpty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver A Máscara Quebrada'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'A Máscara Quebrada',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}, escolha um jogador e revele uma carta da mão dele para todos, sem olhar antes.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (availableTargets.isEmpty)
                _SingleActionCard(
                  text: 'Não há outros jogadores com cartas na mão para revelar.',
                  buttonLabel: 'Continuar',
                  onPressed: () {
                    resolveBrokenMaskEffect(gameState: widget.gameState);
                    _continueAfterEffect(context);
                  },
                )
              else if (selectedTarget == null)
                _TargetSelectionCard(
                  title: 'Escolha o jogador alvo',
                  targets: availableTargets,
                  onTargetSelected: (target) {
                    setState(() {
                      selectedTarget = target;
                    });
                  },
                )
              else if (revealedCard == null)
                _HiddenCardSelectionCard(
                  targetPlayer: selectedTarget!,
                  onBack: () {
                    setState(() {
                      selectedTarget = null;
                    });
                  },
                  onCardSelected: (card) {
                    setState(() {
                      revealedCard = card;
                    });
                  },
                )
              else
                _BrokenMaskRevealCard(
                  targetPlayer: selectedTarget!,
                  revealedCard: revealedCard!,
                  onContinue: () {
                    resolveBrokenMaskEffect(gameState: widget.gameState);
                    _continueAfterEffect(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _continueAfterEffect(BuildContext context) {
    if (widget.gameState.roundFinished) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => RoundResultScreen(gameState: widget.gameState),
        ),
        (route) => route.isFirst,
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(gameState: widget.gameState),
      ),
      (route) => route.isFirst,
    );
  }
}

class _BrokenMaskRevealCard extends StatelessWidget {
  const _BrokenMaskRevealCard({
    required this.targetPlayer,
    required this.revealedCard,
    required this.onContinue,
  });

  final Player targetPlayer;
  final GameCard revealedCard;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(
              Icons.visibility,
              size: 56,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 16),
            Text(
              'Carta revelada da mão de ${targetPlayer.name}:',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              revealedCard.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              revealedCard.shortText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
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

class _TargetSelectionCard extends StatelessWidget {
  const _TargetSelectionCard({
    required this.title,
    required this.targets,
    required this.onTargetSelected,
  });

  final String title;
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
            Text(
              title,
              style: const TextStyle(
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
              'Escolha uma carta sem olhar da mão de ${targetPlayer.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(targetPlayer.hand.length, (index) {
                final card = targetPlayer.hand[index];

                return SizedBox(
                  width: 120,
                  height: 96,
                  child: OutlinedButton(
                    onPressed: () {
                      onCardSelected(card);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.help_outline),
                        const SizedBox(height: 8),
                        Text('Carta ${index + 1}'),
                      ],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('Escolher outro jogador'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SingleActionCard extends StatelessWidget {
  const _SingleActionCard({
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
