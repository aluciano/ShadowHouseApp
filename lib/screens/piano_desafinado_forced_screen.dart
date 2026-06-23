import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../widgets/shadow_background.dart';
import 'played_card_effect_router.dart';

class PianoDesafinadoForcedScreen extends StatefulWidget {
  const PianoDesafinadoForcedScreen({
    super.key,
    required this.gameState,
  });

  final GameState gameState;

  @override
  State<PianoDesafinadoForcedScreen> createState() =>
      _PianoDesafinadoForcedScreenState();
}

class _PianoDesafinadoForcedScreenState
    extends State<PianoDesafinadoForcedScreen> {
  PianoForcedPlayResult? result;
  bool privacyConfirmed = false;

  @override
  Widget build(BuildContext context) {
    final targetPlayer = widget.gameState.currentPlayer;
    final controllerPlayer = widget.gameState.players.firstWhere(
      (player) => player.id == widget.gameState.pianoControllerPlayerId,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Turno sob efeito do Piano Desafinado'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'O Piano Desafinado',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE7C76F),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A vez de ${targetPlayer.name} está sendo controlada por ${controllerPlayer.name}.',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              if (result != null)
                _PianoResultCard(
                  controllerName: controllerPlayer.name,
                  targetName: targetPlayer.name,
                  result: result!,
                  onContinue: () {
                    continueAfterPlayedCard(
                      context: context,
                      gameState: widget.gameState,
                      actingPlayerId: targetPlayer.id,
                      card: result!.playedCard,
                    );
                  },
                )
              else if (!privacyConfirmed)
                _PianoPrivacyCard(
                  controllerName: controllerPlayer.name,
                  targetName: targetPlayer.name,
                  onContinue: () {
                    setState(() {
                      privacyConfirmed = true;
                    });
                  },
                )
              else
                _PianoExecutionCard(
                  controllerName: controllerPlayer.name,
                  targetName: targetPlayer.name,
                  onExecute: () {
                    setState(() {
                      result = resolvePianoForcedPlay(
                        gameState: widget.gameState,
                      );
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PianoPrivacyCard extends StatelessWidget {
  const _PianoPrivacyCard({
    required this.controllerName,
    required this.targetName,
    required this.onContinue,
  });

  final String controllerName;
  final String targetName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.queue_music,
              size: 64,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              'Passe o dispositivo para $controllerName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$controllerName vai jogar uma carta aleatória por $targetName.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PianoExecutionCard extends StatelessWidget {
  const _PianoExecutionCard({
    required this.controllerName,
    required this.targetName,
    required this.onExecute,
  });

  final String controllerName;
  final String targetName;
  final VoidCallback onExecute;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.music_note,
              size: 64,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              '$controllerName vai embaralhar a mão de $targetName sem olhar e jogar uma carta aleatória.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onExecute,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Tocar carta aleatória'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PianoResultCard extends StatelessWidget {
  const _PianoResultCard({
    required this.controllerName,
    required this.targetName,
    required this.result,
    required this.onContinue,
  });

  final String controllerName;
  final String targetName;
  final PianoForcedPlayResult result;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF221229),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.library_music,
              size: 64,
              color: Color(0xFFE7C76F),
            ),
            const SizedBox(height: 24),
            Text(
              '$controllerName jogou uma carta aleatória por $targetName.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            if (result.revealedGuiltyCard != null) ...[
              const SizedBox(height: 12),
              Text(
                'O Culpado foi revelado, devolvido à mão de $targetName e outra carta foi sorteada.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              result.playedCard.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.playedCard.shortText,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onContinue,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Continuar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
