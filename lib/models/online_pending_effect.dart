enum OnlineEffectType {
  detective,
  toto,
}

class OnlinePendingEffect {
  const OnlinePendingEffect({
    required this.type,
    required this.actingPlayerId,
    required this.cardName,
    this.targetPlayerId,
    this.revealedCardId,
    this.revealedCardName,
    this.revealedCardTemplateId,
    this.resultMessage,
    this.acknowledgedPlayerIds = const [],
  });

  final OnlineEffectType type;
  final String actingPlayerId;
  final String cardName;
  final String? targetPlayerId;
  final String? revealedCardId;
  final String? revealedCardName;
  final String? revealedCardTemplateId;
  final String? resultMessage;
  final List<String> acknowledgedPlayerIds;

  bool get wasResolved => targetPlayerId != null && resultMessage != null;

  OnlinePendingEffect copyWith({
    OnlineEffectType? type,
    String? actingPlayerId,
    String? cardName,
    String? targetPlayerId,
    String? revealedCardId,
    String? revealedCardName,
    String? revealedCardTemplateId,
    String? resultMessage,
    List<String>? acknowledgedPlayerIds,
  }) {
    return OnlinePendingEffect(
      type: type ?? this.type,
      actingPlayerId: actingPlayerId ?? this.actingPlayerId,
      cardName: cardName ?? this.cardName,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      revealedCardId: revealedCardId ?? this.revealedCardId,
      revealedCardName: revealedCardName ?? this.revealedCardName,
      revealedCardTemplateId:
          revealedCardTemplateId ?? this.revealedCardTemplateId,
      resultMessage: resultMessage ?? this.resultMessage,
      acknowledgedPlayerIds:
          acknowledgedPlayerIds ?? this.acknowledgedPlayerIds,
    );
  }
}
