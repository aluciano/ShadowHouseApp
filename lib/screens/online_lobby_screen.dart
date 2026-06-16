import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import '../repositories/local_online_membership_store.dart';
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

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen>
    with WidgetsBindingObserver {
  final membershipStore = createLocalOnlineMembershipStore();
  bool isStartingGame = false;
  bool isOpeningGame = false;
  bool isLeavingRoom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    markConnected();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      markConnected();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      markDisconnected();
    }
  }

  Future<void> markConnected() async {
    await RepositoryRegistry.onlineGame.updatePlayerConnection(
      roomId: widget.room.id,
      playerId: widget.currentPlayerId,
      isConnected: true,
    );
  }

  Future<void> markDisconnected() async {
    await RepositoryRegistry.onlineGame.updatePlayerConnection(
      roomId: widget.room.id,
      playerId: widget.currentPlayerId,
      isConnected: false,
    );
  }

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

  Future<void> leaveRoom(OnlineRoom room) async {
    if (isLeavingRoom) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da sala'),
          content: const Text(
            'Você sairá desta sala online. Se a partida já começou, deixará de participar imediatamente.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true || !mounted) {
      return;
    }

    setState(() {
      isLeavingRoom = true;
    });

    await RepositoryRegistry.onlineGame.leaveRoom(
      roomId: room.id,
      playerId: widget.currentPlayerId,
    );
    await membershipStore.clear();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> removeDisconnectedPlayer({
    required OnlineRoom room,
    required String actingPlayerId,
    required String removedPlayerId,
  }) async {
    await RepositoryRegistry.onlineGame.removePlayer(
      roomId: room.id,
      actingPlayerId: actingPlayerId,
      removedPlayerId: removedPlayerId,
    );
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          leaveRoom(widget.room);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lobby Online'),
          backgroundColor: const Color(0xFF120818),
          leading: IconButton(
            onPressed: () {
              leaveRoom(widget.room);
            },
            icon: const Icon(Icons.arrow_back),
          ),
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
                final currentPlayer = _playerById(room, widget.currentPlayerId);

                if (currentPlayer == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    membershipStore.clear();

                    if (!mounted) {
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Você não faz mais parte desta sala.'),
                      ),
                    );
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  });

                  return const SizedBox.shrink();
                }

                final host = room.players.firstWhere(
                  (player) => player.isHost,
                  orElse: () => currentPlayer,
                );
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
                                subtitle: Text(_roleAndStatusText(player)),
                                trailing: isHost &&
                                        player.id != currentPlayer.id &&
                                        !player.id
                                            .startsWith('placeholder_player_') &&
                                        !player.isConnected
                                    ? IconButton(
                                        tooltip:
                                            'Remover jogador desconectado',
                                        onPressed: () {
                                          removeDisconnectedPlayer(
                                            room: room,
                                            actingPlayerId: currentPlayer.id,
                                            removedPlayerId: player.id,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.person_remove,
                                          color: Color(0xFFE7C76F),
                                        ),
                                      )
                                    : Icon(
                                        player.isConnected
                                            ? Icons.check_circle
                                            : Icons.wifi_off,
                                        color: player.isConnected
                                            ? const Color(0xFFE7C76F)
                                            : Colors.white54,
                                      ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      color: const Color(0xFF120818),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              host.isConnected
                                  ? Icons.workspace_premium
                                  : Icons.wifi_off,
                              color: const Color(0xFFE7C76F),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                host.isConnected
                                    ? '${host.name} é o anfitrião atual.'
                                    : '${host.name} está desconectado. Um novo anfitrião será assumido automaticamente por outro jogador disponível.',
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
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                                  'Aguardando ${host.name} iniciar a partida.',
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
                      onPressed: isLeavingRoom ? null : () => leaveRoom(room),
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
      ),
    );
  }

  OnlinePlayer? _playerById(OnlineRoom room, String playerId) {
    for (final player in room.players) {
      if (player.id == playerId) {
        return player;
      }
    }

    return null;
  }

  String _roleAndStatusText(OnlinePlayer player) {
    return [
      player.isHost ? 'Anfitrião' : 'Convidado',
      player.isConnected ? 'conectado' : 'desconectado',
    ].join(' • ');
  }
}
