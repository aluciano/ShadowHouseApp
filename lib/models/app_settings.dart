class AppSettings {
  const AppSettings({
    this.playerName = 'Jogador',
  });

  final String playerName;

  Map<String, String> toJson() {
    return {'playerName': playerName};
  }

  static AppSettings fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const AppSettings();
    }

    final playerName = json['playerName'];

    return AppSettings(
      playerName: playerName is String && playerName.trim().isNotEmpty
          ? playerName.trim()
          : 'Jogador',
    );
  }
}
