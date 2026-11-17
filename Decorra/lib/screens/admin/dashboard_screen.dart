import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../services/catalog_repository.dart';
import '../../services/event_repository.dart';
import '../../services/quote_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import 'activity_screen.dart';
import 'manage_screen.dart';
import 'quote_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.onGoToTab});

  /// Switches the bottom navigation (1 Quotes, 2 Portfolio, 3 Messages).
  final ValueChanged<int> onGoToTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Stream<List<Quote>> _quotes = QuoteRepository().watchAll();
  late final Stream<List<DecorEvent>> _events = EventRepository().watchAll();
  late final Stream<List<DecorItem>> _items =
      context.read<CatalogRepository>().watchItems();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _threads =
      FirebaseFirestore.instance.collection('threads').snapshots();

  /// The client has approved: a booking, from approval until the event is done.
  static bool _booked(Quote q) => switch (q.status) {
        QuoteStatus.approved ||
        QuoteStatus.depositPaid ||
        QuoteStatus.eventInProgress =>
          true,
        _ => false,
      };

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = context.watch<Session>().user?.firstName ?? '';
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return StreamBuilder<List<Quote>>(
      stream: _quotes,
      builder: (context, qs) => StreamBuilder<List<DecorEvent>>(
        stream: _events,
        builder: (context, es) => StreamBuilder<List<DecorItem>>(
          stream: _items,
          builder: (context, itemsSnap) =>
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _threads,
            builder: (context, ts) {
              final quotes = qs.data ?? const <Quote>[];
              final events = es.data ?? const <DecorEvent>[];
              final items = itemsSnap.data ?? const <DecorItem>[];
              final now = DateTime.now();
              final startOfToday = DateTime(now.year, now.month, now.day);

              final newCount =
                  quotes.where((q) => q.status == QuoteStatus.newRequest).length;
              final pending =
                  quotes.where((q) => q.status == QuoteStatus.sent).length;
              final awaitingDeposit =
                  quotes.where((q) => q.status == QuoteStatus.approved).length;
              final upcomingEvents =
                  events.where((e) => !e.date.isBefore(startOfToday)).length;
              final upcomingBookings = quotes
                  .where((q) => _booked(q) && !q.date.isBefore(startOfToday))
                  .length;
              final unread = ts.data?.docs
                      .where((d) => d.data()['lastFromClient'] == true)
                      .length ??
                  0;
              final alerts = newCount + unread;

              final lowStock = items
                  .where((i) => i.stock != null && i.stock! <= i.minStock)
                  .length;
              final tracked = items.where((i) => i.stock != null).length;

              final today = <({String title, String subtitle, String? quoteId})>[
                for (final e in events)
                  if (_sameDay(e.date, now))
                    (
                      title: e.name,
                      subtitle: '${e.type} · ${e.location}',
                      quoteId: null
                    ),
                for (final q in quotes)
                  if (_booked(q) && _sameDay(q.date, now))
                    (
                      title: q.themeName.isNotEmpty
                          ? '${q.clientName} · ${q.themeName}'
                          : q.clientName,
                      subtitle:
                          '${q.eventType} · ${q.location.isEmpty ? 'Location to be confirmed' : q.location}',
                      quoteId: q.id,
                    ),
              ];

              return Scaffold(
                appBar: AppBar(
                  title: const Text('Dashboard'),
                  actions: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: Badge(
                        isLabelVisible: alerts > 0,
                        label: Text('$alerts'),
                        child: const Icon(Icons.notifications_outlined),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ActivityScreen(onGoToTab: widget.onGoToTab),
                        ),
                      ),
                    ),
                  ],
                ),
                body: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      first.isEmpty ? greeting : '$greeting, $first!',
                      style: text.titleLarge,
                    ),
                    Text("Here's what's happening today.",
                        style: text.bodyMedium),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard('New Quote Requests', newCount,
                              () => widget.onGoToTab(1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard('Pending Approvals', pending,
                              () => widget.onGoToTab(1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard('Awaiting Deposit', awaitingDeposit,
                              () => widget.onGoToTab(1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard('Unread Messages', unread,
                              () => widget.onGoToTab(3)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard('Upcoming Bookings',
                              upcomingBookings, () => widget.onGoToTab(1)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard('Upcoming Events', upcomingEvents,
                              () => widget.onGoToTab(2)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            'Low Stock Items',
                            lowStock,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageScreen(initialTab: 1),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            'Items Tracked',
                            tracked,
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ManageScreen(initialTab: 1),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.event_note_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text("Today's Schedule", style: text.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (today.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Nothing scheduled for today.'),
                      )
                    else
                      for (final item in today)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.celebration_outlined),
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          onTap: item.quoteId == null
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => QuoteDetailScreen(
                                          quoteId: item.quoteId!),
                                    ),
                                  ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.onTap);

  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: taupe.withAlpha(128)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 120,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.bodyMedium),
                const Spacer(),
                Text('$value', style: text.headlineMedium),
                Text('View all →', style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}