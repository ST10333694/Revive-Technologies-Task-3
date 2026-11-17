import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/quote_draft.dart';
import 'quote_breakdown_screen.dart';

class EventDetailsScreen extends StatefulWidget {
  const EventDetailsScreen({super.key, required this.draft});

  final QuoteDraft draft;

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  final _form = GlobalKey<FormState>();
  late String _type = eventTypes.contains(widget.draft.eventType) ? widget.draft.eventType : eventTypes.first;
  late DateTime? _date = widget.draft.date;
  late final _guests = TextEditingController(
    text: widget.draft.guests == 0 ? '' : '${widget.draft.guests}',
  );
  late final _location = TextEditingController(text: widget.draft.location);
  late final _venue = TextEditingController(text: widget.draft.venue);
  late final _notes = TextEditingController(text: widget.draft.notes);
  late bool _catering = widget.draft.catering;
  bool _dateMissing = false;

  @override
  void dispose() {
    _guests.dispose();
    _location.dispose();
    _venue.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: (_date != null && !_date!.isBefore(tomorrow)) ? _date! : tomorrow,
      firstDate: tomorrow,
      lastDate: tomorrow.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateMissing = false;
      });
    }
  }

  void _continue() {
    final valid = _form.currentState!.validate();
    if (_date == null) setState(() => _dateMissing = true);
    if (!valid || _date == null) return;

    final draft = widget.draft.copyWith(
      eventType: _type,
      date: _date,
      guests: int.tryParse(_guests.text.trim()) ?? 0,
      location: _location.text.trim(),
      venue: _venue.text.trim(),
      catering: _catering,
      notes: _notes.text.trim(),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuoteBreakdownScreen(draft: draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Event type'),
              items: [for (final t in eventTypes) DropdownMenuItem(value: t, child: Text(t))],
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_date == null ? 'Choose event date' : dateText(_date!)),
            ),
            if (_dateMissing)
              Padding(
                padding: const EdgeInsets.only(top: 6, left: 12),
                child: Text(
                  'Please choose a date',
                  style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _guests,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of guests'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                final n = int.tryParse(t);
                return (n == null || n < 0) ? 'Enter a whole number' : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Event location'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter the location' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _venue,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Venue (optional)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Catering required'),
              subtitle: const Text('Your decorator uses this to plan staff.'),
              value: _catering,
              onChanged: (v) => setState(() => _catering = v),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes for your decorator (optional)'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _continue, child: const Text('Continue')),
          ],
        ),
      ),
    );
  }
}