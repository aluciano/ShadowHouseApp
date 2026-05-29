import 'dart:math';
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

enum GameMode {
  original,
  expansionBalanced,
  expansionFullHand,
}

class GameSetupRecommendation {
  const GameSetupRecommendation({
    required this.initialCards,
    required this.ghostCopies,
    required this.extraSilenceCopies,
    required this.extraSealedCardCopies,
  });

  final int initialCards;
  final int ghostCopies;
  final int extraSilenceCopies;
  final int extraSealedCardCopies;
}

class GameSetupRules {
  static GameSetupRecommendation recommendation({
    required int playerCount,
    required GameMode gameMode,
  }) {
    switch (gameMode) {
      case GameMode.original:
        return const GameSetupRecommendation(
          initialCards: 4,
          ghostCopies: 0,
          extraSilenceCopies: 0,
          extraSealedCardCopies: 0,
        );

      case GameMode.expansionBalanced:
        return GameSetupRecommendation(
          initialCards: playerCount <= 6 ? 4 : 5,
          ghostCopies: switch (playerCount) {
            3 => 1,
            4 => 1,
            5 => 4,
            6 => 2,
            7 => 1,
            8 => 2,
            _ => 1,
          },
          extraSilenceCopies: 0,
          extraSealedCardCopies: 0,
        );

      case GameMode.expansionFullHand:
        return GameSetupRecommendation(
          initialCards: 6,
          ghostCopies: playerCount >= 7 ? 2 : 1,
          extraSilenceCopies: 1,
          extraSealedCardCopies: 1,
        );
    }
  }

  static String titleForMode(GameMode mode) {
    switch (mode) {
      case GameMode.original:
        return 'Original';
      case GameMode.expansionBalanced:
        return 'Ecos da Mansão — Balanceado';
      case GameMode.expansionFullHand:
        return 'Ecos da Mansão — Mão Cheia';
    }
  }

  static String descriptionForMode(GameMode mode) {
    switch (mode) {
      case GameMode.original:
        return 'Jogo base, sem cartas da expansão, usando 4 cartas iniciais.';
      case GameMode.expansionBalanced:
        return 'Expansão com ajuste automático para manter o Culpado levemente favorecido.';
      case GameMode.expansionFullHand:
        return 'Mais cartas na mão, mais estratégia, mais efeitos e mais caos controlado.';
    }
  }
}

class GameSetup {
  const GameSetup({
    required this.playerNames,
    required this.gameMode,
    required this.initialCards,
    required this.ghostCopies,
    required this.extraSilenceCopies,
    required this.extraSealedCardCopies,
  });

  final List<String> playerNames;
  final GameMode gameMode;
  final int initialCards;
  final int ghostCopies;
  final int extraSilenceCopies;
  final int extraSealedCardCopies;
}

enum PlayerType {
  localHuman,
  bot,
  remoteHuman,
}

enum CardType {
  role,
  investigation,
  protection,
  manipulation,
  chaos,
  scoring,
  special,
}

class GameCard {
  const GameCard({
    required this.id,
    required this.templateId,
    required this.name,
    required this.type,
    required this.shortText,
  });

  final String id;
  final String templateId;
  final String name;
  final CardType type;
  final String shortText;
}

class Player {
  Player({
    required this.id,
    required this.name,
    required this.type,
    required this.hand,
    required this.playedCards,
    this.score = 0,
    this.isAccomplice = false,
    this.hasHandcuffs = false,
  });

  final String id;
  final String name;
  final PlayerType type;

  final List<GameCard> hand;
  final List<GameCard> playedCards;

  int score;
  bool isAccomplice;
  bool hasHandcuffs;
}

class GameState {
  GameState({
    required this.players,
    required this.deck,
    required this.currentPlayerIndex,
    required this.initialCards,
    required this.ghostCopies,
    this.roundFinished = false,
  });

  final List<Player> players;
  final List<GameCard> deck;

  int currentPlayerIndex;
  final int initialCards;
  final int ghostCopies;
  bool roundFinished;

  Player get currentPlayer => players[currentPlayerIndex];

  void moveToNextPlayer() {
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
  }
}

