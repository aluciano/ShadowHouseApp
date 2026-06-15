import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_mode.dart';
import '../models/game_setup.dart';
import '../models/game_state.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import '../models/online_game_session.dart';
import '../models/online_pending_effect.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import '../models/player.dart';
import '../models/player_type.dart';
import '../models/round_result.dart';
import '../models/round_result_type.dart';

Map<String, Object?> onlinePlayerToFirestore(OnlinePlayer player) {
  return {
    'id': player.id,
    'name': player.name,
    'isHost': player.isHost,
    'isReady': player.isReady,
  };
}

OnlinePlayer onlinePlayerFromFirestore(Map<String, dynamic> data) {
  return OnlinePlayer(
    id: data['id'] as String,
    name: data['name'] as String,
    isHost: data['isHost'] as bool? ?? false,
    isReady: data['isReady'] as bool? ?? false,
  );
}

Map<String, Object?> onlineRoomToFirestore(OnlineRoom room) {
  return {
    'code': room.code,
    'hostPlayerId': room.hostPlayerId,
    'players': room.players.map(onlinePlayerToFirestore).toList(),
    'gameMode': room.gameMode.name,
    'createdAt': Timestamp.fromDate(room.createdAt),
    'status': room.status.name,
    'currentPlayerId': room.currentPlayerId,
  };
}

