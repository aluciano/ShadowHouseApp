import 'package:flutter/material.dart';

import '../models/online_game_session.dart';
import '../models/online_player.dart';
import '../models/player.dart';
import '../models/round_result_type.dart';
import '../repositories/local_online_membership_store.dart';
import '../repositories/online_game_session_factory.dart';
import '../repositories/repository_registry.dart';
import '../widgets/shadow_background.dart';
import '../widgets/shadow_scrollable_content.dart';
import 'match_history_screen.dart';
import 'online_game_screen.dart';
import 'table_screen.dart';

class OnlineRoundResultScreen extends StatefulWidget {
  const OnlineRoundResultScreen({
    super.key,
    required this.session,
    required this.currentPlayerId,
  });

  final OnlineGameSession session;
  final String currentPlayerId;

  @override
  State<OnlineRoundResultScreen> createState() =>
      _OnlineRoundResultScreenState();
}

class _OnlineRoundResultScreenState extends State<OnlineRoundResultScreen> {
  final membershipStore = createLocalOnlineMembershipStore();
  bool isStartingNextRound = false;
  bool isStartingRematch = false;
  bool isOpeningStartedRound = false;
  bool isLeavingRoom = false;

  OnlineGameSession get session => widget.session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    markConnected();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  late final WidgetsBindingObserver _lifecycleObserver =
      _RoundResultLifecycleObserver(
        onStateChanged: (state) {
          if (state == AppLifecycleState.resumed) {
            markConnected();
          } else if (state == AppLifecycleState.inactive ||
              state == AppLifecycleState.paused ||
              state == AppLifecycleState.detached) {
            markDisconnected();
          }
        },
      );

  Future<void> markConnected() async {
    await RepositoryRegistry.onlineGame.updatePlayerConnection(
      roomId: widget.session.room.id,
      playerId: widget.currentPlayerId,
      isConnected: true,
    );
  }

  Future<void> markDisconnected() async {
    await RepositoryRegistry.onlineGame.updatePlayerConnection(
      roomId: widget.session.room.id,
      playerId: widget.currentPlayerId,
      isConnected: false,
    );
  }