class CardDatabase {
  static List<GameCard> originalDeck() {
    final cards = <GameCard>[];

    addCopies(
      cards: cards,
      templateId: 'primeiro_na_cena',
      name: 'Primeiro na Cena',
      type: CardType.special,
      shortText:
      'Você é o primeiro jogador. Jogue esta carta para iniciar a rodada.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'culpado',
      name: 'Culpado',
      type: CardType.role,
      shortText:
      'Você só pode jogar ou descartar esta carta se ela for a última em sua mão.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'detetive',
      name: 'Detetive',
      type: CardType.investigation,
      shortText:
      'Pergunte a outro jogador: “Você é o culpado?” Se ele for o culpado e não tiver Álibi, você vence.',
      quantity: 4,
    );

    addCopies(
      cards: cards,
      templateId: 'cumplice',
      name: 'Cúmplice',
      type: CardType.role,
      shortText:
      'Jogar esta carta torna você cúmplice do culpado. Force outro jogador a descartar uma carta e comprar outra.',
      quantity: 2,
    );

    addCopies(
      cards: cards,
      templateId: 'xerife',
      name: 'Xerife',
      type: CardType.investigation,
      shortText:
      'Pegue a carta de algemas e coloque-a à frente de outro jogador.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'alibi',
      name: 'Álibi',
      type: CardType.protection,
      shortText:
      'Enquanto estiver segurando esta carta, você deve responder ao Detetive: “Não, eu não sou o culpado!”',
      quantity: 5,
    );

    addCopies(
      cards: cards,
      templateId: 'toto',
      name: 'Totó',
      type: CardType.investigation,
      shortText:
      'Escolha uma carta aleatória da mão de outro jogador e revele-a. Se for o Culpado, você vence.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'bebe_da_familia',
      name: 'O Bebê da Família',
      type: CardType.investigation,
      shortText:
      'Todos fecham os olhos. Apenas o culpado abre os olhos. Depois todos abrem os olhos.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'compartilhar',
      name: 'Compartilhar',
      type: CardType.manipulation,
      shortText:
      'Cada jogador escolhe uma carta da própria mão e entrega ao jogador à esquerda.',
      quantity: 4,
    );

    addCopies(
      cards: cards,
      templateId: 'rumores',
      name: 'Rumores',
      type: CardType.manipulation,
      shortText:
      'Cada jogador saca uma carta aleatória da mão do jogador à sua direita.',
      quantity: 4,
    );

    addCopies(
      cards: cards,
      templateId: 'frenesi',
      name: 'Frenesi!!!',
      type: CardType.chaos,
      shortText:
      'Cada jogador escolhe uma carta da própria mão. Misture-as e distribua uma para cada jogador.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'adivinho',
      name: 'Adivinho',
      type: CardType.special,
      shortText:
      'Compartilhe suas impressões sobre a rodada atual com os outros jogadores.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'testemunha',
      name: 'Testemunha',
      type: CardType.investigation,
      shortText:
      'Olhe as cartas da mão de um jogador. Se encontrar Culpado ou Cúmplice, você pode trocar uma carta com ele.',
      quantity: 4,
    );

    addCopies(
      cards: cards,
      templateId: 'criada',
      name: 'A Criada',
      type: CardType.protection,
      shortText: 'O Detetive não pode questionar você até sua próxima vez.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'governanta',
      name: 'A Governanta',
      type: CardType.protection,
      shortText: 'Totó e o Xerife não podem escolher você até sua próxima vez.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'trocar',
      name: 'Trocar',
      type: CardType.manipulation,
      shortText:
      'Troque uma carta da sua mão pela de um jogador à sua escolha. Ele escolhe qual carta entregar.',
      quantity: 4,
    );

    return cards;
  }

