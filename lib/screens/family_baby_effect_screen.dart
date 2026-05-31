import 'package:flutter/material.dart';

import '../engine/game_engine.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../widgets/shadow_background.dart';
import 'pass_device_screen.dart';

class FamilyBabyEffectScreen extends StatefulWidget {
  const FamilyBabyEffectScreen({
    super.key,
    required this.gameState,
    required this.actingPlayerId,
  });

  final GameState gameState;
  final String actingPlayerId;

  @override
  State<FamilyBabyEffectScreen> createState() => _FamilyBabyEffectScreenState();
}

class _FamilyBabyEffectScreenState extends State<FamilyBabyEffectScreen> {
  bool guiltyRevealed = false;

  @override
  Widget build(BuildContext context) {
    final actingPlayer = widget.gameState.players.firstWhere(
          (player) => player.id == widget.actingPlayerId,
    );

    final guiltyPlayer = findGuiltyPlayer(widget.gameState);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resolver O Bebê da Família'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: Center(
            child: Card(
              color: const Color(0xFF221229),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: guiltyRevealed
                    ? _GuiltyRevealedContent(
                  actingPlayer: actingPlayer,
                  guiltyPlayer: guiltyPlayer,
                  onContinue: () {
                    resolveFamilyBabyEffect(
                      gameState: widget.gameState,
                    );

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => PassDeviceScreen(
                          gameState: widget.gameState,
                        ),
                      ),
                          (route) => route.isFirst,
                    );
                  },
                )
                    : _PrivacyContent(
                  actingPlayer: actingPlayer,
                  onReveal: () {
                    setState(() {
                      guiltyRevealed = true;
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyContent extends StatelessWidget {
  const _PrivacyContent({
    required this.actingPlayer,
    required this.onReveal,
  });

  final Player actingPlayer;
  final VoidCallback onReveal;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.child_care,
          size: 72,
          color: Color(0xFFE7C76F),
        ),
        const SizedBox(height: 24),
        const Text(
          'O Bebê da Família',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE7C76F),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Somente ${actingPlayer.name} deve olhar esta tela.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'O app vai revelar secretamente quem está com o Culpado.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onReveal,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Revelar Culpado',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuiltyRevealedContent extends StatelessWidget {
  const _GuiltyRevealedContent({
    required this.actingPlayer,
    required this.guiltyPlayer,
    required this.onContinue,
  });

  final Player actingPlayer;
  final Player guiltyPlayer;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.visibility,
          size: 72,
          color: Color(0xFFE7C76F),
        ),
        const SizedBox(height: 24),
        const Text(
          'Informação secreta',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE7C76F),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'O Culpado está com:',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          guiltyPlayer.name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE7C76F),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '${actingPlayer.name}, guarde essa informação em segredo.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onContinue,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text(
                'Continuar',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}