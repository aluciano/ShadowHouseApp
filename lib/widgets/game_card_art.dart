import 'package:flutter/material.dart';

import '../models/game_card.dart';

class GameCardArt extends StatelessWidget {
  const GameCardArt({
    super.key,
    required this.card,
    this.width = 96,
    this.showFaceDown = false,
    this.showDiscarded = true,
  });

  final GameCard card;
  final double width;
  final bool showFaceDown;
  final bool showDiscarded;

  static const _assetByTemplateId = <String, String>{
    'primeiro_na_cena': 'assets/cards/original/primeiro_na_cena.png',
    'algemas': 'assets/cards/original/algemas.png',
    'culpado': 'assets/cards/original/culpado.png',
    'detetive': 'assets/cards/original/detetive.png',
    'cumplice': 'assets/cards/original/cumplice.png',
    'xerife': 'assets/cards/original/xerife.png',
    'alibi': 'assets/cards/original/alibi.png',
    'toto': 'assets/cards/original/toto.png',
    'bebe_da_familia': 'assets/cards/original/bebe_da_familia.png',
    'compartilhar': 'assets/cards/original/compartilhar.png',
    'rumores': 'assets/cards/original/rumores.png',
    'frenesi': 'assets/cards/original/frenesi.png',
    'adivinho': 'assets/cards/original/adivinho.png',
    'testemunha': 'assets/cards/original/testemunha.png',
    'criada': 'assets/cards/original/a_criada.png',
    'governanta': 'assets/cards/original/governanta.png',
    'trocar': 'assets/cards/original/trocar.png',
    'mordomo': 'assets/cards/expansion/o_mordomo.png',
    'chave_enferrujada': 'assets/cards/expansion/a_chave_enferrujada.png',
    'retrato_na_parede': 'assets/cards/expansion/retrato_na_parede.png',
    'espiao': 'assets/cards/expansion/o_espiao.png',
    'taca_envenenada': 'assets/cards/expansion/a_taca_envenenada.png',
    'fantasma_do_visconde': 'assets/cards/expansion/o_fantasma_do_visconde.png',
    'mascara_quebrada': 'assets/cards/expansion/a_mascara_quebrada.png',
    'juramento_secreto': 'assets/cards/expansion/o_juramento_secreto.png',
    'cancao_de_ninar': 'assets/cards/expansion/a_cancao_de_ninar.png',
    'palavra_final': 'assets/cards/expansion/a_palavra_final.png',
    'piano_desafinado': 'assets/cards/expansion/o_piano_desafinado.png',
    'carta_selada': 'assets/cards/expansion/a_carta_selada.png',
    'tres_destinos': 'assets/cards/expansion/tres_destinos.png',
    'assunto_inacabado': 'assets/cards/expansion/assunto_inacabado.png',
    'silencio_na_mansao': 'assets/cards/expansion/silencio_na_mansao.png',
    'traicao_no_salao': 'assets/cards/expansion/traicao_no_salao.png',
  };

  static const _cardBackAsset = 'assets/cards/card_back.png';

  static String? assetFor(GameCard card) {
    return _assetByTemplateId[card.templateId];
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = showFaceDown ? _cardBackAsset : assetFor(card);
    final height = width * 1110 / 815;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imagePath == null)
            _FallbackCard(card: card, showFaceDown: showFaceDown)
          else
            Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return _FallbackCard(card: card, showFaceDown: showFaceDown);
              },
            ),
          if (showDiscarded && card.wasDiscarded)
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.46),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.block, color: Colors.white, size: 28),
              ),
            ),
        ],
      ),
    );
  }
}

class _FallbackCard extends StatelessWidget {
  const _FallbackCard({required this.card, required this.showFaceDown});

  final GameCard card;
  final bool showFaceDown;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF120818),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7C76F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Center(
          child: Text(
            showFaceDown ? 'Carta selada' : card.name,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFE7C76F),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}