  static List<GameCard> expansionDeck(GameSetup setup) {
    if (setup.gameMode == GameMode.original) {
      return [];
    }

    final cards = <GameCard>[];

    addCopies(
      cards: cards,
      templateId: 'mordomo',
      name: 'O Mordomo',
      type: CardType.investigation,
      shortText:
      'Escolha um jogador. Ele deve dizer quantas cartas tem na mão com o mesmo nome de cartas já jogadas.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'chave_enferrujada',
      name: 'A Chave Enferrujada',
      type: CardType.manipulation,
      shortText:
      'Mova as algemas para outro jogador. Se estiverem no centro, coloque-as à frente de um jogador.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'retrato_na_parede',
      name: 'Retrato na Parede',
      type: CardType.investigation,
      shortText:
      'Olhe em segredo uma carta aleatória da mão de outro jogador. Se for o Culpado, a rodada não acaba.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'espiao',
      name: 'O Espião',
      type: CardType.investigation,
      shortText:
      'Escolha até dois jogadores. Olhe uma carta aleatória da mão de cada um em segredo.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'taca_envenenada',
      name: 'A Taça Envenenada',
      type: CardType.manipulation,
      shortText:
      'Escolha um jogador. Ele descarta uma carta virada para cima e compra uma carta.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'fantasma_do_visconde',
      name: 'O Fantasma do Visconde',
      type: CardType.special,
      shortText:
      'Escolha uma carta já jogada à frente de qualquer jogador e copie seu efeito.',
      quantity: setup.ghostCopies,
    );

    addCopies(
      cards: cards,
      templateId: 'mascara_quebrada',
      name: 'A Máscara Quebrada',
      type: CardType.investigation,
      shortText:
      'Escolha um jogador. Você escolhe, sem olhar, uma carta da mão dele e a revela para todos.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'juramento_secreto',
      name: 'O Juramento Secreto',
      type: CardType.scoring,
      shortText:
      'Escolha outro jogador. Até o fim da rodada, se um de vocês vencer, o outro recebe 1 ponto a menos.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'cancao_de_ninar',
      name: 'A Canção de Ninar',
      type: CardType.investigation,
      shortText:
      'Quem tem Detetive ou Totó abre os olhos. Depois todos fecham e abrem os olhos novamente.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'palavra_final',
      name: 'A Palavra Final',
      type: CardType.manipulation,
      shortText:
      'Escolha um jogador com proteção ativa. Desative o efeito dessa proteção.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'piano_desafinado',
      name: 'O Piano Desafinado',
      type: CardType.chaos,
      shortText:
      'Na próxima vez de um jogador, você embaralha a mão dele sem olhar e joga uma carta aleatória por ele.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'carta_selada',
      name: 'A Carta Selada',
      type: CardType.manipulation,
      shortText:
      'Escolha um jogador. Pegue uma carta aleatória da mão dele, sem olhar, e coloque-a virada para baixo à frente dele.',
      quantity: 1 + setup.extraSealedCardCopies,
    );

    addCopies(
      cards: cards,
      templateId: 'tres_destinos',
      name: 'Três Destinos',
      type: CardType.special,
      shortText:
      'Compre 3 cartas do monte. Escolha uma para resolver e baixe as outras viradas para cima sem efeito.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'assunto_inacabado',
      name: 'Assunto Inacabado',
      type: CardType.manipulation,
      shortText:
      'Escolha um jogador. Esse jogador compra 1 carta do monte e adiciona à própria mão.',
      quantity: 1,
    );

    addCopies(
      cards: cards,
      templateId: 'silencio_na_mansao',
      name: 'Silêncio na Mansão',
      type: CardType.protection,
      shortText:
      'Até o início da sua próxima vez, ninguém pode jogar cartas que façam pergunta direta a outro jogador.',
      quantity: 1 + setup.extraSilenceCopies,
    );

    addCopies(
      cards: cards,
      templateId: 'traicao_no_salao',
      name: 'Traição no Salão',
      type: CardType.manipulation,
      shortText:
      'Escolha um jogador com Cúmplice à frente. Esse jogador deixa de ser Cúmplice até o fim da rodada.',
      quantity: 1,
    );

    return cards;
  }

  static void addCopies({
    required List<GameCard> cards,
    required String templateId,
    required String name,
    required CardType type,
    required String shortText,
    required int quantity,
  }) {
    final existingCopies =
        cards.where((card) => card.templateId == templateId).length;

    for (int i = 0; i < quantity; i++) {
      final copyNumber = existingCopies + i + 1;

      cards.add(
        GameCard(
          id: '${templateId}_$copyNumber',
          templateId: templateId,
          name: name,
          type: type,
          shortText: shortText,
        ),
      );
    }
  }
}

