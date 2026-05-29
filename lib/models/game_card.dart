import 'card_type.dart';

class GameCard {
  const GameCard({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.shortText,
  });

  final String id;
  final String templateId;
  final String name;
  final CardType type;
  final String shortText;
}