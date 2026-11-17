import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quote.dart';

class QuoteRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('quotes');

  String newId() => _col.doc().id;

  /// Newest first.
  Stream<List<Quote>> watchAll() => _col.snapshots().map((snap) {
        final list = snap.docs.map(Quote.fromDoc).toList();
        final now = DateTime.now();
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  Future<Quote?> get(String id) async {
    final doc = await _col.doc(id).get();
    return doc.exists ? Quote.fromDoc(doc) : null;
  }

  Future<void> save(Quote quote) =>
      _col.doc(quote.id).set(quote.toMap(), SetOptions(merge: true));

  Future<void> delete(String id) => _col.doc(id).delete();
}