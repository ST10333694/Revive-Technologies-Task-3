import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/freelancer.dart';
import '../../models/payment.dart';
import '../../models/quote.dart';
import '../../services/catalog_repository.dart';
import '../../services/freelancer_repository.dart';
import '../../services/payment_repository.dart';
import '../../services/quote_repository.dart';
import '../../services/stock_service.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/item_picker.dart';
import '../../widgets/status_badge.dart';
import 'invoice_screen.dart';

class QuoteDetailScreen extends StatefulWidget {
  const QuoteDetailScreen({super.key, required this.quoteId});

  final String quoteId;

  @override
  State<QuoteDetailScreen> createState() => _QuoteDetailScreenState();
}

class _QuoteDetailScreenState extends State<QuoteDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 4, vsync: this);
  final _repo = QuoteRepository();
  final _freelancerRepo = FreelancerRepository();
  final _payments = PaymentRepository();
  final _stock = StockService();
  final _notes = TextEditingController();
  final _transport = TextEditingController();
  final _working = TextEditingController();
  final _discount = TextEditingController();
  late final Stream<List<DecorItem>> _items;
  final Map<String, EventLine> _lines = {};

  Quote? _quote;
  bool _missing = false;
  bool _busy = false;

  Map<String, int> _reserved = const {};
  DateTime? _reservedFor;

  @override
  void initState() {
    super.initState();
    _items = context.read<CatalogRepository>().watchItems();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _notes.dispose();
    _transport.dispose();
    _working.dispose();
    _discount.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final q = await _repo.get(widget.quoteId);
      if (!mounted) return;
      if (q == null) {
        setState(() => _missing = true);
        return;
      }
      setState(() {
        _quote = q;
        _lines
          ..clear()
          ..addEntries(q.lines.map((l) => MapEntry(l.itemId, l)));
        _notes.text = q.notes;
        _transport.text = _randsText(q.transportCents);
        _working.text = _randsText(q.workingCents);
        _discount.text = q.discountPercent == 0 ? '' : '${q.discountPercent}';
      });
      _refreshReserved();
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    }
  }

  Future<void> _refreshReserved() async {
    final q = _quote;
    if (q == null) return;
    try {
      final reserved = await _stock.reservedOn(q.date, excludeQuoteId: q.id);
      if (!mounted) return;
      setState(() {
        _reserved = reserved;
        _reservedFor = q.date;
      });
    } catch (_) {}
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static String _randsText(int cents) {
    if (cents == 0) return '';
    return cents % 100 == 0 ? '${cents ~/ 100}' : (cents / 100).toStringAsFixed(2);
  }

  int get _transportCents => randsToCents(_transport.text) ?? 0;
  int get _workingCents => randsToCents(_working.text) ?? 0;
  int get _discountPercent => int.tryParse(_discount.text.trim()) ?? 0;

  Widget _feeField(TextEditingController c, String label,
      {String? prefix, String? suffix, bool decimal = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        enabled: !_busy && !_locked,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
              RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
        ],
        decoration: InputDecoration(
            labelText: label, prefixText: prefix, suffixText: suffix),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Future<bool> _save(QuoteStatus status) async {
    final transport = randsToCents(_transport.text);
    final working = randsToCents(_working.text);
    final discount =
        _discount.text.trim().isEmpty ? 0 : int.tryParse(_discount.text.trim());
    if (transport == null ||
        working == null ||
        transport < 0 ||
        working < 0 ||
        discount == null ||
        discount < 0 ||
        discount > 100) {
      _toast(
          'Check the fees and discount. The discount is a percentage from 0 to 100.');
      return false;
    }
    final updated = _quote!.copyWith(
      lines: _lines.values.toList(),
      notes: _notes.text.trim(),
      status: status,
      transportCents: transport,
      workingCents: working,
      discountPercent: discount,
    );
    setState(() => _busy = true);
    try {
      await _repo.save(updated).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline: Firestore keeps the write and sends it later.
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _toast('Could not save. Check your connection.');
      return false;
    }
    if (!mounted) return true;
    setState(() {
      _quote = updated;
      _busy = false;
    });
    _refreshReserved();
    return true;
  }

  bool get _locked => switch (_quote?.status) {
        QuoteStatus.approved ||
        QuoteStatus.depositPaid ||
        QuoteStatus.eventInProgress ||
        QuoteStatus.completed =>
          true,
        _ => false,
      };

  ({String label, QuoteStatus status})? _nextStep(QuoteStatus s) =>
      switch (s) {
        QuoteStatus.approved =>
          (label: 'Mark deposit paid', status: QuoteStatus.depositPaid),
        QuoteStatus.depositPaid =>
          (label: 'Start event', status: QuoteStatus.eventInProgress),
        QuoteStatus.eventInProgress =>
          (label: 'Mark complete', status: QuoteStatus.completed),
        _ => null,
      };

  Future<void> _saveDraft() async {
    final status = _locked ? _quote!.status : QuoteStatus.draft;
    if (await _save(status)) _toast('Saved');
  }

  Future<void> _next() async {
    final status = _quote!.status == QuoteStatus.newRequest
        ? QuoteStatus.inProgress
        : _quote!.status;
    if (await _save(status)) _tabs.animateTo(2);
  }

  Future<void> _send() async {
    if (_lines.isEmpty) {
      _toast('Add at least one item before sending.');
      return;
    }
    if (await _save(QuoteStatus.sent)) _toast('Quote marked as sent.');
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete quote?'),
        content: const Text('This removes the quote for good.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.delete(widget.quoteId);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      _toast('Could not delete. Check your connection.');
    }
  }

  int get _subtotal => _lines.values.fold(0, (sum, l) => sum + l.lineCents);
  int get _units => _lines.values.fold(0, (sum, l) => sum + l.quantity);

  Widget _section(String title, List<Widget> children) => Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: surfaceCard(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: taupe.withAlpha(128)),
              ),
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

  Widget _details(Quote q) {
    final canInvoice = q.status == QuoteStatus.sent ||
        q.status == QuoteStatus.approved ||
        q.status == QuoteStatus.depositPaid ||
        q.status == QuoteStatus.eventInProgress ||
        q.status == QuoteStatus.completed;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            StatusBadge(q.status.label, color: quoteStatusColor(q.status)),
            const Spacer(),
            Text(
              'Requested ${dateText(q.createdAt ?? DateTime.now())}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        _section('Client information', [
          _kv('Name', q.clientName),
          _kv('Email', q.clientEmail.isEmpty ? '-' : q.clientEmail),
          _kv('Phone', q.clientPhone.isEmpty ? '-' : q.clientPhone),
        ]),
        _section('Event details', [
          if (q.themeName.isNotEmpty) _kv('Theme', q.themeName),
          _kv('Event type', q.eventType),
          _kv('Date', dateText(q.date)),
          _kv('Guests', q.guests == 0 ? '-' : '${q.guests}'),
          _kv('Venue', q.venue.isEmpty ? '-' : q.venue),
          _kv('Location', q.location.isEmpty ? '-' : q.location),
          _kv('Catering', q.catering ? 'Yes' : 'No'),
        ]),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: canInvoice
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => InvoiceScreen(quote: q)),
                  )
              : null,
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('View invoice'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Delete quote'),
        ),
      ],
    );
  }

  Widget _builder() {
    return StreamBuilder<List<DecorItem>>(
      stream: _items,
      builder: (context, snap) {
        if (snap.hasError) {
          return const EmptyState(
            title: 'Could not load items',
            message: 'Check your connection and try again.',
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sameDay = _reservedFor != null &&
            _quote != null &&
            _reservedFor!.year == _quote!.date.year &&
            _reservedFor!.month == _quote!.date.month &&
            _reservedFor!.day == _quote!.date.day;

        int maxFor(DecorItem i) {
          final reserved = sameDay ? (_reserved[i.id] ?? 0) : 0;
          if (i.stock == null) return DecorItem.maxQuantity;
          return (i.stock! - reserved).clamp(0, DecorItem.maxQuantity).toInt();
        }

        int reservedFor(DecorItem i) =>
            sameDay ? (_reserved[i.id] ?? 0) : 0;

        return Column(
          children: [
            Expanded(
              child: ItemPicker(
                items: snap.data!,
                lines: _lines,
                onChanged: () => setState(() {}),
                maxFor: maxFor,
                reservedFor: reservedFor,
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                  border:
                      Border(top: BorderSide(color: taupe.withAlpha(128)))),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Items: $_units'),
                        Text(
                          'Total: ${moneyText(_subtotal)}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy ? null : _saveDraft,
                            child: const Text('Save Draft'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _busy ? null : _next,
                            child: const Text('Next: Summary'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveFreelancers(List<FreelancerAssignment> list) async {
    final updated = _quote!.copyWith(freelancers: list);
    setState(() => _busy = true);
    try {
      await _repo.save(updated).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline.
    } catch (_) {
      if (mounted) setState(() => _busy = false);
      _toast('Could not save. Check your connection.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _quote = updated;
      _busy = false;
    });
  }

  Future<int?> _askCost(String name, int initialCents) async {
    final c = TextEditingController(text: _randsText(initialCents));
    String? error;
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text('Cost for $name'),
          content: TextField(
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              labelText: 'Fee for this event',
              prefixText: 'R ',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final cents = randsToCents(c.text);
                if (cents == null || cents < 0) {
                  setLocal(() => error = 'Enter a number.');
                  return;
                }
                Navigator.pop(dialogContext, cents);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    c.dispose();
    return result;
  }

  Future<void> _addFreelancer() async {
    final taken = _quote!.freelancers.map((a) => a.freelancerId).toSet();
    final picked = await showModalBottomSheet<Freelancer>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.of(sheetContext).size.height * 0.6,
        child: StreamBuilder<List<Freelancer>>(
          stream: _freelancerRepo.watchAll(),
          builder: (context, snap) {
            if (snap.hasError) {
              return const EmptyState(
                title: 'Could not load freelancers',
                message: 'Check your connection and try again.',
              );
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final options = snap.data!
                .where((f) => f.active && !taken.contains(f.id))
                .toList();
            if (options.isEmpty) {
              return const EmptyState(
                title: 'No freelancers to assign',
                message:
                    'Add freelancers from the Freelancers screen, or all are already assigned.',
              );
            }
            return ListView(
              children: [
                for (final f in options)
                  ListTile(
                    title: Text(f.name),
                    subtitle: Text([
                      if (f.role.isNotEmpty) f.role,
                      if (f.rateCents > 0) moneyText(f.rateCents),
                    ].join(' · ')),
                    onTap: () => Navigator.pop(sheetContext, f),
                  ),
              ],
            );
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    final cost = await _askCost(picked.name, picked.rateCents);
    if (cost == null) return;
    await _saveFreelancers([
      ..._quote!.freelancers,
      FreelancerAssignment(
        freelancerId: picked.id,
        name: picked.name,
        role: picked.role,
        costCents: cost,
      ),
    ]);
  }

  Future<void> _editAssignmentCost(FreelancerAssignment a) async {
    final cost = await _askCost(a.name, a.costCents);
    if (cost == null) return;
    await _saveFreelancers([
      for (final x in _quote!.freelancers)
        if (x.freelancerId == a.freelancerId)
          FreelancerAssignment(
            freelancerId: x.freelancerId,
            name: x.name,
            role: x.role,
            costCents: cost,
          )
        else
          x,
    ]);
  }

  Future<void> _removeAssignment(FreelancerAssignment a) => _saveFreelancers(
        _quote!.freelancers
            .where((x) => x.freelancerId != a.freelancerId)
            .toList(),
      );

  Future<void> _recordPayment(Quote q, int outstanding) async {
    final amount = TextEditingController(
      text: outstanding > 0 ? (outstanding / 100).toStringAsFixed(2) : '',
    );
    final ref = TextEditingController();
    String method = 'EFT';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Record payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Amount', prefixText: 'R '),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: method,
                  items: const [
                    DropdownMenuItem(value: 'EFT', child: Text('EFT')),
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'Card', child: Text('Card')),
                  ],
                  onChanged: (v) => setLocal(() => method = v ?? 'EFT'),
                  decoration: const InputDecoration(labelText: 'Method'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: ref,
                  decoration:
                      const InputDecoration(labelText: 'Reference (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final cents = randsToCents(amount.text);
    amount.dispose();
    if (cents == null || cents <= 0) {
      _toast('Enter a valid amount.');
      return;
    }
    try {
      await _payments.record(Payment(
        id: _payments.newId(),
        quoteId: q.id,
        amountCents: cents,
        method: method,
        reference: ref.text.trim(),
        paidAt: DateTime.now(),
        recordedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
      ));
      _toast('Payment recorded');
    } catch (_) {
      _toast('Could not save. Check your connection.');
    }
    ref.dispose();
  }

  Widget _freelancerSection(Quote q) {
    final limit = q.catering ? cateringGuestLimit : noCateringGuestLimit;
    return _section('Freelancers', [
      if (q.needsExtraFreelancers)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Additional freelancers needed: ${q.guests} guests '
            '${q.catering ? 'with' : 'without'} catering is over $limit. '
            '${q.freelancers.isEmpty ? 'None assigned yet.' : '${q.freelancers.length} assigned.'}',
            style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer),
          ),
        ),
      if (q.freelancers.isEmpty)
        const Text('No freelancers assigned to this event.')
      else
        for (final a in q.freelancers)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(a.name),
            subtitle: Text([
              if (a.role.isNotEmpty) a.role,
              moneyText(a.costCents),
            ].join(' · ')),
            onTap: _busy ? null : () => _editAssignmentCost(a),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.close),
              onPressed: _busy ? null : () => _removeAssignment(a),
            ),
          ),
      if (q.freelancers.isNotEmpty) ...[
        const Divider(),
        _kv('Freelancer costs (internal)',
            moneyText(q.freelancerCostCents),
            bold: true),
        Text(
          'Not included in the client price.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
      const SizedBox(height: 8),
      OutlinedButton.icon(
        onPressed: _busy ? null : _addFreelancer,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Assign freelancer'),
      ),
    ]);
  }

  Widget _summary(Quote q) {
    final price = priceUp(
      _subtotal,
      _transportCents,
      _workingCents,
      discountPercent: _discountPercent,
    );
    final deposit = (price.total * q.depositPercent + 50) ~/ 100;
    final next = _nextStep(q.status);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _section('Items', [
          if (_lines.isEmpty)
            const Text('No items yet. Add some on the Builder tab.')
          else
            for (final l in _lines.values)
              _kv('${l.name} × ${l.quantity}', moneyText(l.lineCents)),
        ]),
        _section('Fees and discount', [
          _feeField(_transport, 'Transport fee', prefix: 'R '),
          _feeField(_working, 'Labour / working fee', prefix: 'R '),
          _feeField(_discount, 'Discount', suffix: '%', decimal: false),
          if (_locked)
            Text(
              'Fees are locked once the client has approved.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ]),
        _section('Price breakdown', [
          _kv('Items', moneyText(_subtotal)),
          if (_transportCents > 0)
            _kv('Transport', moneyText(_transportCents)),
          if (_workingCents > 0)
            _kv('Labour / working', moneyText(_workingCents)),
          if (price.discount > 0)
            _kv('Discount ($_discountPercent%)',
                '-${moneyText(price.discount)}'),
          _kv('VAT ($vatPercent%)', moneyText(price.vat)),
          _kv('Total estimate', moneyText(price.total), bold: true),
        ]),
        _section('Deposit', [
          _kv('Deposit (${q.depositPercent}%)', moneyText(deposit),
              bold: true),
        ]),
        _section('Payments received', [
          StreamBuilder<List<Payment>>(
            stream: _payments.watchForQuote(q.id),
            builder: (context, snap) {
              final list = snap.data ?? const <Payment>[];
              final paid = list.fold<int>(0, (s, p) => s + p.amountCents);
              final outstanding = price.total - paid;
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
                  _kv('Outstanding', moneyText(outstanding), bold: true),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed:
                        _busy ? null : () => _recordPayment(q, outstanding),
                    icon: const Icon(Icons.add),
                    label: const Text('Record payment'),
                  ),
                ],
              );
            },
          ),
        ]),
        _freelancerSection(q),
        const SizedBox(height: 20),
        if (q.status == QuoteStatus.sent) ...[
          Text(
            'This quote has been sent and is waiting for the client.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Row(
            children: [
              TextButton(
                onPressed:
                    _busy ? null : () => _save(QuoteStatus.approved),
                child: const Text('Mark approved'),
              ),
              TextButton(
                onPressed:
                    _busy ? null : () => _save(QuoteStatus.declined),
                child: const Text('Mark declined'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (next != null) ...[
          Text(
            'The client has approved this quote.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy
                ? null
                : () async {
                    if (await _save(next.status)) _toast('Status updated');
                  },
            child: Text(next.label),
          ),
        ] else if (!_locked)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : _saveDraft,
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : _send,
                  child: const Text('Send to Client'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _notesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: _notes,
          minLines: 6,
          maxLines: 12,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Internal notes',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  if (await _save(_quote!.status)) _toast('Notes saved');
                },
          child: const Text('Save notes'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _quote;
    if (q == null) {
      return Scaffold(
        appBar: AppBar(),
        body: _missing
            ? const EmptyState(
                title: 'Could not load this quote',
                message: 'It may have been deleted, or you may be offline.',
              )
            : const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Quote: ${q.clientName}'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Details'),
            Tab(text: 'Builder'),
            Tab(text: 'Summary'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_details(q), _builder(), _summary(q), _notesTab()],
      ),
    );
  }
}