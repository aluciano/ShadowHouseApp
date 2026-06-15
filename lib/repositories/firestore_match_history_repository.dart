import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/match_history_entry.dart';
import 'firestore_serializers.dart';
import 'match_history_repository.dart';

class FirestoreMatchHistoryRepository implements MatchHistoryRepository {
  FirestoreMatchHistoryRepository({
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _matches {
    return firestore.collection('matches');
  }

  @override
  Future<List<MatchHistoryEntry>> loadHistory() async {
    final snapshot = await _matches
        .orderBy('finishedAt', descending: true)
        .limit(30)
        .get();

    final entries = snapshot.docs.map((doc) {
      return matchHistoryEntryFromFirestore(
        id: doc.id,
        data: doc.data(),
      );
    }).toList();

    return _withoutDuplicatedOnlineMatches(entries);
  }

  @override
  Future<void> saveMatch(MatchHistoryEntry entry) async {
    await _matches.doc(entry.id).set(
          matchHistoryEntryToFirestore(entry),
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
