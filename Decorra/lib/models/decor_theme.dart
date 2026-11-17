import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeItem {
  const ThemeItem({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  Map<String, dynamic> toMap() => {'itemId': itemId, 'quantity': quantity};

  static ThemeItem fromMap(Map<String, dynamic> map) => ThemeItem(
    itemId: map['itemId'] as String? ?? '',
    quantity: (map['quantity'] as num?)?.toInt() ?? 0,
  );
}

class DecorTheme {
  const DecorTheme({
    required this.id,
    required this.name,
    required this.description,
    this.tags = const [],
    this.imageUrl,
    this.items = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> tags;

  /// A public https link. Everyone sees the same photo, on every device.
  final String? imageUrl;
  final List<ThemeItem> items;

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'tags': tags,
    'imageUrl': imageUrl,
    'items': items.map((e) => e.toMap()).toList(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static DecorTheme fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return DecorTheme(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      tags: (data['tags'] as List<dynamic>? ?? const []).cast<String>(),
      imageUrl: data['imageUrl'] as String?,
      items: (data['items'] as List<dynamic>? ?? const [])
          .map((e) => ThemeItem.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
