import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../services/event_repository.dart';
import '../../theme.dart';
import '../../widgets/decor_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/provided_services.dart';
import 'edit_event_screen.dart';
import 'event_menu.dart';

class EventDetailScreen extends StatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late final Stream<List<DecorEvent>> _events = EventRepository().watchAll();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DecorEvent>>(
      stream: _events,
      builder: (context, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final matches = snap.data!.where((e) => e.id == widget.eventId);
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'This event is no longer available.'),
          );
        }
        final e = matches.first;
        final text = Theme.of(context).textTheme;

        return Scaffold(
          appBar: AppBar(title: Text(e.name), actions: [EventMenu(e)]),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
            if (e.photos.length <= 1)
                DecorImage(e.photos.isEmpty ? null : e.photos.first,
                    width: double.infinity, height: 240)
              else ...[
                SizedBox(
                  height: 240,
                  child: PageView.builder(
                    itemCount: e.photos.length,
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: DecorImage(e.photos[i], width: double.infinity, height: 240),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Swipe to see all ${e.photos.length} photos', style: text.bodySmall),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: Text(e.name, style: text.headlineSmall)),
                  e.isPublished
                      ? const StatusBadge('Published', color: sage)
                      : const StatusBadge('Draft', color: sand),
                ],
              ),
              const SizedBox(height: 4),
              Text('${dateText(e.date)} · ${e.location}', style: text.bodyMedium),
              Text(e.type, style: text.bodyMedium),
              if (e.description.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Event overview', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(e.description, style: text.bodyLarge),
              ],
              if (e.themeName != null) ...[
                const SizedBox(height: 20),
                Text('Theme & style', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(e.themeName!, style: text.bodyLarge),
              ],
              if (e.lines.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('Items', style: text.titleMedium),
                const SizedBox(height: 4),
                for (final l in e.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text('${l.name} × ${l.quantity}')),
                        Text(moneyText(l.lineCents)),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total estimate (incl. VAT)', style: text.titleSmall),
                    Text(moneyText(e.totalCents), style: text.titleSmall),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              const ProvidedServices(),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditEventScreen(event: e)),
                ),
                child: const Text('Edit event'),
              ),
            ],
          ),
        );
      },
    );
  }
}