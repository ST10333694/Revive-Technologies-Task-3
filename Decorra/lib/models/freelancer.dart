import 'package:cloud_firestore/cloud_firestore.dart';

/// Business rule (FR44): events that need more freelancers.
/// - With catering: more than 100 guests.
/// - Without catering: more than 150 guests.
const cateringGuestLimit = 100;
const noCateringGuestLimit = 150;

bool guestCountNeedsFreelancers({required bool catering, required int guests}) =>
    guests > (catering ? cateringGuestLimit : noCateringGuestLimit);

/// A person the decorator hires per event. Freelancers have no app login.
class Freelancer {
  const Freelancer({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.role = '',
    this.rateCents = 0,
    this.notes = '',
    this.active = true,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;

  /// Usual fee per event, in cents. Used as the starting cost when assigning.
  final int rateCents;
  final String notes;
  final bool active;

  Freelancer copyWith({
    String? name,
    String? phone,
    String? email,
    String? role,
    int? rateCents,
    String? notes,
    bool? active,
  }) =>
      Freelancer(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        role: role ?? this.role,
        rateCents: rateCents ?? this.rateCents,
        notes: notes ?? this.notes,
        active: active ?? this.active,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'rateCents': rateCents,
        'notes': notes,
        'active': active,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static Freelancer fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Freelancer(
      id: doc.id,
      name: d['name'] as String? ?? '',
      phone: d['phone'] as String? ?? '',
      email: d['email'] as String? ?? '',
      role: d['role'] as String? ?? '',
      rateCents: (d['rateCents'] as num?)?.toInt() ?? 0,
      notes: d['notes'] as String? ?? '',
      active: d['active'] as bool? ?? true,
    );
  }
}

/// A freelancer assigned to one event (stored on the quote). The name is
/// copied in so the assignment still reads correctly if the record changes.
class FreelancerAssignment {
  const FreelancerAssignment({
    required this.freelancerId,
    required this.name,
    this.role = '',
    this.costCents = 0,
  });

  final String freelancerId;
  final String name;
  final String role;
  final int costCents;

  Map<String, dynamic> toMap() => {
        'freelancerId': freelancerId,
        'name': name,
        'role': role,
        'costCents': costCents,
      };

  static FreelancerAssignment fromMap(Map<String, dynamic> m) => FreelancerAssignment(
        freelancerId: m['freelancerId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        role: m['role'] as String? ?? '',
        costCents: (m['costCents'] as num?)?.toInt() ?? 0,
      );
}