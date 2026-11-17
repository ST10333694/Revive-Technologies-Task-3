import 'package:decorra/models/decor_event.dart';
import 'package:decorra/models/freelancer.dart';
import 'package:decorra/models/quote.dart';
import 'package:decorra/services/quote_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

Quote makeQuote({
  String id = 'abcdef123456',
  QuoteStatus status = QuoteStatus.newRequest,
  int guests = 50,
  bool catering = false,
  int transportCents = 0,
  int workingCents = 0,
  int discountPercent = 0,
  List<FreelancerAssignment> freelancers = const [],
}) =>
    Quote(
      id: id,
      clientName: 'Thandi Dlamini',
      eventType: 'Wedding',
      date: DateTime(2027, 3, 20),
      guests: guests,
      catering: catering,
      transportCents: transportCents,
      workingCents: workingCents,
      discountPercent: discountPercent,
      freelancers: freelancers,
      status: status,
      lines: const [
        EventLine(itemId: 'a', name: 'Arch', unitCents: 50000, quantity: 2),
        EventLine(itemId: 'b', name: 'Chair', unitCents: 2500, quantity: 4),
      ],
    );

void main() {
  group('Quote pricing', () {
    test('subtotal adds every line', () {
      expect(makeQuote().subtotalCents, 110000);
    });

    test('total includes VAT', () {
      expect(makeQuote().totalCents, 126500);
    });

    test('total includes fees and discount', () {
      final q = makeQuote(
        transportCents: 5000,
        workingCents: 5000,
        discountPercent: 10,
      );
      expect(q.price.base, 120000);
      expect(q.price.discount, 12000);
      expect(q.totalCents, 124200);
    });

    test('freelancer costs are not part of the client price', () {
      final plain = makeQuote();
      final withStaff = makeQuote(freelancers: const [
        FreelancerAssignment(
            freelancerId: 'f1', name: 'Sipho', costCents: 80000),
      ]);
      expect(withStaff.freelancerCostCents, 80000);
      expect(withStaff.totalCents, plain.totalCents);
    });
  });

  group('Quote rules', () {
    test('needs extra freelancers over the guest limit', () {
      expect(makeQuote(guests: 120, catering: true).needsExtraFreelancers,
          isTrue);
      expect(makeQuote(guests: 120, catering: false).needsExtraFreelancers,
          isFalse);
    });

    test('a new quote starts as a request with a 40% deposit', () {
      final q = makeQuote();
      expect(q.status, QuoteStatus.newRequest);
      expect(q.depositPercent, 40);
    });

    test('copyWith changes the status and keeps everything else', () {
      final q = makeQuote().copyWith(status: QuoteStatus.sent);
      expect(q.status, QuoteStatus.sent);
      expect(q.clientName, 'Thandi Dlamini');
      expect(q.lines.length, 2);
      expect(q.id, 'abcdef123456');
    });

    test('every status has a label', () {
      for (final s in QuoteStatus.values) {
        expect(s.label, isNotEmpty);
      }
      expect(QuoteStatus.approved.label, 'APPROVED');
    });
  });

  group('canDownloadQuotation', () {
    test('is allowed once the client has approved', () {
      for (final s in [
        QuoteStatus.approved,
        QuoteStatus.depositPaid,
        QuoteStatus.eventInProgress,
        QuoteStatus.completed,
      ]) {
        expect(canDownloadQuotation(makeQuote(status: s)), isTrue, reason: '$s');
      }
    });

    test('is not allowed before approval, or after a decline', () {
      for (final s in [
        QuoteStatus.newRequest,
        QuoteStatus.inProgress,
        QuoteStatus.draft,
        QuoteStatus.sent,
        QuoteStatus.declined,
      ]) {
        expect(canDownloadQuotation(makeQuote(status: s)), isFalse,
            reason: '$s');
      }
    });
  });

  group('quote reference and file name', () {
    test('uses the first 8 characters of the id, in capitals', () {
      expect(quoteReference(makeQuote()), 'QUO-ABCDEF12');
      expect(quoteFileName(makeQuote()), 'QUO-ABCDEF12.pdf');
    });

    test('copes with a short id', () {
      expect(quoteReference(makeQuote(id: 'ab')), 'QUO-AB');
    });
  });
}