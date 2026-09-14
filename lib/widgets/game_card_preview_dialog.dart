import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/game_card.dart';
import 'game_card_art.dart';

Future<bool> showGameCardPreviewDialog({
  required BuildContext context,
  required GameCard card,
  bool canPlay = true,
  bool showPlayButton = true,
  bool showFaceDown = false,
  String closeLabel = 'Fechar',
  String playLabel = 'Jogar',
}) async {
  final shouldPlay = await showDialog<bool>(
    context: context,
    builder: (context) {
      return GameCardPreviewDialog(
        card: card,
        canPlay: canPlay,
        showPlayButton: showPlayButton,
        showFaceDown: showFaceDown,
        closeLabel: closeLabel,
        playLabel: playLabel,
      );
    },
  );

  return shouldPlay == true;
}

class GameCardPreviewDialog extends StatelessWidget {
  const GameCardPreviewDialog({
    super.key,
    required this.card,
    required this.canPlay,
    required this.showPlayButton,
    required this.showFaceDown,
    required this.closeLabel,
    required this.playLabel,
  });

  final GameCard card;
  final bool canPlay;
  final bool showPlayButton;
  final bool showFaceDown;
  final String closeLabel;
  final String playLabel;

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: const Color(0xFF120818),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final maxHeight = constraints.maxHeight;
                      final widthByHeight = maxHeight * 815 / 1110;
                      final cardWidth = math.min(maxWidth, widthByHeight);

                      return GameCardArt(
                        card: card,
                        width: cardWidth,
                        showFaceDown: showFaceDown,
                        showDiscarded: false,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      icon: const Icon(Icons.close),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(closeLabel),
                      ),
                    ),
                  ),
                  if (showPlayButton) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canPlay
                            ? () {
                                Navigator.of(context).pop(true);
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(playLabel),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
