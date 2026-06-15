import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/online_room.dart';
import '../repositories/repository_registry.dart';
import '../widgets/shadow_background.dart';
import 'online_game_screen.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({
    super.key,
    required this.room,
    required this.currentPlayerId,
  });

  final OnlineRoom room;
  final String currentPlayerId;

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  bool isStartingGame = false;

  Future<void> startGame() async {
    setState(() {
      isStartingGame = true;
    });

    final session = await RepositoryRegistry.onlineGame.startGame(
      widget.room,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isStartingGame = false;
    });

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          session: session,
          initialViewedPlayerId: session.gameState.currentPlayer.id,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPlayer = widget.room.players.firstWhere(
      (player) => player.id == widget.currentPlayerId,
    );
    final isHost = currentPlayer.isHost;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby Online'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            children: [
              const Icon(
                Icons.groups,
                size: 72,
                color: Color(0xFFE7C76F),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sala criada',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.room.code,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 36,
                  color: Color(0xFFE7C76F),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Compartilhe este codigo com os outros jogadores.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 28),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuracao',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        GameSetupRules.titleForMode(widget.room.gameMode),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GameSetupRules.descriptionForMode(
                          widget.room.gameMode,
                        ),
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                color: const Color(0xFF221229),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jogadores (${widget.room.players.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...widget.room.players.map((player) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            player.isHost
                                ? Icons.workspace_premium
                                : Icons.person,
                            color: player.id == widget.currentPlayerId
                                ? const Color(0xFFE7C76F)
                                : Colors.white70,
                          ),
                          title: Text(player.name),
                          subtitle: Text(
                            player.isHost ? 'Anfitriao' : 'Convidado',
                          ),
                          trailing: Icon(
                            player.isReady
                                ? Icons.check_circle
                                : Icons.hourglass_empty,
                            color: player.isReady
                                ? const Color(0xFFE7C76F)
                                : Colors.white54,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isHost
                    ? isStartingGame
                        ? null
                        : startGame
                    : null,
                icon: isStartingGame
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Iniciar Partida Online',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Voltar ao Menu Inicial',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
