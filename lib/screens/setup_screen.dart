import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../engine/game_engine.dart';
import '../models/game_mode.dart';
import '../models/game_setup.dart';
import '../widgets/game_mode_option_card.dart';
import '../widgets/setup_summary_card.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playerCount = 3;
  GameMode selectedGameMode = GameMode.expansionBalanced;

  late List<TextEditingController> playerNameControllers;

  @override
  void initState() {
    super.initState();

    playerNameControllers = List.generate(
      playerCount,
          (index) => TextEditingController(text: 'Jogador ${index + 1}'),
    );
  }

  @override
  void dispose() {
    for (final controller in playerNameControllers) {
      controller.dispose();
    }

    super.dispose();
  }

  void updatePlayerCount(int newCount) {
    setState(() {
      if (newCount > playerNameControllers.length) {
        for (int i = playerNameControllers.length; i < newCount; i++) {
          playerNameControllers.add(
            TextEditingController(text: 'Jogador ${i + 1}'),
          );
        }
      } else if (newCount < playerNameControllers.length) {
        final removedControllers = playerNameControllers.sublist(newCount);

        for (final controller in removedControllers) {
          controller.dispose();
        }

        playerNameControllers = playerNameControllers.sublist(0, newCount);
      }

      playerCount = newCount;
    });
  }

  void startGame() {
    final playerNames = playerNameControllers
        .map((controller) => controller.text.trim())
        .where((name) => name.isNotEmpty)
        .toList();

    if (playerNames.length != playerCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha o nome de todos os jogadores.'),
        ),
      );

      return;
    }

    final recommendation = GameSetupRules.recommendation(
      playerCount: playerCount,
      gameMode: selectedGameMode,
    );

    final setup = GameSetup(
      playerNames: playerNames,
      gameMode: selectedGameMode,
      initialCards: recommendation.initialCards,
      ghostCopies: recommendation.ghostCopies,
      extraSilenceCopies: recommendation.extraSilenceCopies,
      extraSealedCardCopies: recommendation.extraSealedCardCopies,
    );

    final gameState = createInitialGameState(setup);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(
          gameState: gameState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recommendation = GameSetupRules.recommendation(
      playerCount: playerCount,
      gameMode: selectedGameMode,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Partida'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Configuração da Partida',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Modo passa o celular',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Modo de jogo',
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
                const SizedBox(height: 24),
                const Text(
                  'Quantidade de jogadores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 8,
                  children: List.generate(6, (index) {
                    final count = index + 3;
                    final selected = count == playerCount;

                    return ChoiceChip(
                      label: Text('$count'),
                      selected: selected,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => updatePlayerCount(count),
                    );
                  }),
                ),
                const SizedBox(height: 24),
                SetupSummaryCard(
                  playerCount: playerCount,
                  gameMode: selectedGameMode,
                  recommendation: recommendation,
                ),
                const SizedBox(height: 32),
                const Text(
                  'Jogadores',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(playerCount, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TextField(
                      controller: playerNameControllers[index],
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(
                        labelText: 'Jogador ${index + 1}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: startGame,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Iniciar Partida',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}