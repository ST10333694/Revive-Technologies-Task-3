import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment.dart';

class PaymentRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('payments');

  String newId() => _col.doc().id;

  Stream<List<Payment>> watchForQuote(String quoteId) => _col
      .where('quoteId', isEqualTo: quoteId)
      .snapshots()
      .map((snap) {
        final list = snap.docs.map(Payment.fromDoc).toList();
        list.sort((a, b) => b.paidAt.compareTo(a.paidAt));
        return list;
      });

  Future<void> record(Payment p) => _col.doc(p.id).set(p.toMap());

  Future<void> delete(String id) => _col.doc(id).delete();
}