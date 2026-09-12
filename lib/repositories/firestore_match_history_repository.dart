import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/match_history_entry.dart';
import 'firestore_serializers.dart';
import 'match_history_repository.dart';

class FirestoreMatchHistoryRepository implements MatchHistoryRepository {
  FirestoreMatchHistoryRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  CollectionReference<Map<String, dynamic>> get _matches {
    return firestore.collection('matches');
  }

  @override
  Future<List<MatchHistoryEntry>> loadHistory() async {
    final currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) {
      return const [];
    }

    final snapshot = await _matches
        .where('participantUids', arrayContains: currentUserId)
        .get();

    final entries = snapshot.docs.map((doc) {
      return matchHistoryEntryFromFirestore(id: doc.id, data: doc.data());
    }).toList();

    entries.sort((first, second) {
      return second.finishedAt.compareTo(first.finishedAt);
    });

    return _withoutDuplicatedOnlineMatches(entries).take(30).toList();
  }

  @override
  Future<void> saveMatch(MatchHistoryEntry entry) async {
    final currentUserId = auth.currentUser?.uid;
    final participantUids = {...entry.participantUids, ?currentUserId}.toList();

    await _matches
        .doc(entry.id)
        .set(
          matchHistoryEntryToFirestore(
            MatchHistoryEntry(
              id: entry.id,
              playMode: entry.playMode,
              gameMode: entry.gameMode,
              startedAt: entry.startedAt,
              finishedAt: entry.finishedAt,
              playerNames: entry.playerNames,
              winnerNames: entry.winnerNames,
              roundsPlayed: entry.roundsPlayed,
              participantUids: participantUids,
              roomCode: entry.roomCode,
            ),
          ),
        );
  }

  List<MatchHistoryEntry> _withoutDuplicatedOnlineMatches(
    List<MatchHistoryEntry> entries,
  ) {
    final entriesByKey = <String, MatchHistoryEntry>{};

    for (final entry in entries) {
      entriesByKey.putIfAbsent(_deduplicationKey(entry), () => entry);
    }

    return entriesByKey.values.toList();
  }

  String _deduplicationKey(MatchHistoryEntry entry) {
    return [
      entry.playMode.name,
      entry.roomCode ?? entry.id,
      entry.startedAt.microsecondsSinceEpoch,
    ].join('_');
  }
}
