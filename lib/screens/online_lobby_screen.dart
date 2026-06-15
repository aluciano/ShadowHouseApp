import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/online_game_session.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
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
  bool isOpeningGame = false;

  Future<void> startGame(OnlineRoom room) async {
    setState(() {
      isStartingGame = true;
    });

    final session = await RepositoryRegistry.onlineGame.startGame(room);

    if (!mounted) {
      return;
    }

    setState(() {
      isStartingGame = false;
    });

    openGame(session);
  }

  Future<void> openStartedRoom(OnlineRoom room) async {
    if (isOpeningGame) {
      return;
    }

    isOpeningGame = true;

    try {
      final session = await RepositoryRegistry.onlineGame.loadCurrentSession(
        room,
      );

      if (!mounted) {
        return;
      }

      openGame(session);
    } catch (error) {
      if (!mounted) {
        return;
      }

      isOpeningGame = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void openGame(OnlineGameSession session) {
    if (!isOpeningGame) {
      isOpeningGame = true;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          session: session,
          currentPlayerId: widget.currentPlayerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lobby Online'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: StreamBuilder<OnlineRoom>(
            stream: RepositoryRegistry.onlineGame.watchRoom(widget.room.id),
            initialData: widget.room,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Não foi possível atualizar a sala: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                );
              }

              final room = snapshot.data ?? widget.room;

              final currentPlayer = room.players.firstWhere(
                (player) => player.id == widget.currentPlayerId,
                orElse: () => room.players.first,
              );
              final hostName =
                  room.players.firstWhere((player) => player.isHost).name;
              final isHost = currentPlayer.isHost;
              final isGameInProgress =
                  room.status == OnlineRoomStatus.inProgress;

              if (isGameInProgress) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    openStartedRoom(room);
                  }
                });
              }

              return ListView(
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
                    'Compartilhe este código com os outros jogadores.',
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
                            'Configuração',
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
                                color: player.id == widget.currentPlayerId
                                    ? const Color(0xFFE7C76F)
                                    : Colors.white70,
                              ),
                              title: Text(player.name),
                              subtitle: Text(
                                player.isHost ? 'Anfitrião' : 'Convidado',
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
                  if (isGameInProgress)
                    Card(
                      color: const Color(0xFF120818),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Abrindo a partida...',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (isHost)
                    FilledButton.icon(
                      onPressed: isStartingGame ? null : () => startGame(room),
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
                    )
                  else
                    Card(
                      color: const Color(0xFF120818),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.hourglass_empty,
                              color: Color(0xFFE7C76F),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Aguardando $hostName iniciar a partida.',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
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
              );
            },
          ),
        ),
      ),
    );
  }
}
