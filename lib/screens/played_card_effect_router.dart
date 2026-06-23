import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_card.dart';
import '../models/game_state.dart';
import 'betrayal_effect_screen.dart';
import 'broken_mask_effect_screen.dart';
import 'card_exchange_effect_screen.dart';
import 'circular_card_pass_effect_screen.dart';
import 'detective_effect_screen.dart';
import 'family_baby_effect_screen.dart';
import 'forced_discard_effect_screen.dart';
import 'frenzy_effect_screen.dart';
import 'ghost_of_viscount_effect_screen.dart';
import 'handcuffs_effect_screen.dart';
import 'lullaby_effect_screen.dart';
import 'pass_device_screen.dart';
import 'piano_desafinado_setup_screen.dart';
import 'round_result_screen.dart';
import 'rumors_effect_screen.dart';
import 'sealed_card_effect_screen.dart';
import 'secret_oath_effect_screen.dart';
import 'three_destinies_effect_screen.dart';
import 'toto_effect_screen.dart';
import 'unfinished_business_effect_screen.dart';
import 'witness_effect_screen.dart';

void continueAfterPlayedCard({
  required BuildContext context,
  required GameState gameState,
  required String actingPlayerId,
  required GameCard card,
}) {
  if (gameState.roundFinished) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RoundResultScreen(
          gameState: gameState,
        ),
      ),
      (route) => route.isFirst,
    );

    return;
  }

  if (card.templateId == 'cumplice') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForcedDiscardEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver Cúmplice',
          effectName: 'Cúmplice',
          instructionText:
              'escolha outro jogador. Esse jogador descarta uma carta da própria mão e compra outra do monte.',
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'taca_envenenada') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ForcedDiscardEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver A Taça Envenenada',
          effectName: 'A Taça Envenenada',
          instructionText:
              'escolha outro jogador. Esse jogador descarta uma carta da própria mão virada para cima e depois compra uma carta.',
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'detetive') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => DetectiveEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'toto') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => TotoEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'xerife') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HandcuffsEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver Xerife',
          instructionText:
              'escolha outro jogador com cartas na mão para receber as algemas.',
          allowSelfTarget: false,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'chave_enferrujada') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HandcuffsEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver A Chave Enferrujada',
          instructionText:
              'escolha qualquer jogador com cartas na mão, inclusive você mesmo, para receber as algemas.',
          allowSelfTarget: true,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'bebe_da_familia') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => FamilyBabyEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'testemunha') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => WitnessEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'trocar') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CardExchangeEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver Trocar',
          introText:
              'escolha outro jogador com cartas na mão. Depois cada um escolhe uma carta da própria mão para trocar.',
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'compartilhar') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => CircularCardPassEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
          effectTitle: 'Resolver Compartilhar',
          introText:
              'Cada jogador com cartas na mão escolhe uma carta. Depois, cada carta será entregue ao jogador à esquerda, seguindo a ordem da mesa.',
          passToLeft: true,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'rumores') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => RumorsEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'frenesi') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => FrenzyEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'mascara_quebrada') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BrokenMaskEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'assunto_inacabado') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => UnfinishedBusinessEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'cancao_de_ninar') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LullabyEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'carta_selada') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SealedCardEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'juramento_secreto') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => SecretOathEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'silencio_na_mansao') {
    resolveSilenceEffect(
      gameState: gameState,
      actingPlayer: gameState.players.firstWhere(
        (player) => player.id == actingPlayerId,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PassDeviceScreen(
          gameState: gameState,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'traicao_no_salao') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BetrayalEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'fantasma_do_visconde') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => GhostOfViscountEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'tres_destinos') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => ThreeDestiniesEffectScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
    return;
  }

  if (card.templateId == 'piano_desafinado') {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => PianoDesafinadoSetupScreen(
          gameState: gameState,
          actingPlayerId: actingPlayerId,
        ),
      ),
      (route) => route.isFirst,
    );
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
}
