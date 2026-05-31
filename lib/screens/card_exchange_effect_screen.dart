import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

enum CardExchangeStep {
  selectTarget,
  selectActingPlayerCard,
  passToTarget,
  selectTargetCard,
  noEffect,
}

class CardExchangeEffectScreen extends StatefulWidget {
  const CardExchangeEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
    required this.effectTitle,
    required this.introText,
    this.fixedTargetPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;
  final String effectTitle;
  final String introText;

  /// Quando vier preenchido, a tela não pede para escolher alvo.
  ///
  /// Isso será usado pela Testemunha, que já escolheu o jogador investigado antes.
  final String? fixedTargetPlayerId;

  @override
  State<CardExchangeEffectScreen> createState() =>
      _CardExchangeEffectScreenState();
}

class _CardExchangeEffectScreenState extends State<CardExchangeEffectScreen> {
  late CardExchangeStep step;

  Player? selectedTarget;
  GameCard? selectedActingPlayerCard;

  @override
  void initState() {
    super.initState();

    final actingPlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    if (widget.fixedTargetPlayerId != null) {
      selectedTarget = widget.gameState.players.firstWhere(
            (player) => player.id == widget.fixedTargetPlayerId,
      );
    }

    if (actingPlayer.hand.isEmpty) {
      step = CardExchangeStep.noEffect;
    } else if (selectedTarget == null) {
      step = CardExchangeStep.selectTarget;
    } else {
      step = CardExchangeStep.selectActingPlayerCard;
    }
  }

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
        title: Text(widget.effectTitle),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.effectTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${actingPlayer.name}: ${widget.introText}',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              _buildCurrentStep(
                context: context,
                actingPlayer: actingPlayer,
                availableTargets: availableTargets,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep({
    required BuildContext context,
    required Player actingPlayer,
    required List<Player> availableTargets,
  }) {
    switch (step) {
      case CardExchangeStep.noEffect:
        return _MessageCard(
          title: 'Efeito sem troca',
          message:
          '${actingPlayer.name} não tem mais cartas na mão para trocar. A carta fica à frente sem efeito.',
          buttonText: 'Continuar',
          onPressed: () {
            widget.gameState.moveToNextPlayer();
            _goToNextPlayer(context);
          },
        );

      case CardExchangeStep.selectTarget:
        if (availableTargets.isEmpty) {
          return _MessageCard(
            title: 'Nenhum alvo disponível',
            message:
            'Não há outros jogadores com cartas na mão para realizar a troca. A carta fica à frente sem efeito.',
            buttonText: 'Continuar',
            onPressed: () {
              widget.gameState.moveToNextPlayer();
              _goToNextPlayer(context);
            },
          );
        }

        return _TargetSelectionCard(
          targets: availableTargets,
          onTargetSelected: (target) {
            setState(() {
              selectedTarget = target;
              step = CardExchangeStep.selectActingPlayerCard;
            });
          },
        );

      case CardExchangeStep.selectActingPlayerCard:
        return _ActingPlayerCardSelectionCard(
          actingPlayer: actingPlayer,
          targetPlayer: selectedTarget!,
          onCardSelected: (card) {
            setState(() {
              selectedActingPlayerCard = card;
              step = CardExchangeStep.passToTarget;
            });
          },
          onBack: widget.fixedTargetPlayerId == null
              ? () {
            setState(() {
              selectedTarget = null;
              step = CardExchangeStep.selectTarget;
            });
          }
              : null,
        );

      case CardExchangeStep.passToTarget:
        return _PassToTargetCard(
          targetPlayer: selectedTarget!,
          onContinue: () {
            setState(() {
              step = CardExchangeStep.selectTargetCard;
            });
          },
          onBack: () {
            setState(() {
              selectedActingPlayerCard = null;
              step = CardExchangeStep.selectActingPlayerCard;
            });
          },
        );

      case CardExchangeStep.selectTargetCard:
        return _TargetCardSelectionCard(
          targetPlayer: selectedTarget!,
          onCardSelected: (targetCard) {
            resolveCardExchange(
              gameState: widget.gameState,
              actingPlayer: actingPlayer,
              actingPlayerCard: selectedActingPlayerCard!,
              targetPlayer: selectedTarget!,
              targetPlayerCard: targetCard,
            );

            _goToNextPlayer(context);
          },
          onBack: () {
            setState(() {
              step = CardExchangeStep.passToTarget;
            });
          },
        );
    }
  }

  void _goToNextPlayer(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(
          gameState: widget.gameState,
        ),
      ),
          (route) => route.isFirst,
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

class _ActingPlayerCardSelectionCard extends StatelessWidget {
  const _ActingPlayerCardSelectionCard({
    required this.actingPlayer,
    required this.targetPlayer,
    required this.onCardSelected,
    required this.onBack,
  });

  final Player actingPlayer;
  final Player targetPlayer;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback? onBack;

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
              '${actingPlayer.name}, escolha uma carta da sua mão',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essa carta será trocada com uma carta de ${targetPlayer.name}.',
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ...actingPlayer.hand.map((card) {
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
            if (onBack != null) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onBack,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Escolher outro alvo'),
                ),
              ),
            ],
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
              'Este jogador deve escolher uma carta da própria mão para trocar.',
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

class _TargetCardSelectionCard extends StatelessWidget {
  const _TargetCardSelectionCard({
    required this.targetPlayer,
    required this.onCardSelected,
    required this.onBack,
  });

  final Player targetPlayer;
  final ValueChanged<GameCard> onCardSelected;
  final VoidCallback onBack;

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
              '${targetPlayer.name}, escolha uma carta da sua mão',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essa carta será entregue ao outro jogador.',
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
                child: Text('Voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.info_outline,
              size: 56,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    buttonText,
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