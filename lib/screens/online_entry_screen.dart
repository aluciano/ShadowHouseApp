import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/game_mode.dart';
import '../repositories/repository_registry.dart';
import '../widgets/game_mode_option_card.dart';
import '../widgets/shadow_background.dart';
import 'online_lobby_screen.dart';

class OnlineEntryScreen extends StatefulWidget {
  const OnlineEntryScreen({super.key});

  @override
  State<OnlineEntryScreen> createState() => _OnlineEntryScreenState();
}

class _OnlineEntryScreenState extends State<OnlineEntryScreen> {
  final playerNameController = TextEditingController(text: 'Jogador');
  final roomCodeController = TextEditingController();

  GameMode selectedGameMode = GameMode.expansionBalanced;
  bool isCreatingRoom = false;
  bool isJoiningRoom = false;

  @override
  void dispose() {
    playerNameController.dispose();
    roomCodeController.dispose();

    super.dispose();
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

    final room = await RepositoryRegistry.onlineGame.createRoom(
      hostName: playerName,
      gameMode: selectedGameMode,
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
      showMessage('Informe o codigo da sala.');
      return;
    }

    setState(() {
      isJoiningRoom = true;
    });

    final room = await RepositoryRegistry.onlineGame.joinRoom(
      roomCode: roomCode,
      playerName: playerName,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      isJoiningRoom = false;
    });

    final currentPlayer = room.players.last;

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
              const Text(
                'Partida Online',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Crie uma sala ou entre com um codigo compartilhado.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
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
              const SizedBox(height: 28),
              const Divider(),
              const SizedBox(height: 20),
              TextField(
                controller: roomCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Codigo da sala',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
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
          ),
        ),
      ),
    );
  }
}
