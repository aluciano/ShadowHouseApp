class SavedOnlineRoomMembership {
  const SavedOnlineRoomMembership({
    required this.roomId,
    required this.roomCode,
    required this.playerId,
  });

  final String roomId;
  final String roomCode;
  final String playerId;

  Map<String, String> toJson() {
    return {
      'roomId': roomId,
      'roomCode': roomCode,
      'playerId': playerId,
    };
  }

  static SavedOnlineRoomMembership? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    final roomId = json['roomId'];
    final roomCode = json['roomCode'];
    final playerId = json['playerId'];

    if (roomId is! String || roomCode is! String || playerId is! String) {
      return null;
    }

    return SavedOnlineRoomMembership(
      roomId: roomId,
      roomCode: roomCode,
      playerId: playerId,
    );
  }
}
