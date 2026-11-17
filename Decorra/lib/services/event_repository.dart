import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/decor_event.dart';

class EventRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('events');

  /// Made up front, so a save that is retried overwrites instead of duplicating.
  String newId() => _col.doc().id;

  /// Newest event date first.
  Stream<List<DecorEvent>> watchAll() => _col.snapshots().map((snap) {
        final list = snap.docs.map(DecorEvent.fromDoc).toList();
        list.sort((a, b) => b.date.compareTo(a.date));
        return list;
      });

  Future<void> save(DecorEvent event) =>
      _col.doc(event.id).set(event.toMap(), SetOptions(merge: true));

  Future<void> setStatus(String id, EventStatus status) => _col.doc(id).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> delete(String id) => _col.doc(id).delete();
}