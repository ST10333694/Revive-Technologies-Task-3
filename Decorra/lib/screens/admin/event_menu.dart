import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../services/event_repository.dart';
import 'edit_event_screen.dart';

/// The ⋮ menu on an event: Edit, Publish / Move to drafts, Delete.
class EventMenu extends StatelessWidget {
  const EventMenu(this.event, {super.key});

  final DecorEvent event;

  void _toast(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onSelected(BuildContext context, String action) async {
    final repo = EventRepository();
    final messenger = ScaffoldMessenger.of(context);
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EditEventScreen(event: event)),
        );
      case 'status':
        try {
          await repo.setStatus(
            event.id,
            event.isPublished ? EventStatus.draft : EventStatus.published,
          );
        } catch (_) {
      _toast(messenger, 'Could not update. Check your connection.');
        }
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Delete event?'),
            content: Text('"${event.name}" will be removed from your portfolio.'),
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
          await repo.delete(event.id);
        } catch (_) {
        _toast(messenger, 'Could not delete. Check your connection.');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Options for ${event.name}',
      onSelected: (action) => _onSelected(context, action),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
          value: 'status',
          child: Text(event.isPublished ? 'Move to drafts' : 'Publish'),
        ),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}