import 'player.dart';
import 'round_result_type.dart';

class RoundResult {
  const RoundResult({
    required this.type,
    required this.winner,
    required this.reason,
    required this.scoringSummary,
  });

  final RoundResultType type;
  final Player winner;
  final String reason;
  final String scoringSummary;
}