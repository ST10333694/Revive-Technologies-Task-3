import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/quote.dart';

/// Which quote statuses count as "committing" the stock for the event date.
/// Drafts and sent quotes do not reserve inventory yet.
const _committedStatuses = ['approved', 'depositPaid', 'eventInProgress'];

/// Reserves are computed on demand from committed quotes on the same date.
/// There is no stored counter anywhere, so nothing can drift.
class StockService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// itemId -> quantity already committed by other quotes on [date].
  /// [excludeQuoteId] lets the editor ignore the quote it is currently editing.
  Future<Map<String, int>> reservedOn(DateTime date, {String? excludeQuoteId}) async {
    final day = DateTime(date.year, date.month, date.day);
    final next = day.add(const Duration(days: 1));

    final snap = await _db
        .collection('quotes')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(day))
        .where('date', isLessThan: Timestamp.fromDate(next))
        .where('status', whereIn: _committedStatuses)
        .get();

    final reserved = <String, int>{};
    for (final doc in snap.docs) {
      if (doc.id == excludeQuoteId) continue;
      final q = Quote.fromDoc(doc);
      for (final line in q.lines) {
        reserved[line.itemId] = (reserved[line.itemId] ?? 0) + line.quantity;
      }
    }
    return reserved;
  }
}