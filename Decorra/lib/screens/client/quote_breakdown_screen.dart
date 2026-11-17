import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../models/quote_draft.dart';
import '../../services/client_quote_repository.dart';
import '../../services/draft_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';

/// Last step: review the estimate, then submit or save as a draft.
class QuoteBreakdownScreen extends StatefulWidget {
  const QuoteBreakdownScreen({super.key, required this.draft});

  final QuoteDraft draft;

  @override
  State<QuoteBreakdownScreen> createState() => _QuoteBreakdownScreenState();
}

class _QuoteBreakdownScreenState extends State<QuoteBreakdownScreen> {
  final _quotes = ClientQuoteRepository();
  final _drafts = DraftRepository();
  bool _busy = false;

  static const _depositPercent = 40;

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action().timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline: Firestore keeps the write and sends it when the phone reconnects.
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Check your connection.')),
      );
      return;
    }
    navigator.popUntil((route) => route.isFirst);
    messenger.showSnackBar(SnackBar(content: Text(doneMessage)));
  }

  Future<void> _submit() async {
    final user = context.read<Session>().user;
    final d = widget.draft;
    if (user == null || d.date == null) return;

    final quote = Quote(
      id: _quotes.newId(),
      clientName: user.fullName,
      clientUid: user.id,
      clientEmail: user.email,
      clientPhone: user.phone,
      themeName: d.themeName,
      eventType: d.eventType,
      date: d.date!,
      guests: d.guests,
      location: d.location,
      venue: d.venue,          // NEW
      catering: d.catering,    // NEW
      notes: d.notes,
      lines: d.lines,
      status: QuoteStatus.newRequest,
    );

    await _run(() async {
      await _quotes.submit(quote);
      _drafts.delete(d.id).catchError((_) {});
    }, 'Quote request sent');
  }

  Future<void> _saveDraft() =>
      _run(() => _drafts.save(widget.draft), 'Draft saved in My Designs');

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final text = Theme.of(context).textTheme;
    final price = priceUp(d.subtotalCents, 0, 0);
    final deposit = (price.total * _depositPercent + 50) ~/ 100;

    return Scaffold(
      appBar: AppBar(title: const Text('Quote Breakdown')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _section('Event details', [
            _kv('Theme', d.themeName),
            _kv('Event type', d.eventType),
            if (d.date != null) _kv('Date', dateText(d.date!)),
            _kv('Guests', d.guests == 0 ? '-' : '${d.guests}'),
            _kv('Location', d.location),
            if (d.venue.isNotEmpty) _kv('Venue', d.venue),        
            _kv('Catering', d.catering ? 'Yes' : 'No'),  
            if (d.notes.isNotEmpty) _kv('Notes', d.notes),
          ]),
          _section('Items', [
            for (final l in d.lines) _kv('${l.name} × ${l.quantity}', moneyText(l.lineCents)),
          ]),
          _section('Estimate', [
            _kv('Subtotal', moneyText(price.base)),
            _kv('VAT ($vatPercent%)', moneyText(price.vat)),
            _kv('Total estimate', moneyText(price.total), bold: true),
            _kv('Deposit ($_depositPercent%)', moneyText(deposit)),
            _kv('Remaining balance', moneyText(price.total - deposit)),
          ]),
          const SizedBox(height: 8),
          Text(
            'This is an estimate. Your decorator will confirm the final quote.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Submit Request'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : _saveDraft,
            child: const Text('Save as Draft'),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: taupe.withAlpha(128)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ],
        ),
      );

  Widget _kv(String label, String value, {bool bold = false}) {
    final style =
        bold ? Theme.of(context).textTheme.titleMedium : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}