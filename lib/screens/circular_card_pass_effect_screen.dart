import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class CircularCardPassEffectScreen extends StatefulWidget {
  const CircularCardPassEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
    required this.effectTitle,
    required this.introText,
    required this.passToLeft,
  });

  final GameState gameState;
  final String actingPlayerId;
  final String effectTitle;
  final String introText;
  final bool passToLeft;

  @override
  State<CircularCardPassEffectScreen> createState() =>
      _CircularCardPassEffectScreenState();
}

class _CircularCardPassEffectScreenState
    extends State<CircularCardPassEffectScreen> {
  int currentSelectorIndex = 0;
  bool privacyConfirmed = false;

  Map<String, int>? receivedCardsCountByPlayerId;
  String? nextPlayerId;

  final Map<String, GameCard> selectedCardByPlayerId = {};

  @override
  Widget build(BuildContext context) {
    final eligiblePlayers = widget.gameState.players.where((player) {
      return player.hand.isNotEmpty;
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
                widget.introText,
                style: const TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              if (receivedCardsCountByPlayerId != null)
                _EffectCompletedCard(
                  gameState: widget.gameState,
                  actingPlayerId: widget.actingPlayerId,
                  nextPlayerId: nextPlayerId,
                  receivedCardsCountByPlayerId: receivedCardsCountByPlayerId!,
                  onContinue: () {
                    _goToNextPlayer(context);
                  },
                )
              else if (eligiblePlayers.isEmpty)
                _NoCardsAvailableCard(
                  onContinue: () {
                    widget.gameState.moveToNextPlayer();
                    _goToNextPlayer(context);
                  },
                )
              else
                _buildCurrentStep(
                  context: context,
                  eligiblePlayers: eligiblePlayers,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep({
    required BuildContext context,
    required List<Player> eligiblePlayers,
  }) {
    final currentPlayer = eligiblePlayers[currentSelectorIndex];

    if (!privacyConfirmed) {
      return _PassToPlayerCard(
        player: currentPlayer,
        currentIndex: currentSelectorIndex + 1,
        totalPlayers: eligiblePlayers.length,
        onContinue: () {
          setState(() {
            privacyConfirmed = true;
          });
        },
      );
    }

    return _CardSelectionCard(
      player: currentPlayer,
      currentIndex: currentSelectorIndex + 1,
      totalPlayers: eligiblePlayers.length,
      onCardSelected: (card) {
        selectedCardByPlayerId[currentPlayer.id] = card;

        final isLastPlayer =
            currentSelectorIndex == eligiblePlayers.length - 1;

        if (isLastPlayer) {
          final summary = resolveCircularCardPassEffect(
            gameState: widget.gameState,
            selectedCardByPlayerId: selectedCardByPlayerId,
            passToLeft: widget.passToLeft,
          );

          setState(() {
            receivedCardsCountByPlayerId = summary;
            nextPlayerId = widget.gameState.currentPlayer.id;
          });

          return;
        }

        setState(() {
          currentSelectorIndex++;
          privacyConfirmed = false;
        });
      },
    );
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

class _EffectCompletedCard extends StatelessWidget {
  const _EffectCompletedCard({
    required this.gameState,
    required this.actingPlayerId,
    required this.nextPlayerId,
    required this.receivedCardsCountByPlayerId,
    required this.onContinue,
  });

  final GameState gameState;
  final String actingPlayerId;
  final String? nextPlayerId;
  final Map<String, int> receivedCardsCountByPlayerId;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            const Text(
              'Compartilhar resolvido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'As cartas foram passadas na ordem da mesa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ...gameState.players.map((player) {
              final receivedCount =
                  receivedCardsCountByPlayerId[player.id] ?? 0;

              final labels = <String>[];

              if (player.id == actingPlayerId) {
                labels.add('jogou Compartilhar');
              }

              if (player.id == nextPlayerId) {
                labels.add('próximo a jogar');
              }

              final labelText = labels.isEmpty ? '' : ' (${labels.join(', ')})';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${player.name}$labelText',
                        style: TextStyle(
                          color: player.id == nextPlayerId
                              ? const Color(0xFFE7C76F)
                              : Colors.white70,
                          fontWeight: player.id == nextPlayerId
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '$receivedCount carta${receivedCount == 1 ? '' : 's'} recebida${receivedCount == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: receivedCount > 0
                            ? const Color(0xFFE7C76F)
                            : Colors.white54,
                        fontWeight: receivedCount > 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Continuar',
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

class _NoCardsAvailableCard extends StatelessWidget {
  const _NoCardsAvailableCard({
    required this.onContinue,
  });

  final VoidCallback onContinue;

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
            const Text(
              'Nenhuma carta disponível',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Nenhum jogador tem cartas na mão para compartilhar. A carta fica à frente sem efeito.',
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
                    'Continuar',
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

class _PassToPlayerCard extends StatelessWidget {
  const _PassToPlayerCard({
    required this.player,
    required this.currentIndex,
    required this.totalPlayers,
    required this.onContinue,
  });

  final Player player;
  final int currentIndex;
  final int totalPlayers;
  final VoidCallback onContinue;

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
            Text(
              'Escolha $currentIndex de $totalPlayers',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
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
              player.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Este jogador deve escolher uma carta da própria mão para compartilhar.',
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
          ],
        ),
      ),
    );
  }
}

class _CardSelectionCard extends StatelessWidget {
  const _CardSelectionCard({
    required this.player,
    required this.currentIndex,
    required this.totalPlayers,
    required this.onCardSelected,
  });

  final Player player;
  final int currentIndex;
  final int totalPlayers;
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
              'Escolha $currentIndex de $totalPlayers',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${player.name}, escolha uma carta da sua mão',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Essa carta será entregue somente depois que todos escolherem.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ...player.hand.map((card) {
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
          ],
        ),
      ),
    );
  }
}