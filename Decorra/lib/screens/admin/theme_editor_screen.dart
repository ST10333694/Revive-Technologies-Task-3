import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_theme.dart';
import '../../services/catalog_repository.dart';
import '../../services/image_service.dart';
import '../../widgets/image_picker_field.dart';

/// Add a new theme, or edit an existing one, including its photo.
class ThemeEditorScreen extends StatefulWidget {
  const ThemeEditorScreen({super.key, this.existing});

  final DecorTheme? existing;

  @override
  State<ThemeEditorScreen> createState() => _ThemeEditorScreenState();
}

class _ThemeEditorScreenState extends State<ThemeEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _tags;
  late final String _id;

  PickedPhoto? _picked;
  bool _removeExisting = false;
  bool _saving = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    final theme = widget.existing;
    _id = theme?.id ?? context.read<CatalogRepository>().newThemeId();
    _name = TextEditingController(text: theme?.name ?? '');
    _description = TextEditingController(text: theme?.description ?? '');
    _tags = TextEditingController(text: theme?.tags.join(', ') ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final repo = context.read<CatalogRepository>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      // 1. Upload the new photo first. If this fails, nothing is saved and the
      //    form stays open so the person can try again.
      String? imageUrl = _removeExisting ? null : widget.existing?.imageUrl;
      if (_picked != null) {
        setState(() => _status = 'Uploading photo…');
        imageUrl = await ImageService().upload(_picked!, folder: 'themes');
      }

      // 2. Save the theme with the photo's public link.
      setState(() => _status = 'Saving…');
      final theme = DecorTheme(
        id: _id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        tags: _tags.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
        imageUrl: imageUrl,
        items: widget.existing?.items ?? const [],
      );

      var queued = false;
      try {
        await repo.saveTheme(theme).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        queued = true; // Offline: Firestore keeps the write and sends it later.
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            queued
                ? 'Saved. It will sync when you are back online.'
                : 'Changes saved',
          ),
        ),
      );    } on ImageUploadException catch (e) {
      debugPrint('UPLOAD ERROR: ${e.message}');} on ImageUploadException catch (e) {
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

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: Text(editing ? 'Edit theme' : 'Add theme')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ImagePickerField(
                existingUrl: _removeExisting ? null : widget.existing?.imageUrl,
                picked: _picked,
                enabled: !_saving,
                onPicked: (p) => setState(() {
                  _picked = p;
                  _removeExisting = false;
                }),
                onRemoved: () => setState(() {
                  _picked = null;
                  _removeExisting = true;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Theme name'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'This field is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _tags,
                enabled: !_saving,
                decoration: const InputDecoration(
                  labelText: 'Tags (separate with commas)',
                ),
              ),
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
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