  Future<void> leaveRoom(OnlineGameSession session) async {
    if (isLeavingRoom) {
      return;
    }

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sair da sala'),
          content: const Text(
            'Você sairá desta sala online e deixará de participar da continuação.',
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
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true || !mounted) {
      return;
    }

    setState(() {
      isLeavingRoom = true;
    });

    await RepositoryRegistry.onlineGame.leaveRoom(
      roomId: session.room.id,
      playerId: widget.currentPlayerId,
    );
    await membershipStore.clear();

    if (!mounted) {
      return;
    }

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> confirmReadyForNextRound(
    OnlineGameSession session,
    String playerId,
  ) async {
    final readyPlayerIds = {
      ...session.nextRoundReadyPlayerIds,
      playerId,
    }.toList();

    await RepositoryRegistry.onlineGame.saveCurrentSession(
      session.copyWith(nextRoundReadyPlayerIds: readyPlayerIds),
    );
  }

  Future<void> startNextRound(OnlineGameSession session) async {
    setState(() {
      isStartingNextRound = true;
    });

    final nextSession = createNextOnlineRoundSession(session);

    await RepositoryRegistry.onlineGame.saveCurrentSession(nextSession);

    if (!mounted) {
      return;
    }

    openGame(nextSession);
  }

  Future<void> proposeRematch(
    OnlineGameSession session,
    String playerId,
  ) async {
    final proposals = {
      ...session.rematchProposalPlayerIds,
      playerId,
    }.toList();

    await RepositoryRegistry.onlineGame.saveCurrentSession(
      session.copyWith(rematchProposalPlayerIds: proposals),
    );
  }

  Future<void> removeDisconnectedPlayer({
    required OnlineGameSession session,
    required String removedPlayerId,
  }) async {
    await RepositoryRegistry.onlineGame.removePlayer(
      roomId: session.room.id,
      actingPlayerId: widget.currentPlayerId,
      removedPlayerId: removedPlayerId,
    );
  }

  Future<void> startRematch(OnlineGameSession session) async {
    setState(() {
      isStartingRematch = true;
    });

    final nextSession = await RepositoryRegistry.onlineGame
        .startNewMatchInSameRoom(session.room);

    if (!mounted) {
      return;
    }

    openGame(nextSession);
  }

  void openGame(OnlineGameSession nextSession) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OnlineGameScreen(
          session: nextSession,
          currentPlayerId: widget.currentPlayerId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<OnlineGameSession>(
      stream: RepositoryRegistry.onlineGame.watchCurrentSession(session.room),
      initialData: session,
      builder: (context, snapshot) {
        final visibleSession = snapshot.data ?? session;
        final expectedPlayerIds = _expectedPlayerIds(visibleSession);
        final currentDeviceIsHost =
            widget.currentPlayerId == visibleSession.room.hostPlayerId;
        final matchFinished = _isMatchFinished(visibleSession);
        final proposalsAreComplete = expectedPlayerIds.every(
          visibleSession.rematchProposalPlayerIds.contains,
        );
        final readyForNextRoundIsComplete = expectedPlayerIds.every(
          visibleSession.nextRoundReadyPlayerIds.contains,
        );

        if (!visibleSession.gameState.roundFinished && !isOpeningStartedRound) {
          isOpeningStartedRound = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              openGame(visibleSession);
            }
          });
        } else if (visibleSession.gameState.roundFinished &&
            matchFinished &&
            proposalsAreComplete &&
            currentDeviceIsHost &&
            !isStartingRematch) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              startRematch(visibleSession);
            }
          });
        } else if (visibleSession.gameState.roundFinished &&
            !matchFinished &&
            readyForNextRoundIsComplete &&
            currentDeviceIsHost &&
            !isStartingNextRound) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              startNextRound(visibleSession);
            }
          });
        }

        return buildContent(context, visibleSession);
      },
    );
  }

  Widget buildContent(BuildContext context, OnlineGameSession session) {
    final gameState = session.gameState;
    final result = gameState.roundResult;
    final highestScore = gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);
    final isMatchFinished = highestScore >= 5;
    final winners = gameState.players
        .where((player) => player.score == highestScore)
        .toList();
    final expectedPlayerIds = _expectedPlayerIds(session);
    final currentPlayer = gameState.players.firstWhere(
      (player) => player.id == widget.currentPlayerId,
      orElse: () => gameState.players.first,
    );
    final currentPlayerProposed =
        session.rematchProposalPlayerIds.contains(currentPlayer.id);
    final currentPlayerIsReadyForNextRound =
        session.nextRoundReadyPlayerIds.contains(currentPlayer.id);
    final rematchProposalCount = expectedPlayerIds
        .where(session.rematchProposalPlayerIds.contains)
        .length;
    final readyForNextRoundCount = expectedPlayerIds
        .where(session.nextRoundReadyPlayerIds.contains)
        .length;
    final disconnectedPlayers = session.room.players.where((player) {
      return !player.id.startsWith('placeholder_player_') && !player.isConnected;
    }).toList();
    final rematchAcceptedNames = session.room.players
        .where((player) => session.rematchProposalPlayerIds.contains(player.id))
        .map((player) => player.name)
        .toList();
    final rematchPendingNames = session.room.players
        .where((player) => !session.rematchProposalPlayerIds.contains(player.id))
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.name)
        .toList();
    final nextRoundReadyNames = session.room.players
        .where((player) => session.nextRoundReadyPlayerIds.contains(player.id))
        .map((player) => player.name)
        .toList();
    final nextRoundPendingNames = session.room.players
        .where((player) => !session.nextRoundReadyPlayerIds.contains(player.id))
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.name)
        .toList();

    final currentRoomPlayer = session.room.players.where(
      (player) => player.id == widget.currentPlayerId,
    );

    if (currentRoomPlayer.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        membershipStore.clear();

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Você não faz mais parte desta sala.'),
            ),
          );
        Navigator.of(context).popUntil((route) => route.isFirst);
      });

      return const SizedBox.shrink();
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          leaveRoom(session);
        }
      },
      child: Scaffold(
        body: ShadowBackground(
          child: ShadowScrollableContent(
            child: Card(
              color: const Color(0xFF221229),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const Icon(
                    Icons.emoji_events,
                    size: 72,
                    color: Color(0xFFE7C76F),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isMatchFinished
                        ? 'Fim da Partida Online'
                        : 'Fim da Rodada Online',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sala ${session.room.code}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  if (session.room.systemMessage != null) ...[
                    const SizedBox(height: 16),
                    _RoundRoomSystemMessageCard(
                      message: session.room.systemMessage!,
                    ),
                  ],
                  if (disconnectedPlayers.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _RoundDisconnectedPlayersCard(
                      players: disconnectedPlayers,
                      currentDeviceIsHost:
                          currentRoomPlayer.first.id == session.room.hostPlayerId,
                      onRemovePlayer: (playerId) {
                        removeDisconnectedPlayer(
                          session: session,
                          removedPlayerId: playerId,
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    result == null
                        ? 'A rodada terminou.'
                        : _titleForResult(result.type),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xFFE7C76F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      result.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pontuação da rodada',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE7C76F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.scoringSummary,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Placar atual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...gameState.players.map((player) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        '${player.name}: ${player.score} ponto${player.score == 1 ? '' : 's'}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: player.score == highestScore
                              ? const Color(0xFFE7C76F)
                              : Colors.white70,
                          fontWeight: player.score == highestScore
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  Text(
                    isMatchFinished ? 'Vencedor' : 'Liderança',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE7C76F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    winners.map((player) => player.name).join(', '),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TableScreen(
                              gameState: gameState,
                              showHands: true,
                              title: 'Mesa Final',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.table_bar),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Ver Mesa Final',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (isMatchFinished)
                    _RematchCard(
                      currentPlayer: currentPlayer,
                      proposalCount: rematchProposalCount,
                      expectedCount: expectedPlayerIds.length,
                      currentPlayerProposed: currentPlayerProposed,
                      isStartingRematch: isStartingRematch,
                      acceptedNames: rematchAcceptedNames,
                      pendingNames: rematchPendingNames,
                      onPropose: () {
                        proposeRematch(session, currentPlayer.id);
                      },
                    )
                  else
                    _NextRoundReadyCard(
                      readyCount: readyForNextRoundCount,
                      expectedCount: expectedPlayerIds.length,
                      currentPlayerIsReady: currentPlayerIsReadyForNextRound,
                      isStartingNextRound: isStartingNextRound,
                      readyNames: nextRoundReadyNames,
                      pendingNames: nextRoundPendingNames,
                      onConfirmReady: () {
                        confirmReadyForNextRound(session, currentPlayer.id);
                      },
                    ),
                  const SizedBox(height: 12),
                  if (isMatchFinished)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MatchHistoryScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Ver Histórico',
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
                        leaveRoom(session);
                      },
                      icon: const Icon(Icons.home),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Text(
                          'Voltar ao Menu Inicial',
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

  String _titleForResult(RoundResultType type) {
    switch (type) {
      case RoundResultType.guiltyWins:
        return 'O Culpado venceu a rodada!';
      case RoundResultType.detectiveWins:
        return 'O Detetive venceu a rodada!';
      case RoundResultType.totoWins:
        return 'Totó venceu a rodada!';
      case RoundResultType.handcuffsWins:
        return 'As Algemas venceram!';
    }
  }

  List<String> _expectedPlayerIds(OnlineGameSession session) {
    return session.room.players
        .where((player) => !player.id.startsWith('placeholder_player_'))
        .map((player) => player.id)
        .toList();
  }

  bool _isMatchFinished(OnlineGameSession session) {
    final highestScore = session.gameState.players
        .map((player) => player.score)
        .reduce((a, b) => a > b ? a : b);

    return highestScore >= 5;
  }
}

class _RoundResultLifecycleObserver extends WidgetsBindingObserver {
  _RoundResultLifecycleObserver({
    required this.onStateChanged,
  });

  final ValueChanged<AppLifecycleState> onStateChanged;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state);
  }
}

class _RoundRoomSystemMessageCard extends StatelessWidget {
  const _RoundRoomSystemMessageCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.campaign, color: Color(0xFFE7C76F)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                textAlign: TextAlign.left,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundDisconnectedPlayersCard extends StatelessWidget {
  const _RoundDisconnectedPlayersCard({
    required this.players,
    required this.currentDeviceIsHost,
    required this.onRemovePlayer,
  });

  final List<OnlinePlayer> players;
  final bool currentDeviceIsHost;
  final ValueChanged<String> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wifi_off, color: Color(0xFFE7C76F)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    players.length == 1
                        ? 'Desconectado: ${players.first.name}'
                        : 'Desconectados: ${players.map((player) => player.name).join(', ')}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            if (currentDeviceIsHost) ...[
              const SizedBox(height: 12),
              const Text(
                'O anfitrião pode remover jogadores desconectados para destravar a continuação.',
                style: TextStyle(color: Colors.white60),
              ),
              ...players.map((player) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      onRemovePlayer(player.id);
                    },
                    icon: const Icon(Icons.person_remove),
                    label: Text('Remover ${player.name}'),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _NextRoundReadyCard extends StatelessWidget {
  const _NextRoundReadyCard({
    required this.readyCount,
    required this.expectedCount,
    required this.currentPlayerIsReady,
    required this.isStartingNextRound,
    required this.readyNames,
    required this.pendingNames,
    required this.onConfirmReady,
  });

  final int readyCount;
  final int expectedCount;
  final bool currentPlayerIsReady;
  final bool isStartingNextRound;
  final List<String> readyNames;
  final List<String> pendingNames;
  final VoidCallback onConfirmReady;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Próxima rodada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$readyCount de $expectedCount jogadores estão prontos.',
              style: const TextStyle(color: Colors.white70),
            ),
            if (readyNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Prontos: ${readyNames.join(', ')}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            if (pendingNames.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Faltam: ${pendingNames.join(', ')}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: currentPlayerIsReady || isStartingNextRound
                  ? null
                  : onConfirmReady,
              icon: Icon(
                currentPlayerIsReady ? Icons.check_circle : Icons.visibility,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  currentPlayerIsReady
                      ? 'Você está pronto'
                      : 'Estou pronto para a próxima rodada',
                ),
              ),
            ),
            if (isStartingNextRound) ...[
              const SizedBox(height: 12),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ] else ...[
              const SizedBox(height: 8),
              const Text(
                'A próxima rodada começa quando todos estiverem prontos.',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RematchCard extends StatelessWidget {
  const _RematchCard({
    required this.currentPlayer,
    required this.proposalCount,
    required this.expectedCount,
    required this.currentPlayerProposed,
    required this.isStartingRematch,
    required this.acceptedNames,
    required this.pendingNames,
    required this.onPropose,
  });

  final Player currentPlayer;
  final int proposalCount;
  final int expectedCount;
  final bool currentPlayerProposed;
  final bool isStartingRematch;
  final List<String> acceptedNames;
  final List<String> pendingNames;
  final VoidCallback onPropose;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF120818),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nova partida na mesma sala',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE7C76F),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Quando todos aceitarem, uma nova partida com os mesmos jogadores será iniciada.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            Text(
              '$proposalCount de $expectedCount jogadores aceitaram.',
              style: const TextStyle(color: Colors.white70),
            ),
            if (acceptedNames.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Aceitaram: ${acceptedNames.join(', ')}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            if (pendingNames.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Faltam: ${pendingNames.join(', ')}',
                style: const TextStyle(color: Colors.white60),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed:
                  currentPlayerProposed || isStartingRematch ? null : onPropose,
              icon: Icon(
                currentPlayerProposed ? Icons.check_circle : Icons.how_to_vote,
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  currentPlayerProposed
                      ? '${currentPlayer.name} aceitou'
                      : '${currentPlayer.name} propor nova partida',
                ),
              ),
            ),
            if (isStartingRematch) ...[
              const SizedBox(height: 8),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