class OfficialSetupRules {
  static Map<String, int> mandatoryCardsForPlayerCount(int playerCount) {
    switch (playerCount) {
      case 3:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 0,
          'xerife': 1,
          'alibi': 1,
        };
      case 4:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 1,
          'xerife': 1,
          'alibi': 1,
        };
      case 5:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 1,
          'cumplice': 1,
          'xerife': 1,
          'alibi': 2,
        };
      case 6:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 2,
          'cumplice': 2,
          'xerife': 1,
          'alibi': 2,
        };
      case 7:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 2,
          'cumplice': 2,
          'xerife': 1,
          'alibi': 3,
        };
      case 8:
        return {
          'primeiro_na_cena': 1,
          'culpado': 1,
          'detetive': 2,
          'cumplice': 2,
          'xerife': 1,
          'alibi': 3,
        };
      default:
        throw ArgumentError('Quantidade de jogadores inválida: $playerCount');
    }
  }
}

GameState createInitialGameState(GameSetup setup) {
  final random = Random();

  final playerCount = setup.playerNames.length;
  final cardsToDeal = playerCount * setup.initialCards;

  final pool = [
    ...CardDatabase.originalDeck(),
    ...CardDatabase.expansionDeck(setup),
  ];

  final selectedCards = <GameCard>[];

  final mandatoryCards =
  OfficialSetupRules.mandatoryCardsForPlayerCount(playerCount);

  for (final entry in mandatoryCards.entries) {
    final templateId = entry.key;
    final quantity = entry.value;

    for (int i = 0; i < quantity; i++) {
      final cardIndex = pool.indexWhere(
            (card) => card.templateId == templateId,
      );

      if (cardIndex == -1) {
        throw StateError('Carta obrigatória não encontrada: $templateId');
      }

      selectedCards.add(pool.removeAt(cardIndex));
    }
  }

  final additionalCardsNeeded = cardsToDeal - selectedCards.length;

  if (additionalCardsNeeded < 0) {
    throw StateError(
      'Há mais cartas obrigatórias do que cartas para distribuir.',
    );
  }

  if (additionalCardsNeeded > pool.length) {
    throw StateError(
      'Não há cartas suficientes para distribuir $cardsToDeal cartas.',
    );
  }

  pool.shuffle(random);

  selectedCards.addAll(pool.take(additionalCardsNeeded));
  pool.removeRange(0, additionalCardsNeeded);

  selectedCards.shuffle(random);
  pool.shuffle(random);

  final players = setup.playerNames.asMap().entries.map((entry) {
    final index = entry.key;
    final name = entry.value;

    return Player(
      id: 'player_$index',
      name: name,
      type: PlayerType.localHuman,
      hand: [],
      playedCards: [],
    );
  }).toList();

  for (int i = 0; i < selectedCards.length; i++) {
    final playerIndex = i % players.length;
    players[playerIndex].hand.add(selectedCards[i]);
  }

  final firstPlayerIndex = players.indexWhere(
        (player) => player.hand.any(
          (card) => card.templateId == 'primeiro_na_cena',
    ),
  );

  return GameState(
    players: players,
    deck: pool,
    currentPlayerIndex: firstPlayerIndex == -1 ? 0 : firstPlayerIndex,
    initialCards: setup.initialCards,
    ghostCopies: setup.ghostCopies,
  );
}

