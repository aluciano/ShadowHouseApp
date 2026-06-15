import 'package:flutter/material.dart';

import '../data/game_setup_rules.dart';
import '../models/match_history_entry.dart';
import '../models/match_play_mode.dart';
import '../repositories/repository_registry.dart';
import '../widgets/shadow_background.dart';

class MatchHistoryScreen extends StatefulWidget {
  const MatchHistoryScreen({super.key});

  @override
  State<MatchHistoryScreen> createState() => _MatchHistoryScreenState();
}

class _MatchHistoryScreenState extends State<MatchHistoryScreen> {
  late Future<List<MatchHistoryEntry>> historyFuture;

  @override
  void initState() {
    super.initState();

    historyFuture = RepositoryRegistry.matchHistory.loadHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        backgroundColor: const Color(0xFF120818),
      ),
      body: ShadowBackground(
        child: SafeArea(
          child: FutureBuilder<List<MatchHistoryEntry>>(
            future: historyFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final entries = snapshot.data!;

              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma partida finalizada ainda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                );
              }

              return ListView(
                children: [
                  const Text(
                    'Histórico de Partidas',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Partidas locais e online finalizadas ficarão salvas aqui.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...entries.map((entry) {
                    return Card(
                      color: const Color(0xFF221229),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _iconForPlayMode(entry.playMode),
                                  color: const Color(0xFFE7C76F),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _titleForEntry(entry),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(entry.finishedAt),
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Modo: ${_labelForPlayMode(entry.playMode)} - ${GameSetupRules.titleForMode(entry.gameMode)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Início: ${_formatTime(entry.startedAt)}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Fim: ${_formatTime(entry.finishedAt)}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tempo total: ${_formatDuration(entry.totalDuration)}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Vencedor${entry.winnerNames.length == 1 ? '' : 'es'}: ${entry.winnerNames.join(', ')}',
                              style: const TextStyle(
                                color: Color(0xFFE7C76F),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${entry.roundsPlayed} rodada${entry.roundsPlayed == 1 ? '' : 's'} jogada${entry.roundsPlayed == 1 ? '' : 's'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.playerNames.join('  |  '),
                              style: const TextStyle(color: Colors.white60),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _iconForPlayMode(MatchPlayMode playMode) {
    switch (playMode) {
      case MatchPlayMode.local:
        return Icons.phone_android;
      case MatchPlayMode.online:
        return Icons.public;
    }
  }

  String _labelForPlayMode(MatchPlayMode playMode) {
    switch (playMode) {
      case MatchPlayMode.local:
        return 'Local';
      case MatchPlayMode.online:
        return 'Online';
    }
  }

  String _titleForEntry(MatchHistoryEntry entry) {
    if (entry.roomCode == null) {
      return 'Partida ${_labelForPlayMode(entry.playMode)}';
    }

    return 'Sala ${entry.roomCode}';
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    }

    return '${hours}h ${minutes.toString().padLeft(2, '0')}min';
  }
}
