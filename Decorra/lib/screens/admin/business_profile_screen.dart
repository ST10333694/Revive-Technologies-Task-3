import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/business.dart';
import '../../services/business_repository.dart';
import '../../services/image_service.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/image_picker_field.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = BusinessRepository();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _about = TextEditingController();

  String? _logoUrl;
  PickedPhoto? _picked;
  bool _removeLogo = false;
  bool _loading = true;
  bool _failed = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _address, _about]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final p = await _repo.getProfile();
      if (!mounted) return;
      setState(() {
        _name.text = p.name;
        _email.text = p.email;
        _phone.text = p.phone;
        _address.text = p.address;
        _about.text = p.about;
        _logoUrl = p.logoUrl;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);

    try {
      String? logo = _removeLogo ? null : _logoUrl;
      if (_picked != null) {
        logo = await ImageService().upload(_picked!, folder: 'business');
      }
      final profile = BusinessProfile(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        about: _about.text.trim(),
        logoUrl: logo,
      );

      var queued = false;
      try {
        await _repo.saveProfile(profile).timeout(const Duration(seconds: 10));
      } on TimeoutException {
        queued = true;
      }

      navigator.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(queued
            ? 'Saved. It will sync when you are back online.'
            : 'Business profile saved'),
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_failed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: EmptyState(
          title: 'Could not load your business profile',
          message: 'Check your connection and try again.',
          action: FilledButton(onPressed: _load, child: const Text('Try again')),
        ),
      );
    }

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Business Profile')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ImagePickerField(
                existingUrl: _removeLogo ? null : _logoUrl,
                picked: _picked,
                enabled: !_saving,
                onPicked: (p) => setState(() {
                  _picked = p;
                  _removeLogo = false;
                }),
                onRemoved: () => setState(() {
                  _picked = null;
                  _removeLogo = true;
                }),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _name,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Business name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                enabled: !_saving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Business email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                enabled: !_saving,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Business phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                enabled: !_saving,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _about,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'About your business',
                  alignLabelWithHint: true,
                ),
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
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}