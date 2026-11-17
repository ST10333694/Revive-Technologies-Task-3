import 'package:cloud_firestore/cloud_firestore.dart';

enum EventStatus { draft, published }

const eventTypes = [
  'Wedding',
  'Birthday',
  'Corporate Event',
  'Baby Shower',
  'Engagement',
  'Other',
];

const vatPercent = 15;

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "15 Sep 2025"
String dateText(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// "125", "125.5" and "125,50" all work. Empty text counts as 0.
/// Returns null when the text is not a number.
int? randsToCents(String text) {
  if (text.trim().isEmpty) return 0;
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value == null ? null : (value * 100).round();
}

/// Items + fees, less any percentage discount, then VAT on what is left.
({int base, int discount, int vat, int total}) priceUp(
  int itemsCents,
  int transportCents,
  int workingCents, {
  int discountPercent = 0,
}) {
  final base = itemsCents + transportCents + workingCents;
  final percent = discountPercent.clamp(0, 100).toInt();
  final discount = (base * percent + 50) ~/ 100;
  final taxable = base - discount;
  final vat = (taxable * vatPercent + 50) ~/ 100;
  return (base: base, discount: discount, vat: vat, total: taxable + vat);
}

/// One chosen item. The name and price are copied in, so changing or deleting
/// the item in the catalog later does not change a saved event or quote.
class EventLine {
  const EventLine({
    required this.itemId,
    required this.name,
    required this.unitCents,
    required this.quantity,
  });

  final String itemId;
  final String name;
  final int unitCents;
  final int quantity;

  int get lineCents => unitCents * quantity;

  EventLine withQuantity(int q) =>
      EventLine(itemId: itemId, name: name, unitCents: unitCents, quantity: q);

  Map<String, dynamic> toMap() => {
        'itemId': itemId,
        'name': name,
        'unitCents': unitCents,
        'quantity': quantity,
      };

  static EventLine fromMap(Map<String, dynamic> m) => EventLine(
        itemId: m['itemId'] as String? ?? '',
        name: m['name'] as String? ?? '',
        unitCents: (m['unitCents'] as num?)?.toInt() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
      );
}

class DecorEvent {
  const DecorEvent({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    required this.location,
    this.description = '',
    this.coverUrl,
    this.photoUrls = const [],
    this.themeId,
    this.themeName,
    this.lines = const [],
    this.transportCents = 0,
    this.workingCents = 0,
    this.status = EventStatus.published,
  });

  final String id;
  final String name;
  final String type;
  final DateTime date;
  final String location;
  final String description;
  final String? coverUrl;
  final List<String> photoUrls;

  /// All photos; an older event with only a cover counts that as photo 1.
  List<String> get photos =>
      photoUrls.isNotEmpty ? photoUrls : (coverUrl == null ? const [] : [coverUrl!]);
  final String? themeId;
  final String? themeName;
  final List<EventLine> lines;
  final int transportCents;
  final int workingCents;
  final EventStatus status;

  bool get isPublished => status == EventStatus.published;
  int get itemsCents => lines.fold(0, (total, l) => total + l.lineCents);
  int get totalCents => priceUp(itemsCents, transportCents, workingCents).total;

  DecorEvent copyWith({
    String? name,
    String? type,
    DateTime? date,
    String? location,
    String? description,
    String? coverUrl,
    List<String>? photoUrls,
    bool clearCover = false,
    EventStatus? status,
  }) =>
      DecorEvent(
        id: id,
        name: name ?? this.name,
        type: type ?? this.type,
        date: date ?? this.date,
        location: location ?? this.location,
        description: description ?? this.description,
        coverUrl: clearCover ? null : (coverUrl ?? this.coverUrl),
        photoUrls: photoUrls ?? this.photoUrls,
        themeId: themeId,
        themeName: themeName,
        lines: lines,
        transportCents: transportCents,
        workingCents: workingCents,
        status: status ?? this.status,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'type': type,
        'date': Timestamp.fromDate(date),
        'location': location,
        'description': description,
        'coverUrl': coverUrl,
        'photoUrls': photoUrls,
        'themeId': themeId,
        'themeName': themeName,
        'lines': lines.map((l) => l.toMap()).toList(),
        'transportCents': transportCents,
        'workingCents': workingCents,
        'totalCents': totalCents,
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DecorEvent fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return DecorEvent(
      id: doc.id,
      name: d['name'] as String? ?? '',
      type: d['type'] as String? ?? 'Other',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: d['location'] as String? ?? '',
      description: d['description'] as String? ?? '',
      coverUrl: d['coverUrl'] as String?,
      photoUrls: (d['photoUrls'] as List<dynamic>? ?? const []).whereType<String>().toList(),
      themeId: d['themeId'] as String?,
      themeName: d['themeName'] as String?,
      lines: (d['lines'] as List<dynamic>? ?? const [])
          .map((e) => EventLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      transportCents: (d['transportCents'] as num?)?.toInt() ?? 0,
      workingCents: (d['workingCents'] as num?)?.toInt() ?? 0,
      status: EventStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => EventStatus.published,
      ),
    );
  }
}