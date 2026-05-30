import 'player.dart';
import 'round_result_type.dart';

class RoundResult {
  const RoundResult({
    required this.type,
    this.winner,
    required this.reason,
    required this.scoringSummary,
    required this.roundPointsByPlayerId,
  });

  final RoundResultType type;
  final Player? winner;
  final String reason;
  final String scoringSummary;

  /// Pontos ganhos por cada jogador nesta rodada.
  final Map<String, int> roundPointsByPlayerId;
}