import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/event_draft.dart';
import '../../services/event_repository.dart';
import '../../widgets/gallery_picker_field.dart';
import 'theme_style_screen.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _draft = EventDraft(EventRepository().newId());
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _dateField = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _dateField.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.date ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() {
      _draft.date = picked;
      _dateField.text = dateText(picked);
    });
  }

  void _next() {
    if (!_formKey.currentState!.validate()) return;
    _draft
      ..name = _name.text.trim()
      ..location = _location.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ThemeStyleScreen(draft: _draft)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GalleryPickerField(
              existingUrls: const [],
              picked: _draft.photos,
              enabled: true,
              onPicked: (p) => setState(() => _draft.photos.add(p)),
              onRemoveExisting: (_) {},
              onRemovePicked: (i) => setState(() => _draft.photos.removeAt(i)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Event name',
                hintText: 'e.g. Smith Wedding',
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 12),
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Event type'),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _draft.type,
                  items: [
                    for (final t in eventTypes) DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _draft.type = v ?? _draft.type),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _dateField,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: 'Event date',
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Select a date' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _next, child: const Text('Next: Theme & Style')),
          ],
        ),
      ),
    );
  }
}