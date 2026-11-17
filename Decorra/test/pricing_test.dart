import 'package:decorra/models/decor_event.dart';
import 'package:decorra/models/decor_item.dart';
import 'package:decorra/models/freelancer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('priceUp', () {
    test('adds fees, then 15% VAT', () {
      final p = priceUp(100000, 5000, 5000);
      expect(p.base, 110000);
      expect(p.discount, 0);
      expect(p.vat, 16500);
      expect(p.total, 126500);
    });

    test('takes the discount off before VAT', () {
      final p = priceUp(100000, 5000, 5000, discountPercent: 10);
      expect(p.discount, 11000);
      expect(p.vat, 14850);
      expect(p.total, 113850);
    });

    test('a discount over 100% is capped at 100%', () {
      final p = priceUp(100000, 0, 0, discountPercent: 150);
      expect(p.discount, 100000);
      expect(p.total, 0);
    });

    test('a negative discount counts as no discount', () {
      final p = priceUp(100000, 0, 0, discountPercent: -5);
      expect(p.discount, 0);
      expect(p.total, 115000);
    });

    test('nothing in gives nothing out', () {
      final p = priceUp(0, 0, 0);
      expect(p.total, 0);
    });
  });

  group('randsToCents', () {
    test('reads whole rand, dot and comma amounts', () {
      expect(randsToCents('125'), 12500);
      expect(randsToCents('125.5'), 12550);
      expect(randsToCents('125,50'), 12550);
      expect(randsToCents('1234.56'), 123456);
    });

    test('empty text counts as zero', () {
      expect(randsToCents(''), 0);
      expect(randsToCents('   '), 0);
    });

    test('text that is not a number gives null', () {
      expect(randsToCents('abc'), isNull);
    });
  });

  group('moneyText', () {
    test('drops the cents on whole rand amounts', () {
      expect(moneyText(0), 'R0');
      expect(moneyText(12500), 'R125');
    });

    test('shows two digits of cents otherwise', () {
      expect(moneyText(12550), 'R125.50');
      expect(moneyText(100005), 'R1 000.05');
    });

    test('groups thousands with spaces', () {
      expect(moneyText(123456789), 'R1 234 567.89');
    });

    test('handles negative amounts', () {
      expect(moneyText(-5000), '-R50');
    });
  });

  test('dateText writes day, short month and year', () {
    expect(dateText(DateTime(2026, 11, 16)), '16 Nov 2026');
    expect(dateText(DateTime(2027, 1, 5)), '5 Jan 2027');
  });

  group('guestCountNeedsFreelancers', () {
    test('with catering the limit is 100 guests', () {
      expect(guestCountNeedsFreelancers(catering: true, guests: 100), isFalse);
      expect(guestCountNeedsFreelancers(catering: true, guests: 101), isTrue);
    });

    test('without catering the limit is 150 guests', () {
      expect(guestCountNeedsFreelancers(catering: false, guests: 150), isFalse);
      expect(guestCountNeedsFreelancers(catering: false, guests: 151), isTrue);
    });
  });

  group('EventLine', () {
    const line = EventLine(
      itemId: 'i1',
      name: 'Chair',
      unitCents: 2500,
      quantity: 4,
    );

    test('lineCents is price times quantity', () {
      expect(line.lineCents, 10000);
    });

    test('withQuantity changes only the quantity', () {
      final more = line.withQuantity(10);
      expect(more.quantity, 10);
      expect(more.lineCents, 25000);
      expect(more.name, 'Chair');
      expect(more.itemId, 'i1');
    });

    test('survives a toMap / fromMap round trip', () {
      final back = EventLine.fromMap(line.toMap());
      expect(back.itemId, 'i1');
      expect(back.name, 'Chair');
      expect(back.unitCents, 2500);
      expect(back.quantity, 4);
    });

    test('fromMap fills in safe defaults', () {
      final empty = EventLine.fromMap(<String, dynamic>{});
      expect(empty.name, '');
      expect(empty.unitCents, 0);
      expect(empty.quantity, 1);
    });
  });
}