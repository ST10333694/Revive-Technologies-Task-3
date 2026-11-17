import 'dart:async';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../models/business.dart';
import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/payment.dart';
import '../../models/quote.dart';
import '../../services/business_repository.dart';
import '../../services/client_quote_repository.dart';
import '../../services/payment_repository.dart';
import '../../services/quote_pdf.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'client_quotes_screen.dart';

class ClientQuoteDetailScreen extends StatefulWidget {
  const ClientQuoteDetailScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  State<ClientQuoteDetailScreen> createState() =>
      _ClientQuoteDetailScreenState();
}

class _ClientQuoteDetailScreenState extends State<ClientQuoteDetailScreen> {
  final _repo = ClientQuoteRepository();
  final _payments = PaymentRepository();
  late final Stream<Quote?> _quote = _repo.watchOne(widget.quoteId);
  late final Future<PaymentDetails> _payment =
      BusinessRepository().getPayment();
  bool _busy = false;
  bool _downloading = false;

  Future<bool> _confirm(String title, String message, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _respond(bool approve) async {
    final ok = approve
        ? await _confirm(
            'Approve quote?',
            'The decorator will be told you accepted this quote.',
            'Approve')
        : await _confirm(
            'Decline quote?',
            'This tells the decorator you do not want this quote.',
            'Decline');
    if (!ok || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await _repo
          .respond(widget.quoteId, approve: approve)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline: Firestore keeps the change and sends it later.
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not update. Check your connection.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
          content: Text(approve ? 'Quote approved' : 'Quote declined')),
    );
  }

