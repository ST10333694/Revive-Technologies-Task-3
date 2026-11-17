import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/freelancer.dart';
import '../../services/freelancer_repository.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import '../../widgets/empty_state.dart';

/// Decorator-only list of freelancers: add, edit, deactivate and delete.
class FreelancersScreen extends StatefulWidget {
  const FreelancersScreen({super.key});

  @override
  State<FreelancersScreen> createState() => _FreelancersScreenState();
}

class _FreelancersScreenState extends State<FreelancersScreen> {
  final _repo = FreelancerRepository();
  late final Stream<List<Freelancer>> _stream = _repo.watchAll();

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit([Freelancer? existing]) async {
    final result = await showModalBottomSheet<Freelancer>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _FreelancerForm(existing: existing),
    );
    if (result == null) return;
    try {
      await _repo.save(result);
      _toast(existing == null ? 'Freelancer added' : 'Freelancer updated');
    } catch (_) {
      _toast('Could not save. Check your connection.');
    }
  }

  Future<void> _toggleActive(Freelancer f) async {
    try {
      await _repo.save(f.copyWith(active: !f.active));
    } catch (_) {
      _toast('Could not update. Check your connection.');
    }
  }

  Future<void> _confirmDelete(Freelancer f) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${f.name}?'),
        content: const Text(
            'Past event assignments keep their name and cost. Deactivate instead if you may hire them again.'),
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
      await _repo.delete(f.id);
    } catch (_) {
      _toast('Could not delete. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Freelancers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add freelancer'),
      ),
      body: StreamBuilder<List<Freelancer>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load freelancers',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(
              title: 'No freelancers yet',
              message: 'Add the people you hire for events. They do not need an app login.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _card(list[i]),
          );
        },
      ),
    );
  }

  Widget _card(Freelancer f) {
    final theme = Theme.of(context);
    final details = [
      if (f.role.isNotEmpty) f.role,
      if (f.phone.isNotEmpty) f.phone,
      if (f.rateCents > 0) '${moneyText(f.rateCents)} per event',
    ].join(' · ');
    return Opacity(
      opacity: f.active ? 1 : 0.6,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceCard(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: taupe.withAlpha(128)),
        ),
        child: ListTile(
          onTap: () => _edit(f),
          title: Text(f.active ? f.name : '${f.name} (inactive)', style: theme.textTheme.titleSmall),
          subtitle: details.isEmpty ? null : Text(details),
          trailing: PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') _edit(f);
              if (v == 'active') _toggleActive(f);
              if (v == 'delete') _confirmDelete(f);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'active', child: Text(f.active ? 'Deactivate' : 'Reactivate')),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreelancerForm extends StatefulWidget {
  const _FreelancerForm({this.existing});

  final Freelancer? existing;

  @override
  State<_FreelancerForm> createState() => _FreelancerFormState();
}

class _FreelancerFormState extends State<_FreelancerForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _role = TextEditingController(text: widget.existing?.role ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _email = TextEditingController(text: widget.existing?.email ?? '');
  late final _rate = TextEditingController(text: _randsText(widget.existing?.rateCents ?? 0));
  late final _notes = TextEditingController(text: widget.existing?.notes ?? '');
  String? _error;

  static String _randsText(int cents) {
    if (cents == 0) return '';
    return cents % 100 == 0 ? '${cents ~/ 100}' : (cents / 100).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _phone.dispose();
    _email.dispose();
    _rate.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    final rate = randsToCents(_rate.text);
    final email = _email.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    if (rate == null || rate < 0) {
      setState(() => _error = 'Enter the usual fee as a number, or leave it empty.');
      return;
    }
    if (email.isNotEmpty && !email.contains('@')) {
      setState(() => _error = 'That email address does not look right.');
      return;
    }
    final base = widget.existing ?? const Freelancer(id: '', name: '');
    Navigator.pop(
      context,
      base.copyWith(
        name: name,
        role: _role.text.trim(),
        phone: _phone.text.trim(),
        email: email,
        rateCents: rate,
        notes: _notes.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'Add freelancer' : 'Edit freelancer',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _role,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Role (e.g. setup crew, waiter)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rate,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Usual fee per event', prefixText: 'R '),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Notes', alignLabelWithHint: true),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}