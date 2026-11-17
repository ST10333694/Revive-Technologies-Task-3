import 'package:flutter/material.dart';

import '../../models/business.dart';
import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../services/business_repository.dart';


class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key, required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final deposit = (quote.totalCents * quote.depositPercent + 50) ~/ 100;
    final ref = 'INV-${quote.id.substring(0, quote.id.length.clamp(0, 8)).toUpperCase()}';

    return Scaffold(
      appBar: AppBar(title: const Text('Invoice')),
      body: FutureBuilder<BusinessProfile>(
        future: BusinessRepository().getProfile(),
        builder: (context, snap) {
          final b = snap.data;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(b?.name ?? 'Decorra', style: text.headlineSmall),
              if ((b?.address ?? '').isNotEmpty) Text(b!.address, style: text.bodyMedium),
              if ((b?.email ?? '').isNotEmpty) Text(b!.email, style: text.bodyMedium),
              const SizedBox(height: 16),
              Text(ref, style: text.titleMedium),
              Text('Issued ${dateText(DateTime.now())}', style: text.bodySmall),
              const Divider(height: 32),
              Text('Bill to', style: text.labelLarge),
              Text(quote.clientName, style: text.bodyLarge),
              if (quote.clientEmail.isNotEmpty) Text(quote.clientEmail),
              if (quote.venue.isNotEmpty) Text(quote.venue),
              if (quote.location.isNotEmpty) Text(quote.location),
              const SizedBox(height: 24),
              Text('Event: ${quote.eventType} · ${dateText(quote.date)}', style: text.bodyMedium),
              const Divider(height: 32),
              for (final l in quote.lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(child: Text('${l.name} × ${l.quantity}')),
                      Text(moneyText(l.lineCents)),
                    ],
                  ),
                ),
              const Divider(height: 24),
              _row(text, 'Items', moneyText(quote.subtotalCents)),
              if (quote.transportCents > 0)
                _row(text, 'Transport', moneyText(quote.transportCents)),
              if (quote.workingCents > 0)
                _row(text, 'Labour', moneyText(quote.workingCents)),
              if (quote.price.discount > 0)
                _row(text, 'Discount (${quote.discountPercent}%)',
                    '-${moneyText(quote.price.discount)}'),
              _row(text, 'VAT ($vatPercent%)', moneyText(quote.price.vat)),
              const Divider(height: 24),
              _row(text, 'Total', moneyText(quote.totalCents), bold: true),
              _row(text, 'Deposit (${quote.depositPercent}%)', moneyText(deposit)),
              const SizedBox(height: 32),
              Text(
                'This invoice was generated in the app. No PDF export is available on the free plan.',
                style: text.bodySmall,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(TextTheme text, String label, String value, {bool bold = false}) {
    final style = bold ? text.titleMedium : text.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}