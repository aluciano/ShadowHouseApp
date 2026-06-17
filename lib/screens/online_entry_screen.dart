import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/game_mode.dart';
import '../models/saved_online_room_membership.dart';
import '../models/online_room.dart';
import '../models/online_room_status.dart';
import '../repositories/local_online_membership_store.dart';
import '../repositories/repository_registry.dart';
import '../widgets/game_mode_option_card.dart';
import '../widgets/shadow_background.dart';
import 'online_game_screen.dart';
import 'online_lobby_screen.dart';

class OnlineEntryScreen extends StatefulWidget {
  const OnlineEntryScreen({super.key});

  @override
  State<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends State<OnlineEntryScreen> {
  final membershipStore = createLocalOnlineMembershipStore();
  final playerNameController = TextEditingController(text: 'Jogador');
  final roomCodeController = TextEditingController();

  GameMode selectedGameMode = GameMode.expansionBalanced;
  SavedOnlineRoomMembership? savedMembership;
  bool isCreatingTab = true;
  bool isCreatingRoom = false;
  bool isJoiningRoom = false;
  bool isResumingRoom = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    resumeSavedRoomIfPossible();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    playerNameController.dispose();
    roomCodeController.dispose();

    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _OnlineEntryLifecycleObserver(
        onResumed: () {
          if (!isResumingRoom && savedMembership != null) {
            resumeSavedRoomIfPossible(showErrorMessage: false);
          }
        },
      );

  Future<void> resumeSavedRoomIfPossible({
    bool showErrorMessage = false,
  }) async {
    if (isResumingRoom) {
      return;
    }

    setState(() {
      isResumingRoom = true;
    });

    final membership = await membershipStore.load();

    if (!mounted) {
      return;
    }

    savedMembership = membership;

    if (membership == null) {
      setState(() {
        isResumingRoom = false;
      });
      return;
    }

    try {
      final room = await RepositoryRegistry.onlineGame.reconnectToRoom(
        roomId: membership.roomId,
        playerId: membership.playerId,
      );

      if (!mounted) {
        return;
      }

      if (room.status == OnlineRoomStatus.inProgress) {
        final session = await RepositoryRegistry.onlineGame.loadCurrentSession(
          room,
        );

        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OnlineGameScreen(
              session: session,
              currentPlayerId: membership.playerId,
            ),
          ),
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OnlineLobbyScreen(
            room: room,
            currentPlayerId: membership.playerId,
          ),
        ),
      );
      return;
    } catch (_) {
      await membershipStore.clear();
      if (mounted) {
        savedMembership = null;
        if (showErrorMessage) {
          showMessage('Não foi possível retomar sua última sala.');
        }
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isResumingRoom = false;
    });
  }

  Future<void> createRoom() async {
    final playerName = playerNameController.text.trim();

    if (playerName.isEmpty) {
      showMessage('Informe seu nome para criar uma sala.');
      return;
    }

    setState(() {
      isCreatingRoom = true;
    });

    late final OnlineRoom room;

    try {
      room = await RepositoryRegistry.onlineGame.createRoom(
        hostName: playerName,
        gameMode: selectedGameMode,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isCreatingRoom = false;
      });
      showMessage(error.toString());
      return;
    }

    if (!mounted) {
      return;
    }

    await membershipStore.save(
      SavedOnlineRoomMembership(
        roomId: room.id,
        roomCode: room.code,
        playerId: room.hostPlayerId,
      ),
    );
    savedMembership = SavedOnlineRoomMembership(
      roomId: room.id,
      roomCode: room.code,
      playerId: room.hostPlayerId,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isCreatingRoom = false;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineLobbyScreen(
          room: room,
          currentPlayerId: room.hostPlayerId,
        ),
      ),
    );
  }

  Future<void> joinRoom() async {
    final playerName = playerNameController.text.trim();
    final roomCode = roomCodeController.text.trim();

    if (playerName.isEmpty) {
      showMessage('Informe seu nome para entrar em uma sala.');
      return;
    }

    if (roomCode.isEmpty) {
      showMessage('Informe o código da sala.');
      return;
    }

    setState(() {
      isJoiningRoom = true;
    });

    late final OnlineRoom room;

    try {
      room = await RepositoryRegistry.onlineGame.joinRoom(
        roomCode: roomCode,
        playerName: playerName,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isJoiningRoom = false;
      });
      showMessage(error.toString());
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isJoiningRoom = false;
    });

    final currentPlayer = room.players.firstWhere(
      (player) => player.name.trim().toLowerCase() == playerName.toLowerCase(),
      orElse: () => room.players.last,
    );

    await membershipStore.save(
      SavedOnlineRoomMembership(
        roomId: room.id,
        roomCode: room.code,
        playerId: currentPlayer.id,
      ),
    );
    savedMembership = SavedOnlineRoomMembership(
      roomId: room.id,
      roomCode: room.code,
      playerId: currentPlayer.id,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OnlineLobbyScreen(
          room: room,
          currentPlayerId: currentPlayer.id,
        ),
      ),
    );
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partida Online'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            children: [
              if (isResumingRoom) ...[
                const Card(
                  color: Color(0xFF221229),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tentando retomar sua última sala online...',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (savedMembership != null) ...[
                Card(
                  color: const Color(0xFF221229),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Última sala: ${savedMembership!.roomCode}',
                          style: const TextStyle(
                            color: Color(0xFFE7C76F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Você ainda pode tentar voltar para sua última partida online.',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () {
                            resumeSavedRoomIfPossible(showErrorMessage: true);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Retomar última sala'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text(
                'Partida Online',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie uma sala ou entre com um código compartilhado.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    icon: Icon(Icons.add),
                    label: Text('Criar'),
                  ),
                  ButtonSegment(
                    value: false,
                    icon: Icon(Icons.login),
                    label: Text('Entrar'),
                  ),
                ],
                selected: {isCreatingTab},
                onSelectionChanged: (selection) {
                  setState(() {
                    isCreatingTab = selection.first;
                  });
                },
              ),
              const SizedBox(height: 24),
              TextField(
                controller: playerNameController,
                textCapitalization: TextCapitalization.words,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Seu nome',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 28),
              if (isCreatingTab) ...[
                const Text(
                  'Modo da sala',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...GameMode.values.map((mode) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GameModeOptionCard(
                      title: GameSetupRules.titleForMode(mode),
                      description: GameSetupRules.descriptionForMode(mode),
                      selected: selectedGameMode == mode,
                      onTap: () {
                        setState(() {
                          selectedGameMode = mode;
                        });
                      },
                    ),
                  );
                }),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: isCreatingRoom ? null : createRoom,
                  icon: isCreatingRoom
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Criar Sala',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: roomCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código da sala',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: isJoiningRoom ? null : joinRoom,
                  icon: isJoiningRoom
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Entrar na Sala',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OnlineEntryLifecycleObserver extends WidgetsBindingObserver {
  _OnlineEntryLifecycleObserver({
    required this.onResumed,
  });

  final VoidCallback onResumed;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResumed();
    }
  }
}
