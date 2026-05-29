import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/game_mode.dart';
import '../models/game_setup_recommendation.dart';
import 'setup_summary_row.dart';

class SetupSummaryCard extends StatelessWidget {
  const SetupSummaryCard({
    super.key,
    required this.playerCount,
    required this.gameMode,
    required this.recommendation,
  });

  final int playerCount;
  final GameMode gameMode;
  final GameSetupRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SetupSummaryRow(
              label: 'Jogadores',
              value: '$playerCount',
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Modo',
              value: GameSetupRules.titleForMode(gameMode),
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Cartas iniciais',
              value: '${recommendation.initialCards}',
            ),
            if (recommendation.ghostCopies > 0) ...[
              const Divider(),
              SetupSummaryRow(
                label: 'Fantasmas do Visconde',
                value: '${recommendation.ghostCopies}',
              ),
            ],
            if (recommendation.extraSilenceCopies > 0) ...[
              const Divider(),
              SetupSummaryRow(
                label: 'Silêncio na Mansão extra',
                value: '+${recommendation.extraSilenceCopies}',
              ),
            ],
            if (recommendation.extraSealedCardCopies > 0) ...[
              const Divider(),
              SetupSummaryRow(
                label: 'A Carta Selada extra',
                value: '+${recommendation.extraSealedCardCopies}',
              ),
            ],
          ],
        ),
      ),
    );
  }
}