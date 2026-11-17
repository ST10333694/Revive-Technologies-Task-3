import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/freelancer.dart';

/// Freelancers the decorator hires for events (stored in Firestore).
class FreelancerRepository {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('freelancers');

  Stream<List<Freelancer>> watchAll() => _col.snapshots().map((snap) {
        final list = snap.docs.map(_fromDoc).toList();
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        return list;
      });

  Freelancer _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Freelancer(
      id: doc.id,
      name: d['name'] as String? ?? '',
      role: d['role'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      rateCents: (d['rateCents'] as num?)?.toInt() ?? 0,
      notes: d['notes'] as String? ?? '',
      active: d['active'] as bool? ?? true,
    );
  }

  /// A new freelancer has an empty id, so one is made here.
  Future<void> save(Freelancer f) {
    final ref = f.id.isEmpty ? _col.doc() : _col.doc(f.id);
    return ref.set({
      'name': f.name,
      'role': f.role,
      'phone': f.phone,
      'email': f.email,
      'rateCents': f.rateCents,
      'notes': f.notes,
      'active': f.active,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}