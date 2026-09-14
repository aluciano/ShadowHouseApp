import 'package:flutter/material.dart';

import '../models/game_card.dart';
import 'game_card_art.dart';

class GameCardCarousel extends StatelessWidget {
  const GameCardCarousel({
    super.key,
    required this.cards,
    this.cardWidth = 150,
    this.showFaceDown = false,
    this.showDiscarded = true,
    this.onCardTap,
    this.labelBuilder,
    this.showFaceDownBuilder,
  });

  final List<GameCard> cards;
  final double cardWidth;
  final bool showFaceDown;
  final bool showDiscarded;
  final ValueChanged<GameCard>? onCardTap;
  final String Function(GameCard card)? labelBuilder;
  final bool Function(GameCard card)? showFaceDownBuilder;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: cards.map((card) {
          final label = labelBuilder?.call(card);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onCardTap == null ? null : () => onCardTap!(card),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GameCardArt(
                    card: card,
                    width: cardWidth,
                    showFaceDown:
                        showFaceDownBuilder?.call(card) ?? showFaceDown,
                    showDiscarded: showDiscarded,
                  ),
                  if (label != null) ...[
                    const SizedBox(height: 6),
                    SizedBox(
                      width: cardWidth,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
