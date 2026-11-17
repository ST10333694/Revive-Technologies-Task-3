import 'package:cloud_firestore/cloud_firestore.dart';

const itemCategories = ['Backdrops', 'Floral', 'Furniture', 'Lighting', 'Other'];

/// themeId == null means the item is available inside every theme.
/// rentable == true also lets clients rent it on its own.
/// stock == null means the quantity is not tracked.
class DecorItem {
  const DecorItem({
    required this.id,
    required this.name,
    required this.priceCents,
    this.category = 'Other',
    this.themeId,
    this.imageUrl,
    this.rentable = false,
    this.stock,
    this.minStock = 0,
    this.unitCostCents = 0,
  });

  static const maxQuantity = 9999;

  final String id;
  final String name;
  final int priceCents;
  final String category;
  final String? themeId;
  final String? imageUrl;
  final bool rentable;
  final int? stock;
  final int minStock;
  final int unitCostCents;

  int get maxOrderable => (stock ?? maxQuantity).clamp(0, maxQuantity).toInt();

  Map<String, dynamic> toMap() => {
        'name': name,
        'priceCents': priceCents,
        'category': category,
        'themeId': themeId,
        'imageUrl': imageUrl,
        'rentable': rentable,
        'stock': stock,
        'minStock': minStock,
        'unitCostCents': unitCostCents,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static DecorItem fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return DecorItem(
      id: doc.id,
      name: d['name'] as String? ?? '',
      priceCents: (d['priceCents'] as num?)?.toInt() ?? 0,
      category: d['category'] as String? ?? 'Other',
      themeId: d['themeId'] as String?,
      imageUrl: d['imageUrl'] as String?,
      rentable: d['rentable'] as bool? ?? false,
      stock: (d['stock'] as num?)?.toInt(),
      minStock: (d['minStock'] as num?)?.toInt() ?? 0,
      unitCostCents: (d['unitCostCents'] as num?)?.toInt() ?? 0,
    );
  }
}

/// "R1 234.50" style text. Whole rand amounts drop the cents.
String moneyText(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final rand = abs ~/ 100;
  final rest = abs % 100;
  final digits = rand.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  final centsPart = rest == 0 ? '' : '.${rest.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}R$buffer$centsPart';
}