  /// Builds the approved quotation as a PDF and opens the share / save sheet.
  Future<void> _download(Quote q) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _downloading = true);
    try {
      // Business and bank details are nice to have; the PDF still works without them.
      BusinessProfile? business;
      PaymentDetails? payment;
      try {
        business = await BusinessRepository().getProfile();
      } catch (_) {}
      try {
        payment = await _payment;
      } catch (_) {}

      final bytes = await buildQuotePdf(q, business: business, payment: payment);
      await Printing.sharePdf(bytes: bytes, filename: quoteFileName(q));
    } catch (e) {
      debugPrint('PDF ERROR: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not create the PDF. Try again.')),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Quote?>(
      stream: _quote,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              title: 'Could not load this quote',
              message: 'Check your connection and try again.',
            ),
          );
        }
        if (snap.connectionState == ConnectionState.waiting &&
            !snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final q = snap.data;
        if (q == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
                title: 'This quote is no longer available.'),
          );
        }
        return _body(q);
      },
    );
  }

  Widget _body(Quote q) {
    final text = Theme.of(context).textTheme;
    final priced = quotePriced(q);
    final price = q.price;
    final deposit = (price.total * q.depositPercent + 50) ~/ 100;
    final title = q.themeName.isNotEmpty ? q.themeName : q.eventType;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              StatusBadge(clientStatusLabel(q.status),
                  color: quoteStatusColor(q.status)),
              const Spacer(),
              Text(
                'Requested ${dateText(q.createdAt ?? DateTime.now())}',
                style: text.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _Card(child: _Stepper(q.status)),
          if (q.status == QuoteStatus.sent) ...[
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your quote is ready', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Please review the items and price below, then approve or decline.',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _busy ? null : () => _respond(true),
                    child: const Text('Approve Quote'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _respond(false),
                    child: const Text('Decline Quote'),
                  ),
                ],
              ),
            ),
          ],
          if (canDownloadQuotation(q)) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _downloading ? null : () => _download(q),
              icon: _downloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: const Text('Download approved quotation'),
            ),
          ],
          _section('Event details', [
            if (q.themeName.isNotEmpty) _kv('Theme', q.themeName),
            _kv('Event type', q.eventType),
            _kv('Date', dateText(q.date)),
            _kv('Guests', q.guests == 0 ? '-' : '${q.guests}'),
            if (q.venue.isNotEmpty) _kv('Venue', q.venue),
            if (q.location.isNotEmpty) _kv('Location', q.location),
            _kv('Catering', q.catering ? 'Yes' : 'No'),
          ]),
          if (!priced)
            _section('Price', [
              const Text(
                  'Your decorator is preparing your quote. The price will appear here.'),
            ])
          else ...[
            _section('Items', [
              if (q.lines.isEmpty)
                const Text('No items listed.')
              else
                for (final l in q.lines)
                  _kv('${l.name} × ${l.quantity}', moneyText(l.lineCents)),
            ]),
            _section('Price breakdown', [
              _kv('Items', moneyText(q.subtotalCents)),
              if (q.transportCents > 0)
                _kv('Transport', moneyText(q.transportCents)),
              if (q.workingCents > 0)
                _kv('Labour / working', moneyText(q.workingCents)),
              if (price.discount > 0)
                _kv('Discount (${q.discountPercent}%)',
                    '-${moneyText(price.discount)}'),
              _kv('VAT ($vatPercent%)', moneyText(price.vat)),
              _kv('Total estimate', moneyText(price.total), bold: true),
              _kv('Deposit (${q.depositPercent}%)', moneyText(deposit)),
              _kv('Remaining balance', moneyText(price.total - deposit)),
            ]),
            _section('Payments', [
              StreamBuilder<List<Payment>>(
                stream: _payments.watchForQuote(q.id),
                builder: (context, snap) {
                  final list = snap.data ?? const <Payment>[];
                  final paid =
                      list.fold<int>(0, (s, p) => s + p.amountCents);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (list.isEmpty)
                        const Text('No payments recorded yet.')
                      else
                        for (final p in list)
                          _kv(
                            '${dateText(p.paidAt)} · ${p.method}',
                            moneyText(p.amountCents),
                          ),
                      const Divider(),
                      _kv('Total paid', moneyText(paid)),
                      _kv('Deposit required', moneyText(deposit)),
                      _kv('Outstanding',
                          moneyText(q.totalCents - paid),
                          bold: true),
                    ],
                  );
                },
              ),
            ]),
          ],
          if (q.status == QuoteStatus.approved)
            FutureBuilder<PaymentDetails>(
              future: _payment,
              builder: (context, snap) {
                final p = snap.data;
                if (p == null || p.accountNumber.isEmpty) {
                  return const SizedBox.shrink();
                }
                return _section('Pay your deposit', [
                  _kv('Account holder', p.accountHolder),
                  _kv('Bank', p.bankName),
                  _kv('Account type', p.accountType),
                  _kv('Account number', p.accountNumber),
                  if (p.branchCode.isNotEmpty)
                    _kv('Branch code', p.branchCode),
                  if (p.reference.isNotEmpty) _kv('Reference', p.reference),
                ]);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _Card(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            ),
          ],
        ),
      );

  Widget _kv(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Flexible(
              child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: taupe.withAlpha(128)),
        ),
        child: child,
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper(this.status);

  final QuoteStatus status;

  static const _steps = [
    'Requested',
    'Being prepared',
    'Sent to you',
    'Approved',
    'Deposit paid',
    'Event in progress',
    'Complete',
  ];

  int get _current => switch (status) {
        QuoteStatus.newRequest => 0,
        QuoteStatus.inProgress || QuoteStatus.draft => 1,
        QuoteStatus.sent => 2,
        QuoteStatus.approved => 3,
        QuoteStatus.depositPaid => 4,
        QuoteStatus.eventInProgress => 5,
        QuoteStatus.completed => 6,
        QuoteStatus.declined => -1,
      };

  @override
  Widget build(BuildContext context) {
    if (status == QuoteStatus.declined) {
      return const Text('You declined this quote.');
    }
    final text = Theme.of(context).textTheme;

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(
                  i <= _current
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: i <= _current ? accentInk(context) : taupe,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  _steps[i],
                  style: i == _current
                      ? text.titleSmall
                      : text.bodyMedium?.copyWith(
                          color: i < _current ? null : taupe),
                ),
              ],
            ),
          ),
      ],
    );
  }
}