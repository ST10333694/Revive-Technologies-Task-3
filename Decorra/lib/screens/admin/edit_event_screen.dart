import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../services/event_repository.dart';
import '../../services/image_service.dart';
import '../../widgets/gallery_picker_field.dart';

class EditEventScreen extends StatefulWidget {
  const EditEventScreen({super.key, required this.event});

  final DecorEvent event;

  @override
  State<EditEventScreen> createState() => _EditEventScreenState();
}

class _EditEventScreenState extends State<EditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _description;
  late final TextEditingController _dateField;
  late String _type;
  late DateTime _date;

  late List<String> _urls;
  final List<PickedPhoto> _newPhotos = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _name = TextEditingController(text: e.name);
    _location = TextEditingController(text: e.location);
    _description = TextEditingController(text: e.description);
    _dateField = TextEditingController(text: dateText(e.date));
    _type = e.type;
    _date = e.date;
    _urls = List.of(e.photos);
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _dateField.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 10),
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
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);
    try {
      final urls = [..._urls];
      for (final p in _newPhotos) {
        urls.add(await ImageService().upload(p, folder: 'events'));
      }

      final updated = widget.event.copyWith(
        name: _name.text.trim(),
        type: _type,
        date: _date,
        location: _location.text.trim(),
        description: _description.text.trim(),
        coverUrl: urls.isEmpty ? null : urls.first,
        photoUrls: urls,
        clearCover: urls.isEmpty,
      );

      var queued = false;
      try {
        await EventRepository().save(updated).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        queued = true;
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(queued ? 'Saved. It will sync when you are back online.' : 'Changes saved'),
      ));
    } on ImageUploadException catch (e) {
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Edit Event')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GalleryPickerField(
                existingUrls: _urls,
                picked: _newPhotos,
                enabled: !_saving,
                onPicked: (p) => setState(() => _newPhotos.add(p)),
                onRemoveExisting: (i) => setState(() => _urls.removeAt(i)),
                onRemovePicked: (i) => setState(() => _newPhotos.removeAt(i)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Event name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 12),
              InputDecorator(
                decoration: const InputDecoration(labelText: 'Event type'),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: eventTypes.contains(_type) ? _type : null,
                    hint: Text(_type),
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
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Location'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                enabled: !_saving,
                minLines: 3,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Event overview',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Update Event'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}