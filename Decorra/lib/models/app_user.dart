import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { client, decorator }

/// A person's profile, stored in the Firestore "users" collection
/// (same layout as the Android app, so existing accounts keep working).
class AppUser {
  const AppUser({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    this.pushMessages = true,
    this.disabled = false,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final bool pushMessages;

  /// A decorator can turn a client account off without deleting it,
  /// so quotes and history stay intact.
  final bool disabled;

  String get fullName => '$firstName $lastName'.trim();

  static AppUser? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (!doc.exists || data == null) return null;
    return AppUser(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] == 'decorator' ? UserRole.decorator : UserRole.client,
      pushMessages: data['pushMessages'] as bool? ?? true,
      disabled: data['disabled'] as bool? ?? false,
    );
  }
}