class OnlinePlayer {
  const OnlinePlayer({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isReady,
    this.isConnected = true,
    required this.lastSeenAt,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool isReady;
  final bool isConnected;
  final DateTime lastSeenAt;

  OnlinePlayer copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isReady,
    bool? isConnected,
    DateTime? lastSeenAt,
  }) {
    return OnlinePlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isReady: isReady ?? this.isReady,
      isConnected: isConnected ?? this.isConnected,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }
}
