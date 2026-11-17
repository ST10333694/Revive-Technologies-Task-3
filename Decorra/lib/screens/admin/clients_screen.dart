import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/client_admin_repository.dart';
import '../../theme_dark.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';

/// Decorator-only list of client accounts. View, edit contact details and
/// disable / re-enable. Nothing is deleted so quotes and history survive.
class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final _repo = ClientAdminRepository();
  late final Stream<List<AppUser>> _stream = _repo
      .watchClients()
      .map((snap) => snap.docs.map(AppUser.fromDoc).whereType<AppUser>().toList()
        ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())));

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(AppUser u) async {
    final first = TextEditingController(text: u.firstName);
    final last = TextEditingController(text: u.lastName);
    final phone = TextEditingController(text: u.phone);
    final formKey = GlobalKey<FormState>();
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(sheet).viewInsets.bottom),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Edit client', style: Theme.of(sheet).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: first,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: last,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'This field is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) Navigator.pop(sheet, true);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
    final saved = result == true;
    if (saved) {
      try {
        await _repo.updateContact(
          u.id,
          firstName: first.text.trim(),
          lastName: last.text.trim(),
          phone: phone.text.trim(),
        );
        _toast('Client updated');
      } catch (_) {
        _toast('Could not save. Check your connection.');
      }
    }
    first.dispose();
    last.dispose();
    phone.dispose();
  }

  Future<void> _toggleDisabled(AppUser u) async {
    final verb = u.disabled ? 'Re-enable' : 'Disable';
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text('$verb ${u.fullName}?'),
        content: Text(
          u.disabled
              ? 'They will be able to sign in again. Their quotes and history are unchanged.'
              : 'They will not be able to sign in. Their quotes and history are kept.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(verb),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.setDisabled(u.id, !u.disabled);
      _toast(u.disabled ? 'Client re-enabled' : 'Client disabled');
    } catch (_) {
      _toast('Could not update. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clients')),
      body: StreamBuilder<List<AppUser>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load clients',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final clients = snap.data!;
          if (clients.isEmpty) {
            return const EmptyState(
              title: 'No clients yet',
              message: 'Client accounts appear here as soon as people register.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: clients.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = clients[i];
              return Opacity(
                opacity: c.disabled ? 0.6 : 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceCard(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: taupe.withAlpha(128)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: sand,
                      child: Text(
                        c.firstName.isEmpty ? '?' : c.firstName[0].toUpperCase(),
                        style: const TextStyle(color: espresso),
                      ),
                    ),
                    title: Text(c.disabled ? '${c.fullName} (disabled)' : c.fullName),
                    subtitle: Text(
                      [c.email, if (c.phone.isNotEmpty) c.phone].join(' · '),
                    ),
                    onTap: () => _edit(c),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'edit') _edit(c);
                        if (v == 'toggle') _toggleDisabled(c);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(c.disabled ? 'Re-enable' : 'Disable'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}