OnlineRoom onlineRoomFromFirestore({
  required String id,
  required Map<String, dynamic> data,
}) {
  final players = (data['players'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(onlinePlayerFromFirestore)
      .toList();

  return OnlineRoom(
    id: id,
    code: data['code'] as String,
    hostPlayerId: data['hostPlayerId'] as String,
    players: players,
    gameMode: _enumByName(
      GameMode.values,
      data['gameMode'] as String?,
      GameMode.expansionBalanced,
    ),
    createdAt: _dateTimeFromFirestore(data['createdAt']),
    status: _enumByName(
      OnlineRoomStatus.values,
      data['status'] as String?,
      OnlineRoomStatus.waiting,
    ),
    currentPlayerId: data['currentPlayerId'] as String?,
  );
}

Map<String, Object?> matchHistoryEntryToFirestore(MatchHistoryEntry entry) {
  return {
    'playMode': entry.playMode.name,
    'gameMode': entry.gameMode.name,
    'startedAt': Timestamp.fromDate(entry.startedAt),
    'finishedAt': Timestamp.fromDate(entry.finishedAt),
    'playerNames': entry.playerNames,
    'winnerNames': entry.winnerNames,
    'roundsPlayed': entry.roundsPlayed,
    'roomCode': entry.roomCode,
  };
}

MatchHistoryEntry matchHistoryEntryFromFirestore({
  required String id,
  required Map<String, dynamic> data,
}) {
  return MatchHistoryEntry(
    id: id,
    playMode: _enumByName(
      MatchPlayMode.values,
      data['playMode'] as String?,
      MatchPlayMode.online,
    ),
    gameMode: _enumByName(
      GameMode.values,
      data['gameMode'] as String?,
      GameMode.expansionBalanced,
    ),
    startedAt: _dateTimeFromFirestore(data['startedAt']),
    finishedAt: _dateTimeFromFirestore(data['finishedAt']),
    playerNames: List<String>.from(data['playerNames'] as List<dynamic>? ?? []),
    winnerNames: List<String>.from(data['winnerNames'] as List<dynamic>? ?? []),
    roundsPlayed: data['roundsPlayed'] as int? ?? 0,
    roomCode: data['roomCode'] as String?,
  );
}

Map<String, Object?> onlineGameSessionToFirestore(
  OnlineGameSession session,
) {
  return {
    'room': onlineRoomToFirestore(session.room),
    'gameState': gameStateToFirestore(session.gameState),
    'startedAt': Timestamp.fromDate(session.startedAt),
    'roundsPlayed': session.roundsPlayed,
    'rematchProposalPlayerIds': session.rematchProposalPlayerIds,
    'nextRoundReadyPlayerIds': session.nextRoundReadyPlayerIds,
    'pendingEffect': session.pendingEffect == null
        ? null
        : onlinePendingEffectToFirestore(session.pendingEffect!),
  };
}

OnlineGameSession onlineGameSessionFromFirestore({
  required OnlineRoom room,
  required Map<String, dynamic> data,
}) {
  return OnlineGameSession(
    room: room,
    gameState: gameStateFromFirestore(
      data['gameState'] as Map<String, dynamic>,
    ),
    startedAt: _dateTimeFromFirestore(data['startedAt']),
    roundsPlayed: data['roundsPlayed'] as int? ?? 1,
    rematchProposalPlayerIds: List<String>.from(
      data['rematchProposalPlayerIds'] as List<dynamic>? ?? [],
    ),
    nextRoundReadyPlayerIds: List<String>.from(
      data['nextRoundReadyPlayerIds'] as List<dynamic>? ?? [],
    ),
    pendingEffect: data['pendingEffect'] == null
        ? null
        : onlinePendingEffectFromFirestore(
            data['pendingEffect'] as Map<String, dynamic>,
          ),
  );
}

Map<String, Object?> onlinePendingEffectToFirestore(
  OnlinePendingEffect effect,
) {
  return {
    'type': effect.type.name,
    'actingPlayerId': effect.actingPlayerId,
    'cardName': effect.cardName,
    'targetPlayerId': effect.targetPlayerId,
    'resultMessage': effect.resultMessage,
    'acknowledgedPlayerIds': effect.acknowledgedPlayerIds,
  };
}

OnlinePendingEffect onlinePendingEffectFromFirestore(
  Map<String, dynamic> data,
) {
  return OnlinePendingEffect(
    type: _enumByName(
      OnlineEffectType.values,
      data['type'] as String?,
      OnlineEffectType.detective,
    ),
    actingPlayerId: data['actingPlayerId'] as String,
    cardName: data['cardName'] as String? ?? 'Efeito',
    targetPlayerId: data['targetPlayerId'] as String?,
    resultMessage: data['resultMessage'] as String?,
    acknowledgedPlayerIds: List<String>.from(
      data['acknowledgedPlayerIds'] as List<dynamic>? ?? [],
    ),
  );
}

Map<String, Object?> gameStateToFirestore(GameState gameState) {
  return {
    'setup': gameSetupToFirestore(gameState.setup),
    'players': gameState.players.map(playerToFirestore).toList(),
    'deck': gameState.deck.map(gameCardToFirestore).toList(),
    'currentPlayerIndex': gameState.currentPlayerIndex,
    'initialDeckSize': gameState.initialDeckSize,
    'roundFinished': gameState.roundFinished,
    'roundResult': gameState.roundResult == null
        ? null
        : roundResultToFirestore(gameState.roundResult!),
  };
}

GameState gameStateFromFirestore(Map<String, dynamic> data) {
  final players = (data['players'] as List<dynamic>? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(playerFromFirestore)
      .toList();

  return GameState(
    setup: gameSetupFromFirestore(data['setup'] as Map<String, dynamic>),
    players: players,
    deck: (data['deck'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(gameCardFromFirestore)
        .toList(),
    currentPlayerIndex: data['currentPlayerIndex'] as int? ?? 0,
    initialDeckSize: data['initialDeckSize'] as int? ?? 0,
    roundFinished: data['roundFinished'] as bool? ?? false,
    roundResult: data['roundResult'] == null
        ? null
        : roundResultFromFirestore(
            data['roundResult'] as Map<String, dynamic>,
            players,
          ),
  );
}

Map<String, Object?> gameSetupToFirestore(GameSetup setup) {
  return {
    'playerNames': setup.playerNames,
    'gameMode': setup.gameMode.name,
    'initialCards': setup.initialCards,
    'ghostCopies': setup.ghostCopies,
    'extraSilenceCopies': setup.extraSilenceCopies,
    'extraSealedCardCopies': setup.extraSealedCardCopies,
  };
}

GameSetup gameSetupFromFirestore(Map<String, dynamic> data) {
  return GameSetup(
    playerNames: List<String>.from(data['playerNames'] as List<dynamic>? ?? []),
    gameMode: _enumByName(
      GameMode.values,
      data['gameMode'] as String?,
      GameMode.expansionBalanced,
    ),
    initialCards: data['initialCards'] as int? ?? 4,
    ghostCopies: data['ghostCopies'] as int? ?? 0,
    extraSilenceCopies: data['extraSilenceCopies'] as int? ?? 0,
    extraSealedCardCopies: data['extraSealedCardCopies'] as int? ?? 0,
  );
}

Map<String, Object?> playerToFirestore(Player player) {
  return {
    'id': player.id,
    'name': player.name,
    'type': player.type.name,
    'hand': player.hand.map(gameCardToFirestore).toList(),
    'playedCards': player.playedCards.map(gameCardToFirestore).toList(),
    'score': player.score,
    'isAccomplice': player.isAccomplice,
    'hasHandcuffs': player.hasHandcuffs,
  };
}

Player playerFromFirestore(Map<String, dynamic> data) {
  return Player(
    id: data['id'] as String,
    name: data['name'] as String,
    type: _enumByName(
      PlayerType.values,
      data['type'] as String?,
      PlayerType.remoteHuman,
    ),
    hand: (data['hand'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(gameCardFromFirestore)
        .toList(),
    playedCards: (data['playedCards'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(gameCardFromFirestore)
        .toList(),
    score: data['score'] as int? ?? 0,
    isAccomplice: data['isAccomplice'] as bool? ?? false,
    hasHandcuffs: data['hasHandcuffs'] as bool? ?? false,
  );
}

Map<String, Object?> gameCardToFirestore(GameCard card) {
  return {
    'id': card.id,
    'templateId': card.templateId,
    'name': card.name,
    'type': card.type.name,
    'shortText': card.shortText,
    'wasDiscarded': card.wasDiscarded,
  };
}

GameCard gameCardFromFirestore(Map<String, dynamic> data) {
  return GameCard(
    id: data['id'] as String,
    templateId: data['templateId'] as String,
    name: data['name'] as String,
    type: _enumByName(
      CardType.values,
      data['type'] as String?,
      CardType.special,
    ),
    shortText: data['shortText'] as String,
    wasDiscarded: data['wasDiscarded'] as bool? ?? false,
  );
}

Map<String, Object?> roundResultToFirestore(RoundResult result) {
  return {
    'type': result.type.name,
    'winnerPlayerId': result.winner?.id,
    'reason': result.reason,
    'scoringSummary': result.scoringSummary,
    'roundPointsByPlayerId': result.roundPointsByPlayerId,
  };
}

RoundResult roundResultFromFirestore(
  Map<String, dynamic> data,
  List<Player> players,
) {
  final winnerPlayerId = data['winnerPlayerId'] as String?;

  return RoundResult(
    type: _enumByName(
      RoundResultType.values,
      data['type'] as String?,
      RoundResultType.guiltyWins,
    ),
    winner: winnerPlayerId == null
        ? null
        : _playerByIdOrNull(players, winnerPlayerId),
    reason: data['reason'] as String? ?? '',
    scoringSummary: data['scoringSummary'] as String? ?? '',
    roundPointsByPlayerId: Map<String, int>.from(
      data['roundPointsByPlayerId'] as Map<String, dynamic>? ?? {},
    ),
  );
}

Player? _playerByIdOrNull(List<Player> players, String playerId) {
  for (final player in players) {
    if (player.id == playerId) {
      return player;
    }
  }

  return null;
}

DateTime _dateTimeFromFirestore(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.now();
}

T _enumByName<T extends Enum>(
  List<T> values,
  String? name,
  T fallback,
) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }

  return fallback;
}
