import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'round_result_screen.dart';

class AccompliceEffectScreen extends StatefulWidget {
  const AccompliceEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<AccompliceEffectScreen> createState() => _AccompliceEffectScreenState();
}

class _AccompliceEffectScreenState extends State<AccompliceEffectScreen> {
  Player? selectedTarget;
  bool targetConfirmedPrivacy = false;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    final availableTargets = widget.gameState.players.where((player) {
      final isActingPlayer = player.id == widget.actingPlayerId;
      final hasCardsInHand = player.hand.isNotEmpty;

      return !isActingPlayer && hasCardsInHand;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Cúmplice'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Efeito do Cúmplice',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name} deve escolher outro jogador. '
                    'Esse jogador descarta uma carta da própria mão e compra outra do monte.',
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
                _TargetSelectionCard(
                  targets: availableTargets,
                  onTargetSelected: (target) {
                    setState(() {
                      selectedTarget = target;
                      targetConfirmedPrivacy = false;
                    });
                  },
                )
              else if (!targetConfirmedPrivacy)
                  _PassToTargetCard(
                    targetPlayer: selectedTarget!,
                    onContinue: () {
                      setState(() {
                        targetConfirmedPrivacy = true;
                      });
                    },
                    onBack: () {
                      setState(() {
                        selectedTarget = null;
                        targetConfirmedPrivacy = false;
                      });
                    },
                  )
                else
                  _DiscardSelectionCard(
                    targetPlayer: selectedTarget!,
                    onBack: () {
                      setState(() {
                        targetConfirmedPrivacy = false;
                      });
                    },
                    onCardSelected: (card) {
                      final target = selectedTarget!;

                      final isGuiltyCard = card.templateId == 'culpado';
                      final isLastCardInHand = target.hand.length == 1;

                      if (isGuiltyCard && !isLastCardInHand) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'O Culpado só pode ser descartado se for a última carta da mão.',
                            ),
                          ),
                        );

                        return;
                      }

                      resolveAccompliceEffect(
                        gameState: widget.gameState,
                        targetPlayer: target,
                        cardToDiscard: card,
                      );

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
              'Não há jogadores com cartas na mão para escolher.',
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

class _TargetSelectionCard extends StatelessWidget {
  const _TargetSelectionCard({
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

class _PassToTargetCard extends StatelessWidget {
  const _PassToTargetCard({
    required this.targetPlayer,
    required this.onContinue,
    required this.onBack,
  });

  final Player targetPlayer;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
              targetPlayer.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Este jogador escolherá uma carta da própria mão para descartar.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Escolher carta',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onBack,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Voltar',
                    style: TextStyle(fontSize: 18),
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

class _DiscardSelectionCard extends StatelessWidget {
  const _DiscardSelectionCard({
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
              'Passe o celular para ${targetPlayer.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este jogador deve escolher uma carta da própria mão para descartar.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ...targetPlayer.hand.map((card) {
              return Card(
                color: const Color(0xFF120818),
                child: ListTile(
                  title: Text(
                    card.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(card.shortText),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    onCardSelected(card);
                  },
                ),
              );
            }),
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