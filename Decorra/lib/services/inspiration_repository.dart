import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The themes a client has bookmarked ("My Inspiration").
class InspirationRepository {
  DocumentReference<Map<String, dynamic>>? get _doc {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance.collection('userSettings').doc(uid);
  }

  Stream<Set<String>> watchSaved() {
    final doc = _doc;
    if (doc == null) return Stream.value(<String>{});
    return doc.snapshots().map((s) =>
        ((s.data()?['savedThemeIds'] as List<dynamic>?) ?? const [])
            .cast<String>()
            .toSet());
  }

  Future<void> toggle(String themeId, {required bool save}) {
    final doc = _doc;
    if (doc == null) return Future.error(StateError('Not signed in'));
    return doc.set({
      'savedThemeIds': save
          ? FieldValue.arrayUnion([themeId])
          : FieldValue.arrayRemove([themeId]),
    }, SetOptions(merge: true));
  }
}