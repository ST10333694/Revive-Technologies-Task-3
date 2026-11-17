import 'package:cloud_firestore/cloud_firestore.dart';

import 'decor_event.dart';

/// A quote request the client has started but not sent yet.
class QuoteDraft {
  const QuoteDraft({
    required this.id,
    required this.themeId,
    required this.themeName,
    this.lines = const [],
    this.eventType = 'Wedding',
    this.date,
    this.guests = 0,
    this.location = '',
    this.venue = '',
    this.catering = false,
    this.notes = '',
    this.updatedAt,
  });

  final String id;
  final String themeId;
  final String themeName;
  final List<EventLine> lines;
  final String eventType;
  final DateTime? date;
  final int guests;
  final String location;
  final String venue;
  final bool catering;
  final String notes;
  final DateTime? updatedAt;

  int get subtotalCents => lines.fold(0, (total, l) => total + l.lineCents);

  QuoteDraft copyWith({
    List<EventLine>? lines,
    String? eventType,
    DateTime? date,
    int? guests,
    String? location,
    String? venue,
    bool? catering,
    String? notes,
  }) =>
      QuoteDraft(
        id: id,
        themeId: themeId,
        themeName: themeName,
        lines: lines ?? this.lines,
        eventType: eventType ?? this.eventType,
        date: date ?? this.date,
        guests: guests ?? this.guests,
        location: location ?? this.location,
        venue: venue ?? this.venue,
        catering: catering ?? this.catering,
        notes: notes ?? this.notes,
        updatedAt: updatedAt,
      );

  Map<String, dynamic> toMap() => {
        'themeId': themeId,
        'themeName': themeName,
        'lines': lines.map((l) => l.toMap()).toList(),
        'eventType': eventType,
        'date': date == null ? null : Timestamp.fromDate(date!),
        'guests': guests,
        'location': location,
        'venue': venue,
        'catering': catering,
        'notes': notes,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static QuoteDraft fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return QuoteDraft(
      id: doc.id,
      themeId: d['themeId'] as String? ?? '',
      themeName: d['themeName'] as String? ?? '',
      lines: (d['lines'] as List<dynamic>? ?? const [])
          .map((e) => EventLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      eventType: d['eventType'] as String? ?? 'Wedding',
      date: (d['date'] as Timestamp?)?.toDate(),
      guests: (d['guests'] as num?)?.toInt() ?? 0,
      location: d['location'] as String? ?? '',
      venue: d['venue'] as String? ?? '',
      catering: d['catering'] as bool? ?? false,
      notes: d['notes'] as String? ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}