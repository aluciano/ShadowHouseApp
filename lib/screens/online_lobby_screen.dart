import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/online_room.dart';
import '../widgets/shadow_background.dart';

class OnlineLobbyScreen extends StatelessWidget {
  const OnlineLobbyScreen({
    super.key,
    required this.room,
    required this.currentPlayerId,
  });

  final OnlineRoom room;
  final String currentPlayerId;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = room.players.firstWhere(
      (player) => player.id == currentPlayerId,
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
                room.code,
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
                        GameSetupRules.titleForMode(room.gameMode),
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        GameSetupRules.descriptionForMode(room.gameMode),
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
                        'Jogadores (${room.players.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE7C76F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...room.players.map((player) {
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            player.isHost
                                ? Icons.workspace_premium
                                : Icons.person,
                            color: player.id == currentPlayerId
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
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'O inicio online sera conectado ao Firebase na proxima etapa.',
                            ),
                          ),
                        );
                      }
                    : null,
                icon: const Icon(Icons.play_arrow),
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
