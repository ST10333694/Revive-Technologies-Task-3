import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/quote.dart';
import '../../services/quote_repository.dart';
import '../../services/business_repository.dart';

/// The decorator adds a client's quote request by hand. (Once the client app
/// can send requests, they will appear in the same list.)
class NewQuoteScreen extends StatefulWidget {
  const NewQuoteScreen({super.key});

  @override
  State<NewQuoteScreen> createState() => _NewQuoteScreenState();
}

class _NewQuoteScreenState extends State<NewQuoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = QuoteRepository();
  late final String _id = _repo.newId();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _guests = TextEditingController();
  final _location = TextEditingController();
  final _venue = TextEditingController();
  final _dateField = TextEditingController();
  String _type = eventTypes.first;
  DateTime? _date;
  bool _catering = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _guests, _location, _venue, _dateField]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      _dateField.text = dateText(picked);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

       var depositPercent = 40;
   try {
     final payment = await BusinessRepository().getPayment().timeout(const Duration(seconds: 5));
     depositPercent = payment.depositPercent;
   } catch (_) {}

    final quote = Quote(
      id: _id,
      depositPercent: depositPercent,
      clientName: _name.text.trim(),
      clientEmail: _email.text.trim(),
      clientPhone: _phone.text.trim(),
      eventType: _type,
      date: _date ?? DateTime.now(),
      guests: int.tryParse(_guests.text.trim()) ?? 0,
      location: _location.text.trim(),
      venue: _venue.text.trim(),
      catering: _catering,
    );

    try {
      await _repo.save(quote).timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Offline: Firestore keeps the write and sends it later.
        } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not save. Please try again.')),
      );
      return;
    }
    navigator.pop();
    messenger.showSnackBar(const SnackBar(content: Text('Quote request added')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Quote Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _name,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Client name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              enabled: !_saving,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              enabled: !_saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone (optional)'),
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Event type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _type,
                  items: [
                    for (final t in eventTypes) DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: _saving ? null : (v) => setState(() => _type = v ?? _type),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateField,
              readOnly: true,
              enabled: !_saving,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Event date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Select a date' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _guests,
              enabled: !_saving,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Number of guests (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Location (optional)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _venue,
              enabled: !_saving,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Venue (optional)'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Catering required'),
              value: _catering,
              onChanged: _saving ? null : (v) => setState(() => _catering = v),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Add quote request'),
            ),
          ],
        ),
      ),
    );
  }
}