void playCard({
  required GameState gameState,
  required GameCard card,
}) {
  final currentPlayer = gameState.currentPlayer;

  currentPlayer.hand.removeWhere((item) => item.id == card.id);
  currentPlayer.playedCards.add(card);

  gameState.moveToNextPlayer();
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

class GameModeOptionCard extends StatelessWidget {
  const GameModeOptionCard({
    super.key,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected
          ? const Color(0xFF3A1A4A)
          : const Color(0xFF221229),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected
              ? const Color(0xFFE7C76F)
              : Colors.white24,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFFE7C76F)
                    : Colors.white54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    required this.gameMode,
    required this.recommendation,
  });

  final int playerCount;
  final GameMode gameMode;
  final GameSetupRecommendation recommendation;

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
              label: 'Modo',
              value: GameSetupRules.titleForMode(gameMode),
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Cartas iniciais',
              value: '${recommendation.initialCards}',
            ),
            const Divider(),
            SetupSummaryRow(
              label: 'Fantasmas do Visconde',
              value: '${recommendation.ghostCopies}',
            ),
            if (recommendation.extraSilenceCopies > 0) ...[
              const Divider(),
              SetupSummaryRow(
                label: 'Silêncio na Mansão extra',
                value: '+${recommendation.extraSilenceCopies}',
              ),
            ],
            if (recommendation.extraSealedCardCopies > 0) ...[
              const Divider(),
              SetupSummaryRow(
                label: 'A Carta Selada extra',
                value: '+${recommendation.extraSealedCardCopies}',
              ),
            ],
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
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.currentPlayer;

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
                      currentPlayer.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '${gameState.initialCards} cartas iniciais • '
                          '${gameState.ghostCopies} Fantasmas',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cartas na mão: ${currentPlayer.hand.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      'Cartas à frente: ${currentPlayer.playedCards.length}',
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => HandScreen(
                                gameState: gameState,
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TableScreen(
                                gameState: gameState,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.table_bar),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver Mesa',
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

class HandScreen extends StatelessWidget {
  const HandScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    final currentPlayer = gameState.currentPlayer;

    return Scaffold(
      appBar: AppBar(
        title: Text('Mão de ${currentPlayer.name}'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                currentPlayer.name,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Escolha uma carta para jogar.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TableScreen(
                        gameState: gameState,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.table_bar),
                label: const Text('Ver Mesa'),
              ),
              const SizedBox(height: 24),
              ...currentPlayer.hand.map((card) {
                return Card(
                  color: const Color(0xFF221229),
                  child: ListTile(
                    title: Text(
                      card.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(card.shortText),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final isFirstTurnOfRound = gameState.players.every(
                            (player) => player.playedCards.isEmpty,
                      );

                      final isFirstSceneCard = card.templateId == 'primeiro_na_cena';

                      if (isFirstTurnOfRound && !isFirstSceneCard) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('A primeira carta da rodada deve ser Primeiro na Cena.'),
                          ),
                        );

                        return;
                      }

                      final shouldPlay = await showDialog<bool>(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text(card.name),
                            content: Text(
                              '${card.shortText}\n\nDeseja jogar esta carta?',
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
                                child: const Text('Jogar'),
                              ),
                            ],
                          );
                        },
                      );

                      if (shouldPlay != true) {
                        return;
                      }

                      playCard(
                        gameState: gameState,
                        card: card,
                      );

                      if (!context.mounted) {
                        return;
                      }

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => PassDeviceScreen(
                            gameState: gameState,
                          ),
                        ),
                            (route) => route.isFirst,
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class TableScreen extends StatelessWidget {
  const TableScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesa'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Estado da Mesa',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Veja as cartas já jogadas à frente de cada jogador.',
                style: TextStyle(
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ...gameState.players.map((player) {
                final isCurrentPlayer = player.id == gameState.currentPlayer.id;

                return Card(
                  color: isCurrentPlayer
                      ? const Color(0xFF3A1A4A)
                      : const Color(0xFF221229),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isCurrentPlayer
                          ? const Color(0xFFE7C76F)
                          : Colors.white12,
                      width: isCurrentPlayer ? 2 : 1,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isCurrentPlayer
                                  ? Icons.play_arrow
                                  : Icons.person,
                              color: isCurrentPlayer
                                  ? const Color(0xFFE7C76F)
                                  : Colors.white70,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                player.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${player.hand.length} na mão',
                              style: const TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (player.playedCards.isEmpty)
                          const Text(
                            'Nenhuma carta à frente.',
                            style: TextStyle(
                              color: Colors.white54,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: player.playedCards.map((card) {
                              return Chip(
                                label: Text(card.name),
                                backgroundColor: const Color(0xFF120818),
                                side: const BorderSide(
                                  color: Color(0xFFE7C76F),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            ],
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