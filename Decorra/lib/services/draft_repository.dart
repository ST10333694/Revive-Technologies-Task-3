import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/quote_draft.dart';

/// The client's private drafts: userSettings/{uid}/drafts.
class DraftRepository {
  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('userSettings')
        .doc(uid)
        .collection('drafts');
  }

  String newId() => FirebaseFirestore.instance.collection('userSettings').doc().id;

  Stream<List<QuoteDraft>> watchMine() {
    final col = _col;
    if (col == null) return Stream.value(const <QuoteDraft>[]);
    return col.snapshots().map((snap) {
      final list = snap.docs.map(QuoteDraft.fromDoc).toList();
      final now = DateTime.now();
      list.sort((a, b) => (b.updatedAt ?? now).compareTo(a.updatedAt ?? now));
      return list;
    });
  }

  Future<void> save(QuoteDraft draft) {
    final col = _col;
    if (col == null) return Future.error(StateError('Not signed in'));
    return col.doc(draft.id).set(draft.toMap());
  }

  Future<void> delete(String id) {
    final col = _col;
    if (col == null) return Future.value();
    return col.doc(id).delete();
  }
}