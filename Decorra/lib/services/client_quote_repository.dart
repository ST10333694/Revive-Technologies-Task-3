import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quote.dart';

/// The client's side of the "quotes" collection.
class ClientQuoteRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('quotes');

  String newId() => _col.doc().id;

  /// Only this client's quotes, newest first.
  Stream<List<Quote>> watchMine(String uid) =>
      _col.where('clientUid', isEqualTo: uid).snapshots().map((snap) {
        final list = snap.docs.map(Quote.fromDoc).toList();
        final now = DateTime.now();
        list.sort((a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now));
        return list;
      });

  /// One quote, live. Null when it no longer exists.
  Stream<Quote?> watchOne(String id) =>
      _col.doc(id).snapshots().map((d) => d.exists ? Quote.fromDoc(d) : null);

  Future<void> submit(Quote quote) => _col.doc(quote.id).set(quote.toMap());

  /// Only allowed by the rules while the quote is "sent".
  Future<void> respond(String id, {required bool approve}) => _col.doc(id).update({
        'status': approve ? 'approved' : 'declined',
        'updatedAt': FieldValue.serverTimestamp(),
      });
}