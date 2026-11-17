import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin actions on client accounts. Kept in one place so the rules file
/// only needs to allow decorators to write the "disabled" field.
class ClientAdminRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  /// Every client, newest first is not meaningful here — sort by name in the UI.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchClients() =>
      _users.where('role', isEqualTo: 'client').snapshots();

  Future<void> setDisabled(String uid, bool disabled) =>
      _users.doc(uid).update({
        'disabled': disabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> updateContact(
    String uid, {
    required String firstName,
    required String lastName,
    required String phone,
  }) =>
      _users.doc(uid).update({
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'updatedAt': FieldValue.serverTimestamp(),
      });
}