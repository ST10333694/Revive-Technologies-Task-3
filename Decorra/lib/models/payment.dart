import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  const Payment({
    required this.id,
    required this.quoteId,
    required this.amountCents,
    this.method = 'EFT',
    this.reference = '',
    required this.paidAt,
    this.recordedBy = '',
  });

  final String id;
  final String quoteId;
  final int amountCents;
  final String method;
  final String reference;
  final DateTime paidAt;
  final String recordedBy;

  Map<String, dynamic> toMap() => {
        'quoteId': quoteId,
        'amountCents': amountCents,
        'method': method,
        'reference': reference,
        'paidAt': Timestamp.fromDate(paidAt),
        'recordedBy': recordedBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static Payment fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Payment(
      id: doc.id,
      quoteId: d['quoteId'] as String? ?? '',
      amountCents: (d['amountCents'] as num?)?.toInt() ?? 0,
      method: d['method'] as String? ?? 'EFT',
      reference: d['reference'] as String? ?? '',
      paidAt: (d['paidAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      recordedBy: d['recordedBy'] as String? ?? '',
    );
  }
}