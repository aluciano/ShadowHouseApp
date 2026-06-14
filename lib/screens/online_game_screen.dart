import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../models/online_game_session.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({
    super.key,
    required this.session,
    required this.initialViewedPlayerId,
  });

  final OnlineGameSession session;
  final String initialViewedPlayerId;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late GameState gameState;
  late String viewedPlayerId;

  @override
  void initState() {
    super.initState();

    gameState = widget.session.gameState;
    viewedPlayerId = widget.initialViewedPlayerId;
  }

  Player get viewedPlayer {
    return gameState.players.firstWhere(
      (player) => player.id == viewedPlayerId,
      orElse: () => gameState.currentPlayer,
    );
  }

  bool get isViewingCurrentPlayer {
    return viewedPlayer.id == gameState.currentPlayer.id;
  }

  Future<void> playOnlineCard(GameCard card) async {
    if (!isViewingCurrentPlayer) {
      showMessage('Aguarde sua vez para jogar.');
      return;
    }

    final isFirstTurnOfRound = gameState.players.every(
      (player) => player.playedCards.isEmpty,
    );
    final isFirstSceneCard = card.templateId == 'primeiro_na_cena';

    if (isFirstTurnOfRound && !isFirstSceneCard) {
      showMessage('A primeira carta da rodada deve ser Primeiro na Cena.');
      return;
    }

    final isGuiltyCard = card.templateId == 'culpado';
    final isLastCardInHand = viewedPlayer.hand.length == 1;

    if (isGuiltyCard && !isLastCardInHand) {
      showMessage('Voce so pode jogar o Culpado como ultima carta da mao.');
      return;
    }

    final shouldPlay = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(card.name),
          content: Text('${card.shortText}\n\nDeseja jogar esta carta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Jogar'),
            ),
          ],
        );
      },
    );

    if (shouldPlay != true) {
      return;
    }

    final previousPlayerId = gameState.currentPlayer.id;

    setState(() {
      playCard(
        gameState: gameState,
        card: card,
      );

      if (!gameState.roundFinished &&
          gameState.currentPlayer.id == previousPlayerId) {
        gameState.moveToNextPlayer();
      }

      viewedPlayerId = gameState.currentPlayer.id;
    });

    if (gameState.roundFinished) {
      showMessage('Rodada finalizada. A tela de resultado online vem na proxima etapa.');
      return;
    }

    if (_cardNeedsOnlineResolution(card)) {
      showMessage(
        'Efeito de ${card.name} sera resolvido online em uma proxima etapa.',
      );
    }
  }

  bool _cardNeedsOnlineResolution(GameCard card) {
    return {
      'cumplice',
      'taca_envenenada',
      'detetive',
      'toto',
      'xerife',
      'chave_enferrujada',
      'bebe_da_familia',
      'testemunha',
      'trocar',
      'compartilhar',
      'rumores',
    }.contains(card.templateId);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.currentPlayer;
    final selectedPlayer = viewedPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('Sala ${widget.session.room.code}'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const Text(
                'Partida Online',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Vez de ${currentPlayer.name}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedPlayer.id,
                decoration: const InputDecoration(
                  labelText: 'Visualizando como',
                  border: OutlineInputBorder(),
                ),
                items: gameState.players.map((player) {
                  return DropdownMenuItem(
                    value: player.id,
                    child: Text(player.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    viewedPlayerId = value;
                  });
                },
              ),
              const SizedBox(height: 24),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mao de ${selectedPlayer.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isViewingCurrentPlayer
                            ? 'Escolha uma carta para jogar.'
                            : 'Este jogador esta aguardando a propria vez.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      if (selectedPlayer.hand.isEmpty)
                        const Text(
                          'Nenhuma carta na mao.',
                          style: TextStyle(color: Colors.white54),
                        )
                      else
                        ...selectedPlayer.hand.map((card) {
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
                              trailing: Icon(
                                isViewingCurrentPlayer
                                    ? Icons.play_arrow
                                    : Icons.lock,
                              ),
                              onTap: isViewingCurrentPlayer
                                  ? () => playOnlineCard(card)
                                  : null,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Mesa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...gameState.players.map((player) {
                        final isCurrent = player.id == currentPlayer.id;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCurrent ? Icons.play_arrow : Icons.person,
                                    size: 18,
                                    color: isCurrent
                                        ? const Color(0xFFE7C76F)
                                        : Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      style: TextStyle(
                                        fontWeight: isCurrent
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${player.hand.length} carta${player.hand.length == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (player.playedCards.isEmpty)
                                const Text(
                                  'Nenhuma carta a frente.',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: player.playedCards.map((card) {
                                    return Chip(
                                      label: Text(card.name),
                                      backgroundColor: const Color(0xFF120818),
                                      side: const BorderSide(
                                        color: Color(0xFFE7C76F),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
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
