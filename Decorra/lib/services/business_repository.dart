import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/business.dart';

/// The business's own details. Two small documents in the "business" collection.
class BusinessRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _profile => _db.collection('business').doc('profile');
  DocumentReference<Map<String, dynamic>> get _payment => _db.collection('business').doc('payment');

  Stream<BusinessProfile> watchProfile() =>
      _profile.snapshots().map((d) => BusinessProfile.fromMap(d.data() ?? {}));

  Future<BusinessProfile> getProfile() async =>
      BusinessProfile.fromMap((await _profile.get()).data() ?? {});

  Future<void> saveProfile(BusinessProfile p) =>
      _profile.set(p.toMap(), SetOptions(merge: true));

  Future<PaymentDetails> getPayment() async =>
      PaymentDetails.fromMap((await _payment.get()).data() ?? {});

  Future<void> savePayment(PaymentDetails p) =>
      _payment.set(p.toMap(), SetOptions(merge: true));
}