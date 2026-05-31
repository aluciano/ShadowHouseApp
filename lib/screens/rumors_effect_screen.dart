import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class RumorsEffectScreen extends StatefulWidget {
  const RumorsEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<RumorsEffectScreen> createState() => _RumorsEffectScreenState();
}

class _RumorsEffectScreenState extends State<RumorsEffectScreen> {
  int currentSelectorIndex = 0;
  bool privacyConfirmed = false;

  Map<String, List<GameCard>>? originalHandsByPlayerId;
  Map<String, int>? receivedCardsCountByPlayerId;
  String? nextPlayerId;

  final List<RumorCardSelection> selections = [];

  @override
  void initState() {
    super.initState();

    originalHandsByPlayerId = {
      for (final player in widget.gameState.players)
        player.id: List<GameCard>.from(player.hand),
    };
  }

  @override
  Widget build(BuildContext context) {
    final players = widget.gameState.players;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver Rumores'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Resolver Rumores',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cada jogador tenta pegar uma carta, sem olhar, da mão do jogador à sua direita. As cartas só serão transferidas depois que todos escolherem.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              if (receivedCardsCountByPlayerId != null)
                _RumorsCompletedCard(
                  gameState: widget.gameState,
                  actingPlayerId: widget.actingPlayerId,
                  nextPlayerId: nextPlayerId,
                  receivedCardsCountByPlayerId: receivedCardsCountByPlayerId!,
                  onContinue: () {
                    _goToNextPlayer(context);
                  },
                )
              else
                _buildCurrentStep(
                  context: context,
                  players: players,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep({
    required BuildContext context,
    required List<Player> players,
  }) {
    final currentPlayer = players[currentSelectorIndex];

    final sourcePlayer = _playerToTheRightOf(
      currentPlayer: currentPlayer,
      players: players,
    );

    final sourceOriginalHand = originalHandsByPlayerId![sourcePlayer.id] ?? [];

    final availableCards = sourceOriginalHand.where((card) {
      final alreadySelected = selections.any(
            (selection) => selection.card.id == card.id,
      );

      return !alreadySelected;
    }).toList();

    if (!privacyConfirmed) {
      return _PassToPlayerCard(
        player: currentPlayer,
        sourcePlayer: sourcePlayer,
        currentIndex: currentSelectorIndex + 1,
        totalPlayers: players.length,
        sourceHasCards: availableCards.isNotEmpty,
        onContinue: () {
          setState(() {
            privacyConfirmed = true;
          });
        },
      );
    }

    if (availableCards.isEmpty) {
      return _NoCardToTakeCard(
        player: currentPlayer,
        sourcePlayer: sourcePlayer,
        currentIndex: currentSelectorIndex + 1,
        totalPlayers: players.length,
        onContinue: () {
          _advanceOrFinish();
        },
      );
    }

    return _HiddenCardSelectionCard(
      player: currentPlayer,
      sourcePlayer: sourcePlayer,
      availableCards: availableCards,
      currentIndex: currentSelectorIndex + 1,
      totalPlayers: players.length,
      onCardSelected: (card) {
        selections.add(
          RumorCardSelection(
            receiverPlayerId: currentPlayer.id,
            sourcePlayerId: sourcePlayer.id,
            card: card,
          ),
        );

        _advanceOrFinish();
      },
    );
  }

  Player _playerToTheRightOf({
    required Player currentPlayer,
    required List<Player> players,
  }) {
    final currentIndex = players.indexWhere(
          (player) => player.id == currentPlayer.id,
    );

    final rightIndex = (currentIndex - 1 + players.length) % players.length;

    return players[rightIndex];
  }

  void _advanceOrFinish() {
    final isLastPlayer =
        currentSelectorIndex == widget.gameState.players.length - 1;

    if (isLastPlayer) {
      final summary = resolveRumorsEffect(
        gameState: widget.gameState,
        selections: selections,
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

class _PassToPlayerCard extends StatelessWidget {
  const _PassToPlayerCard({
    required this.player,
    required this.sourcePlayer,
    required this.currentIndex,
    required this.totalPlayers,
    required this.sourceHasCards,
    required this.onContinue,
  });

  final Player player;
  final Player sourcePlayer;
  final int currentIndex;
  final int totalPlayers;
  final bool sourceHasCards;
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
            Text(
              sourceHasCards
                  ? '${player.name} vai escolher uma carta, sem olhar, da mão de ${sourcePlayer.name}.'
                  : '${sourcePlayer.name}, à direita de ${player.name}, não tem cartas disponíveis para Rumores.',
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
                    sourceHasCards ? 'Escolher carta' : 'Continuar',
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

class _HiddenCardSelectionCard extends StatelessWidget {
  const _HiddenCardSelectionCard({
    required this.player,
    required this.sourcePlayer,
    required this.availableCards,
    required this.currentIndex,
    required this.totalPlayers,
    required this.onCardSelected,
  });

  final Player player;
  final Player sourcePlayer;
  final List<GameCard> availableCards;
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
              '${player.name}, escolha uma carta de ${sourcePlayer.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Escolha sem olhar. A carta só será transferida depois que todos terminarem.',
              style: TextStyle(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(availableCards.length, (index) {
                final card = availableCards[index];

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
          ],
        ),
      ),
    );
  }
}

class _NoCardToTakeCard extends StatelessWidget {
  const _NoCardToTakeCard({
    required this.player,
    required this.sourcePlayer,
    required this.currentIndex,
    required this.totalPlayers,
    required this.onContinue,
  });

  final Player player;
  final Player sourcePlayer;
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
              Icons.info_outline,
              size: 56,
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
            Text(
              '${player.name} não recebeu carta',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${sourcePlayer.name}, à direita de ${player.name}, não tinha cartas disponíveis para Rumores.',
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

class _RumorsCompletedCard extends StatelessWidget {
  const _RumorsCompletedCard({
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
              'Rumores resolvido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Cada jogador pegou uma carta, quando possível, da mão do jogador à sua direita.',
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
                labels.add('jogou Rumores');
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