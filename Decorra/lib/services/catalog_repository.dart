import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/decor_item.dart';
import '../models/decor_theme.dart';

/// Themes (the portfolio) and items (the catalog), shared by every device
/// through Firestore. Clients read them; decorators change them.
class CatalogRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _themes =>
      _db.collection('themes');
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');

  /// Ids are made up front, so a save that is retried after a bad connection
  /// overwrites the same document instead of creating a duplicate.
  String newThemeId() => _themes.doc().id;
  String newItemId() => _items.doc().id;

  Stream<List<DecorTheme>> watchThemes() => _themes.snapshots().map((snap) {
    final list = snap.docs.map(DecorTheme.fromDoc).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });

  Stream<List<DecorItem>> watchItems() => _items.snapshots().map((snap) {
    final list = snap.docs.map(DecorItem.fromDoc).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  });

  Future<void> saveTheme(DecorTheme theme) =>
      _themes.doc(theme.id).set(theme.toMap(), SetOptions(merge: true));

  Future<void> saveItem(DecorItem item) =>
      _items.doc(item.id).set(item.toMap(), SetOptions(merge: true));

  /// Items that belonged only to this theme stay in the catalog and become
  /// available everywhere (same behaviour as the Android app).
  Future<void> deleteTheme(String id) async {
    final batch = _db.batch();
    final owned = await _items.where('themeId', isEqualTo: id).get();
    for (final doc in owned.docs) {
      batch.update(doc.reference, {'themeId': null});
    }
    batch.delete(_themes.doc(id));
    await batch.commit();
  }

  /// Also takes the item out of every theme's item list.
  Future<void> deleteItem(String id) async {
    final batch = _db.batch();
    final themes = await _themes.get();
    for (final doc in themes.docs) {
      final list = (doc.data()['items'] as List<dynamic>? ?? const []);
      final kept = list.where((e) => (e as Map)['itemId'] != id).toList();
      if (kept.length != list.length) {
        batch.update(doc.reference, {'items': kept});
      }
    }
    batch.delete(_items.doc(id));
    await batch.commit();
  }
}
