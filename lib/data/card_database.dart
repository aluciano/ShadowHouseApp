import '../models/card_type.dart';
import '../models/game_card.dart';
import '../models/game_mode.dart';
import '../models/game_setup.dart';

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
      'Escolha outro jogador. Esse jogador descarta uma carta da própria mão virada para cima e depois compra uma carta.',
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