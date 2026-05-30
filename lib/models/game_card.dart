import 'card_type.dart';

class GameCard {
  const GameCard({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.shortText,
    this.wasDiscarded = false,
  });

  final String id;
  final String templateId;
  final String name;
  final CardType type;
  final String shortText;

  /// Indica que a carta foi colocada à frente do jogador por descarte,
  /// não por ter sido jogada normalmente.
  ///
  /// Cartas descartadas ficam visíveis na mesa, mas seus efeitos são ignorados.
  final bool wasDiscarded;

  GameCard copyWith({
    bool? wasDiscarded,
  }) {
    return GameCard(
      id: id,
      templateId: templateId,
      name: name,
      type: type,
      shortText: shortText,
      wasDiscarded: wasDiscarded ?? this.wasDiscarded,
    );
  }
}