import 'package:flutter/material.dart';

void main() {
  runApp(const ShadowHouseApp());
}

class ShadowHouseApp extends StatelessWidget {
  const ShadowHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shadow House: Masquerade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B2E8F),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class GameSetupRules {
  static int initialCardsForPlayerCount(int playerCount) {
    if (playerCount <= 4) {
      return 6;
    }

    return 7;
  }

  static int ghostCopiesForPlayerCount(int playerCount) {
    if (playerCount <= 4) {
      return 2;
    }

    return 3;
  }
}

class GameSetup {
  const GameSetup({
    required this.playerNames,
    required this.initialCards,
    required this.ghostCopies,
  });

  final List<String> playerNames;
  final int initialCards;
  final int ghostCopies;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ShadowBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.masks,
                    size: 72,
                    color: Color(0xFFE7C76F),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Shadow House',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Masquerade',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Color(0xFFE7C76F),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Ecos da Mansão',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 56),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SetupScreen(),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Nova Partida',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Configurações ainda serão implementadas.',
                            ),
                          ),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Configurações',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  int playerCount = 3;

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

    final initialCards =
    GameSetupRules.initialCardsForPlayerCount(playerCount);

    final ghostCopies =
    GameSetupRules.ghostCopiesForPlayerCount(playerCount);

    final setup = GameSetup(
      playerNames: playerNames,
      initialCards: initialCards,
      ghostCopies: ghostCopies,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(
          setup: setup,
          currentPlayerIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialCards =
    GameSetupRules.initialCardsForPlayerCount(playerCount);

    final ghostCopies =
    GameSetupRules.ghostCopiesForPlayerCount(playerCount);

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
                const SizedBox(height: 32),
                SetupSummaryCard(
                  playerCount: playerCount,
                  initialCards: initialCards,
                  ghostCopies: ghostCopies,
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

class SetupSummaryCard extends StatelessWidget {
  const SetupSummaryCard({
    super.key,
    required this.playerCount,
    required this.initialCards,
    required this.ghostCopies,
  });

  final int playerCount;
  final int initialCards;
  final int ghostCopies;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SetupSummaryRow(
              label: 'Jogadores',
              value: '$playerCount',
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Cartas iniciais',
              value: '$initialCards',
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Fantasmas do Visconde',
              value: '$ghostCopies',
            ),
            const Divider(),
            const SetupSummaryRow(
              label: 'Modo',
              value: 'Passa o celular',
            ),
          ],
        ),
      ),
    );
  }
}

class SetupSummaryRow extends StatelessWidget {
  const SetupSummaryRow({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFFE7C76F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class PassDeviceScreen extends StatelessWidget {
  const PassDeviceScreen({
    super.key,
    required this.setup,
    required this.currentPlayerIndex,
  });

  final GameSetup setup;
  final int currentPlayerIndex;

  @override
  Widget build(BuildContext context) {
    final currentPlayerName = setup.playerNames[currentPlayerIndex];

    return Scaffold(
      body: ShadowBackground(
        child: SafeArea(
          child: Center(
            child: Card(
              color: const Color(0xFF221229),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_android,
                      size: 64,
                      color: Color(0xFFE7C76F),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Passe o celular para',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPlayerName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${setup.initialCards} cartas iniciais • '
                          '${setup.ghostCopies} Fantasmas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Em breve: mão de $currentPlayerName',
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver minha mão',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShadowBackground extends StatelessWidget {
  const ShadowBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF120818),
            Color(0xFF261033),
            Color(0xFF08050A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }
}