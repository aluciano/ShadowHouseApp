class OnlinePlayer {
  const OnlinePlayer({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isReady,
  });

  final String id;
  final String name;
  final bool isHost;
  final bool isReady;
}
