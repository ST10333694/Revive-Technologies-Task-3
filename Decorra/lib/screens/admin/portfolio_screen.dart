import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../services/event_repository.dart';
import '../../theme.dart';
import '../../widgets/decor_image.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'create_event_screen.dart';
import 'event_menu.dart';
import 'event_detail_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  late final Stream<List<DecorEvent>> _events = EventRepository().watchAll();
  bool _asList = false;

  void _create() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateEventScreen()),
      );

  void _open(DecorEvent e) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id)),
      );

  StatusBadge _badge(DecorEvent e) => e.isPublished
      ? const StatusBadge('Published', color: sage)
      : const StatusBadge('Draft', color: sand);

  Widget _grid(List<DecorEvent> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: list.length + 1,
      itemBuilder: (context, i) {
        if (i == list.length) {
          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _create,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: taupe),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, size: 32),
                  SizedBox(height: 6),
                  Text('Add new event'),
                ],
              ),
            ),
          );
        }
        final e = list[i];
        final text = Theme.of(context).textTheme;
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _open(e),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: DecorImage(e.coverUrl)),
                    Positioned(top: 8, left: 8, child: _badge(e)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelLarge,
                        ),
                        Text(dateText(e.date), style: text.bodySmall),
                      ],
                    ),
                  ),
                  EventMenu(e),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rows(List<DecorEvent> list) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        for (final e in list)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: DecorImage(e.coverUrl, width: 56, height: 56),
            title: Text(e.name),
            subtitle: Text(dateText(e.date)),
            onTap: () => _open(e),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_badge(e), EventMenu(e)],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _create, child: const Text('Add New Event')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Portfolio'),
          actions: [
            IconButton(
              tooltip: _asList ? 'Show as grid' : 'Manage as list',
              icon: Icon(_asList ? Icons.grid_view : Icons.view_list),
              onPressed: () => setState(() => _asList = !_asList),
            ),
          ],
          bottom: const TabBar(tabs: [Tab(text: 'Published'), Tab(text: 'Drafts')]),
        ),
        body: StreamBuilder<List<DecorEvent>>(
          stream: _events,
          builder: (context, snap) {
            if (snap.hasError) {
              return const EmptyState(
                title: 'Could not load events',
                message: 'Check your connection and try again.',
              );
            }
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final all = snap.data!;
            final published = all.where((e) => e.isPublished).toList();
            final drafts = all.where((e) => !e.isPublished).toList();
            return TabBarView(
              children: [
                _asList ? _rows(published) : _grid(published),
                _asList ? _rows(drafts) : _grid(drafts),
              ],
            );
          },
        ),
      ),
    );
  }
}