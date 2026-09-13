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

  CollectionReference<Map<String, dynamic>> _userMatches(String userId) {
    return firestore.collection('users').doc(userId).collection('matches');
  }

  @override
  Future<List<MatchHistoryEntry>> loadHistory() async {
    final currentUserId = auth.currentUser?.uid;

    if (currentUserId == null) {
      return const [];
    }

    final snapshot = await _userMatches(currentUserId)
        .orderBy('finishedAt', descending: true)
        .limit(30)
        .get();

    final entries = snapshot.docs.map((doc) {
      return matchHistoryEntryFromFirestore(id: doc.id, data: doc.data());
    }).toList();

    return _withoutDuplicatedOnlineMatches(entries);
  }

  @override
  Future<void> saveMatch(MatchHistoryEntry entry) async {
    final currentUserId = auth.currentUser?.uid;
    final participantUids = {...entry.participantUids, ?currentUserId}.toList();

    final entryToSave = MatchHistoryEntry(
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
    );
    final data = matchHistoryEntryToFirestore(entryToSave);
    final batch = firestore.batch();

    for (final participantUid in participantUids) {
      batch.set(_userMatches(participantUid).doc(entry.id), data);
    }

    await batch.commit();
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
