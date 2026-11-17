import 'dart:typed_data';

import 'package:decorra/models/business.dart';
import 'package:decorra/models/decor_event.dart';
import 'package:decorra/models/quote.dart';
import 'package:decorra/services/quote_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

Quote approvedQuote({int lineCount = 2}) => Quote(
      id: 'abcdef123456',
      clientName: 'Thandi Dlamini',
      clientEmail: 'thandi@example.com',
      clientPhone: '082 000 0000',
      themeName: 'Floral Arch Wedding',
      eventType: 'Wedding',
      date: DateTime(2027, 3, 20),
      guests: 80,
      venue: 'Rose Gardens',
      location: 'Hammanskraal',
      notes: 'Please set up from 8am.',
      transportCents: 5000,
      workingCents: 5000,
      discountPercent: 5,
      status: QuoteStatus.approved,
      lines: [
        for (var i = 0; i < lineCount; i++)
          EventLine(
            itemId: 'i$i',
            name: 'Item $i',
            unitCents: 2500,
            quantity: 2,
          ),
      ],
    );

/// Every PDF file starts with the text "%PDF".
bool looksLikePdf(Uint8List bytes) =>
    bytes.length > 4 &&
    bytes[0] == 0x25 &&
    bytes[1] == 0x50 &&
    bytes[2] == 0x44 &&
    bytes[3] == 0x46;

void main() {
  test('builds a PDF with only the quote', () async {
    final bytes = await buildQuotePdf(approvedQuote());
    expect(looksLikePdf(bytes), isTrue);
    expect(bytes.length, greaterThan(1000));
  });

  test('builds a PDF with business and bank details', () async {
    final bytes = await buildQuotePdf(
      approvedQuote(),
      business: const BusinessProfile(
        name: 'Bees Events',
        email: 'hello@example.com',
        phone: '012 000 0000',
        address: 'Hammanskraal',
      ),
      payment: const PaymentDetails(
        accountHolder: 'Bees Events',
        bankName: 'FNB',
        accountNumber: '123456789',
        branchCode: '250655',
        reference: 'QUO-ABCDEF12',
      ),
      issuedAt: DateTime(2026, 11, 16),
    );
    expect(looksLikePdf(bytes), isTrue);
  });

  test('builds a PDF for a quote with no items', () async {
    final bytes = await buildQuotePdf(approvedQuote(lineCount: 0));
    expect(looksLikePdf(bytes), isTrue);
  });

  test('a long quote runs onto more pages without failing', () async {
    final short = await buildQuotePdf(approvedQuote(lineCount: 2));
    final long = await buildQuotePdf(approvedQuote(lineCount: 120));
    expect(looksLikePdf(long), isTrue);
    expect(long.length, greaterThan(short.length));
  });
}