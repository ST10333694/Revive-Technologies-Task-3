import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/event_draft.dart';
import '../../services/event_repository.dart';
import '../../services/image_service.dart';
import '../../widgets/decor_image.dart';
import 'event_created_screen.dart';

class ReviewEventScreen extends StatefulWidget {
  const ReviewEventScreen({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<ReviewEventScreen> createState() => _ReviewEventScreenState();
}

class _ReviewEventScreenState extends State<ReviewEventScreen> {
  final _transport = TextEditingController();
  final _working = TextEditingController();
  bool _saving = false;
  String _status = '';
  String? _coverUrl; // kept, so a retry after a failed save does not upload twice

  @override
  void dispose() {
    _transport.dispose();
    _working.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final transport = randsToCents(_transport.text);
    final working = randsToCents(_working.text);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (transport == null || working == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Enter the fees as numbers, for example 800.')),
      );
      return;
    }

    final d = widget.draft;
    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      if (d.cover != null && _coverUrl == null) {
        setState(() => _status = 'Uploading photo…');
        _coverUrl = await ImageService().upload(d.cover!, folder: 'events');
      }

      setState(() => _status = 'Saving…');
      final event = DecorEvent(
        id: d.id,
        name: d.name,
        type: d.type,
        date: d.date ?? DateTime.now(),
        location: d.location,
        coverUrl: _coverUrl,
        themeId: d.theme?.id,
        themeName: d.theme?.name,
        lines: d.lines.values.toList(),
        transportCents: transport,
        workingCents: working,
      );

      var queued = false;
      try {
        await EventRepository().save(event).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        queued = true; // offline: Firestore keeps the write and sends it later
      }

      // Close all the creation screens and go back to the Events tab.
         navigator.pushAndRemoveUntil(
     MaterialPageRoute(builder: (_) => const EventCreatedScreen()),
     (route) => route.isFirst,
   );
      messenger.showSnackBar(SnackBar(
        content: Text(queued ? 'Saved. It will sync when you are back online.' : 'Event saved'),
      ));
        } on ImageUploadException catch (e) {
      debugPrint('UPLOAD ERROR: ${e.message}');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
    }
  }

  Widget _heading(String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  Widget _row(String label, String value, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }

  Widget _feeField(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(labelText: label, prefixText: 'R '),
          onChanged: (_) => setState(() {}),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;
    final transport = randsToCents(_transport.text) ?? 0;
    final working = randsToCents(_working.text) ?? 0;
    final price = priceUp(d.itemsCents, transport, working);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Review Your Event')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: d.cover != null
                    ? Image.memory(d.cover!.bytes, fit: BoxFit.cover)
                    : const DecorImage(null),
              ),
            ),
            _heading('Event details'),
            _row('Name', d.name),
            _row('Type', d.type),
            _row('Date', d.date == null ? '-' : dateText(d.date!)),
            _row('Location', d.location),
            _heading('Theme'),
            _row('Style', d.theme?.name ?? 'None'),
            _heading('Selected items (${d.lines.length})'),
            if (d.lines.isEmpty)
              const Text('No items selected')
            else
              for (final l in d.lines.values) _row('${l.name} × ${l.quantity}', moneyText(l.lineCents)),
            _heading('Fees'),
            _feeField(_transport, 'Transport fee'),
            _feeField(_working, 'Working fee'),
            const Divider(),
            _row('Items subtotal', moneyText(d.itemsCents)),
            _row('Transport fee', moneyText(transport)),
            _row('Working fee', moneyText(working)),
            _row('VAT ($vatPercent%)', moneyText(price.vat)),
            _row('Total estimate', moneyText(price.total), bold: true),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                        if (_status.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(_status),
                        ],
                      ],
                    )
                  : const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }
}