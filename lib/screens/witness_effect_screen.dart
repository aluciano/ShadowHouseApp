import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';
import 'card_exchange_effect_screen.dart';

enum WitnessStep {
  selectTarget,
  privacyBeforeReveal,
  inspectTargetHand,
}

class WitnessEffectScreen extends StatefulWidget {
  const WitnessEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<WitnessEffectScreen> createState() => _WitnessEffectScreenState();
}

class _WitnessEffectScreenState extends State<WitnessEffectScreen> {
  WitnessStep step = WitnessStep.selectTarget;

  Player? selectedTarget;

  @override
  Widget build(BuildContext context) {
    final witnessPlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    final availableTargets = widget.gameState.players.where((player) {
      final isWitnessPlayer = player.id == widget.actingPlayerId;
      final hasCardsInHand = player.hand.isNotEmpty;

      return !isWitnessPlayer && hasCardsInHand;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Testemunha'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Efeito da Testemunha',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${witnessPlayer.name} deve escolher outro jogador para olhar a mão em segredo.',
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              _buildCurrentStep(
                context: context,
                witnessPlayer: witnessPlayer,
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
    required Player witnessPlayer,
    required List<Player> availableTargets,
  }) {
    switch (step) {
      case WitnessStep.selectTarget:
        if (availableTargets.isEmpty) {
          return _MessageCard(
            title: 'Nenhum alvo disponível',
            message: 'Não há outros jogadores com cartas na mão para investigar.',
            buttonText: 'Continuar',
            onPressed: () {
              resolveWitnessWithoutExchange(
                gameState: widget.gameState,
              );

              _goToNextPlayer(context);
            },
          );
        }

        return _TargetSelectionCard(
          targets: availableTargets,
          onTargetSelected: (target) {
            setState(() {
              selectedTarget = target;
              step = WitnessStep.privacyBeforeReveal;
            });
          },
        );

      case WitnessStep.privacyBeforeReveal:
        return _PrivacyCard(
          playerName: witnessPlayer.name,
          title: 'Somente ${witnessPlayer.name} deve olhar',
          message:
          'A Testemunha vai olhar a mão de ${selectedTarget!.name} em segredo.',
          buttonText: 'Ver mão',
          onContinue: () {
            setState(() {
              step = WitnessStep.inspectTargetHand;
            });
          },
          onBack: () {
            setState(() {
              selectedTarget = null;
              step = WitnessStep.selectTarget;
            });
          },
        );

      case WitnessStep.inspectTargetHand:
        final target = selectedTarget!;
        final foundSuspiciousCard = playerHandHasGuiltyOrAccomplice(target);
        final witnessCanExchange = witnessPlayer.hand.isNotEmpty;

        return _InspectTargetHandCard(
          witnessPlayer: witnessPlayer,
          targetPlayer: target,
          foundSuspiciousCard: foundSuspiciousCard,
          witnessCanExchange: witnessCanExchange,
          onContinueWithoutExchange: () {
            resolveWitnessWithoutExchange(
              gameState: widget.gameState,
            );

            _goToNextPlayer(context);
          },
          onStartExchange: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => CardExchangeEffectScreen(
                  gameState: widget.gameState,
                  actingPlayerId: widget.actingPlayerId,
                  fixedTargetPlayerId: selectedTarget!.id,
                  effectTitle: 'Troca da Testemunha',
                  introText:
                  'escolha uma carta da sua mão. Depois o jogador investigado escolherá uma carta da própria mão para trocar.',
                ),
              ),
                  (route) => route.isFirst,
            );
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
              'Escolha o jogador investigado',
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

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({
    required this.playerName,
    required this.title,
    required this.message,
    required this.buttonText,
    required this.onContinue,
    required this.onBack,
  });

  final String playerName;
  final String title;
  final String message;
  final String buttonText;
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
              Icons.visibility,
              size: 64,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
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
                onPressed: onContinue,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    buttonText,
                    style: const TextStyle(fontSize: 18),
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

class _InspectTargetHandCard extends StatelessWidget {
  const _InspectTargetHandCard({
    required this.witnessPlayer,
    required this.targetPlayer,
    required this.foundSuspiciousCard,
    required this.witnessCanExchange,
    required this.onContinueWithoutExchange,
    required this.onStartExchange,
  });

  final Player witnessPlayer;
  final Player targetPlayer;
  final bool foundSuspiciousCard;
  final bool witnessCanExchange;
  final VoidCallback onContinueWithoutExchange;
  final VoidCallback onStartExchange;

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
              'Informação secreta da Testemunha',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Confira a mão do jogador investigado e compare com a sua mão antes de decidir se deseja trocar.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            LayoutBuilder(
              builder: (context, constraints) {
                final useSideBySide = constraints.maxWidth >= 620;

                final targetHand = _HandPreviewPanel(
                  title: 'Mão de ${targetPlayer.name}',
                  cards: targetPlayer.hand,
                  highlightSuspiciousCards: true,
                  emptyMessage: 'Nenhuma carta na mão.',
                );

                final witnessHand = _HandPreviewPanel(
                  title: 'Sua mão (${witnessPlayer.name})',
                  cards: witnessPlayer.hand,
                  highlightSuspiciousCards: false,
                  emptyMessage: 'Você não tem cartas para trocar.',
                );

                if (useSideBySide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: targetHand),
                      const SizedBox(width: 12),
                      Expanded(child: witnessHand),
                    ],
                  );
                }

                return Column(
                  children: [
                    targetHand,
                    const SizedBox(height: 12),
                    witnessHand,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),
            if (!foundSuspiciousCard)
              const Text(
                'Nenhum Culpado ou Cúmplice foi encontrado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              )
            else if (!witnessCanExchange)
              Text(
                '${witnessPlayer.name} encontrou Culpado ou Cúmplice, mas não tem cartas na mão para trocar.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              )
            else
              const Text(
                'Culpado ou Cúmplice encontrado. Você pode trocar uma carta com esse jogador.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 16),
            if (foundSuspiciousCard && witnessCanExchange) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onStartExchange,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Trocar uma carta',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onContinueWithoutExchange,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    foundSuspiciousCard && witnessCanExchange
                        ? 'Não trocar'
                        : 'Continuar',
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

class _HandPreviewPanel extends StatelessWidget {
  const _HandPreviewPanel({
    required this.title,
    required this.cards,
    required this.highlightSuspiciousCards,
    required this.emptyMessage,
  });

  final String title;
  final List<GameCard> cards;
  final bool highlightSuspiciousCards;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF120818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white12,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFE7C76F),
            ),
          ),
          const SizedBox(height: 12),
          if (cards.isEmpty)
            Text(
              emptyMessage,
              style: const TextStyle(
                color: Colors.white54,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            ...cards.map((card) {
              final isSuspicious =
                  card.templateId == 'culpado' || card.templateId == 'cumplice';

              final shouldHighlight = highlightSuspiciousCards && isSuspicious;

              return Card(
                color: shouldHighlight
                    ? const Color(0xFF3A1A4A)
                    : const Color(0xFF221229),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    shouldHighlight ? Icons.warning_amber : Icons.visibility,
                    color: shouldHighlight
                        ? const Color(0xFFE7C76F)
                        : Colors.white70,
                  ),
                  title: Text(
                    card.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(card.shortText),
                ),
              );
            }),
        ],
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