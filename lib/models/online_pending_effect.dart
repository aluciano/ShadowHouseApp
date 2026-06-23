import 'game_card.dart';

enum OnlineEffectType {
  detective,
  toto,
  handcuffs,
  accomplice,
  poisonedCup,
  witness,
  familyBaby,
  publicNotice,
  protectionCancel,
  swap,
  share,
  rumors,
  frenzy,
  butler,
  portrait,
  spy,
  brokenMask,
  unfinishedBusiness,
  lullaby,
  sealedCard,
  secretOath,
  silence,
  betrayal,
  threeDestinies,
  ghostCopy,
  pianoSetup,
  pianoExecution,
}

class OnlinePendingEffect {
  const OnlinePendingEffect({
    required this.type,
    required this.actingPlayerId,
    required this.cardName,
    this.resolverPlayerId,
    this.allowSelfTarget = false,
    this.targetPlayerId,
    this.revealedCardId,
    this.revealedCardName,
    this.revealedCardTemplateId,
    this.secondaryCardId,
    this.secondaryCardName,
    this.secondaryCardTemplateId,
    this.participantPlayerIds = const [],
    this.completedPlayerIds = const [],
    this.selectedCardIdsByPlayerId = const {},
    this.selectedCardNamesByPlayerId = const {},
    this.receivedCardCountByPlayerId = const {},
    this.receivedCardNamesByPlayerId = const {},
    this.previewCardNames = const [],
    this.offeredCards = const [],
    this.resultMessage,
    this.acknowledgedPlayerIds = const [],
  });

  final OnlineEffectType type;
  final String actingPlayerId;
  final String cardName;
  final String? resolverPlayerId;
  final bool allowSelfTarget;
  final String? targetPlayerId;
  final String? revealedCardId;
  final String? revealedCardName;
  final String? revealedCardTemplateId;
  final String? secondaryCardId;
  final String? secondaryCardName;
  final String? secondaryCardTemplateId;
  final List<String> participantPlayerIds;
  final List<String> completedPlayerIds;
  final Map<String, String> selectedCardIdsByPlayerId;
  final Map<String, String> selectedCardNamesByPlayerId;
  final Map<String, int> receivedCardCountByPlayerId;
  final Map<String, String> receivedCardNamesByPlayerId;
  final List<String> previewCardNames;
  final List<GameCard> offeredCards;
  final String? resultMessage;
  final List<String> acknowledgedPlayerIds;

  bool get wasResolved => targetPlayerId != null && resultMessage != null;

  OnlinePendingEffect copyWith({
    OnlineEffectType? type,
    String? actingPlayerId,
    String? cardName,
    String? resolverPlayerId,
    bool? allowSelfTarget,
    String? targetPlayerId,
    String? revealedCardId,
    String? revealedCardName,
    String? revealedCardTemplateId,
    String? secondaryCardId,
    String? secondaryCardName,
    String? secondaryCardTemplateId,
    List<String>? participantPlayerIds,
    List<String>? completedPlayerIds,
    Map<String, String>? selectedCardIdsByPlayerId,
    Map<String, String>? selectedCardNamesByPlayerId,
    Map<String, int>? receivedCardCountByPlayerId,
    Map<String, String>? receivedCardNamesByPlayerId,
    List<String>? previewCardNames,
    List<GameCard>? offeredCards,
    String? resultMessage,
    List<String>? acknowledgedPlayerIds,
  }) {
    return OnlinePendingEffect(
      type: type ?? this.type,
      actingPlayerId: actingPlayerId ?? this.actingPlayerId,
      cardName: cardName ?? this.cardName,
      resolverPlayerId: resolverPlayerId ?? this.resolverPlayerId,
      allowSelfTarget: allowSelfTarget ?? this.allowSelfTarget,
      targetPlayerId: targetPlayerId ?? this.targetPlayerId,
      revealedCardId: revealedCardId ?? this.revealedCardId,
      revealedCardName: revealedCardName ?? this.revealedCardName,
      revealedCardTemplateId:
          revealedCardTemplateId ?? this.revealedCardTemplateId,
      secondaryCardId: secondaryCardId ?? this.secondaryCardId,
      secondaryCardName: secondaryCardName ?? this.secondaryCardName,
      secondaryCardTemplateId:
          secondaryCardTemplateId ?? this.secondaryCardTemplateId,
      participantPlayerIds: participantPlayerIds ?? this.participantPlayerIds,
      completedPlayerIds: completedPlayerIds ?? this.completedPlayerIds,
      selectedCardIdsByPlayerId:
          selectedCardIdsByPlayerId ?? this.selectedCardIdsByPlayerId,
      selectedCardNamesByPlayerId:
          selectedCardNamesByPlayerId ?? this.selectedCardNamesByPlayerId,
      receivedCardCountByPlayerId:
          receivedCardCountByPlayerId ?? this.receivedCardCountByPlayerId,
      receivedCardNamesByPlayerId:
          receivedCardNamesByPlayerId ?? this.receivedCardNamesByPlayerId,
      previewCardNames: previewCardNames ?? this.previewCardNames,
      offeredCards: offeredCards ?? this.offeredCards,
      resultMessage: resultMessage ?? this.resultMessage,
      acknowledgedPlayerIds:
          acknowledgedPlayerIds ?? this.acknowledgedPlayerIds,
    );
  }
}
