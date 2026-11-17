import 'package:cloud_firestore/cloud_firestore.dart';

import 'decor_event.dart';
import 'freelancer.dart';

enum QuoteStatus {
  newRequest,
  inProgress,
  draft,
  sent,
  approved,
  declined,
  depositPaid,
  eventInProgress,
  completed,
}

extension QuoteStatusText on QuoteStatus {
  String get label => switch (this) {
        QuoteStatus.newRequest => 'NEW',
        QuoteStatus.inProgress => 'IN PROGRESS',
        QuoteStatus.draft => 'DRAFT',
        QuoteStatus.sent => 'SENT',
        QuoteStatus.approved => 'APPROVED',
        QuoteStatus.declined => 'DECLINED',
        QuoteStatus.depositPaid => 'DEPOSIT PAID',
        QuoteStatus.eventInProgress => 'EVENT IN PROGRESS',
        QuoteStatus.completed => 'COMPLETE',
      };
}

class Quote {
  const Quote({
    required this.id,
    required this.clientName,
    this.clientUid = '',
    this.clientEmail = '',
    this.clientPhone = '',
    this.themeName = '',
    required this.eventType,
    required this.date,
    this.guests = 0,
    this.location = '',
    this.venue = '',
    this.catering = false,
    this.notes = '',
    this.lines = const [],
    this.depositPercent = 40,
    this.transportCents = 0,
    this.workingCents = 0,
    this.discountPercent = 0,
    this.freelancers = const [],
    this.status = QuoteStatus.newRequest,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String clientName;

  /// The client's Firebase user id. Empty for quotes the decorator added by hand.
  final String clientUid;
  final String clientEmail;
  final String clientPhone;
  final String themeName;
  final String eventType;
  final DateTime date;
  final int guests;
  final String location;

  /// The venue name, separate from the general location/area.
  final String venue;

  /// Whether the client wants catering. Drives the freelancer guest rule.
  final bool catering;
  final String notes;
  final List<EventLine> lines;
  final int depositPercent;

  /// Fees the decorator adds, in cents, and a percentage taken off before VAT.
  final int transportCents;
  final int workingCents;
  final int discountPercent;

  /// Freelancers the decorator has assigned. Their costs are internal only
  /// and are not part of the client's price.
  final List<FreelancerAssignment> freelancers;
  final QuoteStatus status;

  /// null until the server has stamped a brand-new quote.
  final DateTime? createdAt;

  /// When the quote last changed. Read-only; the server sets it on every save.
  final DateTime? updatedAt;

  int get subtotalCents => lines.fold(0, (total, l) => total + l.lineCents);
  ({int base, int discount, int vat, int total}) get price => priceUp(
        subtotalCents,
        transportCents,
        workingCents,
        discountPercent: discountPercent,
      );
  int get totalCents => price.total;

  bool get needsExtraFreelancers =>
      guestCountNeedsFreelancers(catering: catering, guests: guests);
  int get freelancerCostCents => freelancers.fold(0, (total, f) => total + f.costCents);

  Quote copyWith({
    List<EventLine>? lines,
    String? notes,
    QuoteStatus? status,
    int? transportCents,
    int? workingCents,
    int? discountPercent,
    List<FreelancerAssignment>? freelancers,
  }) =>
      Quote(
        id: id,
        clientName: clientName,
        clientUid: clientUid,
        clientEmail: clientEmail,
        clientPhone: clientPhone,
        themeName: themeName,
        eventType: eventType,
        date: date,
        guests: guests,
        location: location,
        venue: venue,
        catering: catering,
        notes: notes ?? this.notes,
        lines: lines ?? this.lines,
        depositPercent: depositPercent,
        transportCents: transportCents ?? this.transportCents,
        workingCents: workingCents ?? this.workingCents,
        discountPercent: discountPercent ?? this.discountPercent,
        freelancers: freelancers ?? this.freelancers,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'clientName': clientName,
        'clientUid': clientUid,
        'clientEmail': clientEmail,
        'clientPhone': clientPhone,
        'themeName': themeName,
        'eventType': eventType,
        'date': Timestamp.fromDate(date),
        'guests': guests,
        'location': location,
        'venue': venue,
        'catering': catering,
        'notes': notes,
        'lines': lines.map((l) => l.toMap()).toList(),
        'depositPercent': depositPercent,
        'transportCents': transportCents,
        'workingCents': workingCents,
        'discountPercent': discountPercent,
        'freelancers': freelancers.map((f) => f.toMap()).toList(),
        'needsExtraFreelancers': needsExtraFreelancers,
        'status': status.name,
        'totalCents': totalCents,
        'updatedAt': FieldValue.serverTimestamp(),
        if (createdAt == null) 'createdAt': FieldValue.serverTimestamp(),
      };

  static Quote fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Quote(
      id: doc.id,
      clientName: d['clientName'] as String? ?? '',
      clientUid: d['clientUid'] as String? ?? '',
      clientEmail: d['clientEmail'] as String? ?? '',
      clientPhone: d['clientPhone'] as String? ?? '',
      themeName: d['themeName'] as String? ?? '',
      eventType: d['eventType'] as String? ?? 'Other',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      guests: (d['guests'] as num?)?.toInt() ?? 0,
      location: d['location'] as String? ?? '',
      venue: d['venue'] as String? ?? '',
      catering: d['catering'] as bool? ?? false,
      notes: d['notes'] as String? ?? '',
      lines: (d['lines'] as List<dynamic>? ?? const [])
          .map((e) => EventLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      depositPercent: (d['depositPercent'] as num?)?.toInt() ?? 40,
      transportCents: (d['transportCents'] as num?)?.toInt() ?? 0,
      workingCents: (d['workingCents'] as num?)?.toInt() ?? 0,
      discountPercent: (d['discountPercent'] as num?)?.toInt() ?? 0,
      freelancers: (d['freelancers'] as List<dynamic>? ?? const [])
          .map((e) => FreelancerAssignment.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      status: QuoteStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => QuoteStatus.newRequest,
      ),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}