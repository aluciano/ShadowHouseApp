import 'player.dart';
import 'round_result_type.dart';

class RoundResult {
  const RoundResult({
    required this.type,
    required this.winner,
    required this.reason,
    required this.scoringSummary,
    required this.roundPointsByPlayerId,
  });

  final RoundResultType type;
  final Player winner;
  final String reason;
  final String scoringSummary;

  /// Pontos ganhos por cada jogador nesta rodada.
  ///
  /// Exemplo:
  /// {
  ///   'player_0': 2,
  ///   'player_1': 0,
  ///   'player_2': 2,
  /// }
  final Map<String, int> roundPointsByPlayerId;
}