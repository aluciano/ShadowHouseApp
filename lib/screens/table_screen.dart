import 'package:flutter/material.dart';

import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import '../widgets/game_card_carousel.dart';
import '../widgets/game_card_preview_dialog.dart';
import '../widgets/shadow_background.dart';

class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.gameState,
    this.showHands = false,
    this.title = 'Mesa',
  });

  final GameState gameState;
  final bool showHands;
  final String title;

  static const _handcuffsCard = GameCard(
    id: 'table_handcuffs',
    templateId: 'algemas',
    name: 'Algemas',
    type: CardType.special,
    shortText: 'O jogador com algemas não vence se revelar o Culpado.',
  );

  String deckSummaryText() {
    final initialDeckSize = gameState.initialDeckSize;
    final currentDeckSize = gameState.deck.length;
    final drawnCards = gameState.drawnCardsCount;

    if (drawnCards <= 0) {
      return 'Monte de compras: $currentDeckSize carta${currentDeckSize == 1 ? '' : 's'}';
    }

    final drawGroups = gameState.deckDrawGroups.isEmpty
        ? List.generate(drawnCards, (_) => 1)
        : gameState.deckDrawGroups;
    final subtractions = drawGroups.join(' - ');

    return 'Monte de compras: $initialDeckSize - $subtractions = $currentDeckSize carta${currentDeckSize == 1 ? '' : 's'}';
  }

  List<String> roundEffects() {
    final effects = <String>[];

    if (gameState.silenceOwnerPlayerId != null) {
      final owner = gameState.players.firstWhere(
        (player) => player.id == gameState.silenceOwnerPlayerId,
      );
      effects.add(
        'Silêncio na Mansão: Detetive e Totó ficam bloqueados até o início da próxima vez de ${owner.name}.',
      );
    }

    if (gameState.hasSecretOath) {
      final firstPlayer = gameState.players.firstWhere(
        (player) => player.id == gameState.secretOathPlayerId,
      );
      final secondPlayer = gameState.players.firstWhere(
        (player) => player.id == gameState.secretOathPartnerPlayerId,
      );
      effects.add(
        'Juramento Secreto: ${firstPlayer.name} e ${secondPlayer.name} estão vinculados até o fim da rodada.',
      );
    }

    if (gameState.hasPendingPiano) {
      final controllerPlayer = gameState.players.firstWhere(
        (player) => player.id == gameState.pianoControllerPlayerId,
      );
      final targetPlayer = gameState.players.firstWhere(
        (player) => player.id == gameState.pianoTargetPlayerId,
      );
      effects.add(
        'O Piano Desafinado: na próxima vez de ${targetPlayer.name}, ${controllerPlayer.name} jogará uma carta aleatória por esse jogador.',
      );
    }

    return effects;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                title == 'Mesa Final' ? 'Mesa Final' : 'Estado da Mesa',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                showHands
                    ? 'Confira as cartas jogadas à frente e as cartas que ainda estavam na mão ao final da rodada.'
                    : 'Veja as cartas já jogadas à frente de cada jogador.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                deckSummaryText(),
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Cartas riscadas foram descartadas e não têm efeito.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  fontStyle: FontStyle.italic,
                ),
              ),
              if (roundEffects().isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFF221229),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Efeitos da rodada',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...roundEffects().map((effect) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              effect,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ...gameState.players.map((player) {
                final isCurrentPlayer = player.id == gameState.currentPlayer.id;

                return Card(
                  color: isCurrentPlayer
                      ? const Color(0xFF3A1A4A)
                      : const Color(0xFF221229),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isCurrentPlayer
                          ? const Color(0xFFE7C76F)
                          : Colors.white12,
                      width: isCurrentPlayer ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCurrentPlayer ? Icons.play_arrow : Icons.person,
                              color: isCurrentPlayer
                                  ? const Color(0xFFE7C76F)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${player.hand.length} carta${player.hand.length == 1 ? '' : 's'} na mão',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                Builder(
                                  builder: (context) {
                                    final roundPoints =
                                        gameState
                                            .roundResult
                                            ?.roundPointsByPlayerId[player
                                            .id] ??
                                        0;

                                    final previousScore =
                                        player.score - roundPoints;

                                    final scoreText =
                                        showHands &&
                                            gameState.roundResult != null
                                        ? '$previousScore + $roundPoints = ${player.score} ponto${player.score == 1 ? '' : 's'}'
                                        : '${player.score} ponto${player.score == 1 ? '' : 's'}';

                                    return Text(
                                      scoreText,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (player.hasHandcuffs) ...[
                          const SizedBox(height: 8),
                          GameCardCarousel(
                            cards: const [_handcuffsCard],
                            cardWidth: 72,
                            labelBuilder: (_) => 'Algemas',
                            onCardTap: (_) {
                              showGameCardPreviewDialog(
                                context: context,
                                card: _handcuffsCard,
                                showPlayButton: false,
                              );
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Text(
                          'Cartas à frente',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE7C76F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (player.playedCards.isEmpty)
                          const Text(
                            'Nenhuma carta à frente.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          GameCardCarousel(
                            cards: player.playedCards,
                            cardWidth: 72,
                            labelBuilder: (card) =>
                                card.isFaceDown ? 'Carta Selada' : card.name,
                            showFaceDownBuilder: (card) => card.isFaceDown,
                            onCardTap: (card) {
                              showGameCardPreviewDialog(
                                context: context,
                                card: card,
                                showFaceDown: card.isFaceDown && !showHands,
                                showPlayButton: false,
                              );
                            },
                          ),
                        if (showHands) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Cartas que estavam na mão',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (player.hand.isEmpty)
                            const Text(
                              'Nenhuma carta restante na mão.',
                              style: TextStyle(
                                color: Colors.white54,
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          else
                            GameCardCarousel(
                              cards: player.hand,
                              cardWidth: 72,
                              labelBuilder: (card) => card.name,
                              onCardTap: (card) {
                                showGameCardPreviewDialog(
                                  context: context,
                                  card: card,
                                  showPlayButton: false,
                                );
                              },
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
