import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/quote.dart';
import '../../services/quote_repository.dart';
import '../../widgets/empty_state.dart';
import 'quote_detail_screen.dart';

class _Entry {
  const _Entry({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    this.quoteId,
  });

  final IconData icon;
  final String title;
  final String body;
  final DateTime time;

  /// Null for chat messages.
  final String? quoteId;
}

/// What needs the decorator's attention, newest first.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key, required this.onGoToTab});

  /// Switches the bottom navigation (3 is Messages).
  final ValueChanged<int> onGoToTab;

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  late final Stream<List<Quote>> _quotes = QuoteRepository().watchAll();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _threads =
      FirebaseFirestore.instance.collection('threads').snapshots();

  List<_Entry> _entries(List<Quote> quotes, QuerySnapshot<Map<String, dynamic>> threads) {
    final now = DateTime.now();
    final entries = <_Entry>[];

    for (final q in quotes) {
      final what = q.themeName.isNotEmpty ? q.themeName : q.eventType;
      final time = q.updatedAt ?? q.createdAt ?? now;
      switch (q.status) {
        case QuoteStatus.newRequest:
          if (q.clientUid.isEmpty) break; // added by hand, not a client request
          entries.add(_Entry(
            icon: Icons.mark_email_unread_outlined,
            title: 'New quote request',
            body: '${q.clientName} requested $what.',
            time: time,
            quoteId: q.id,
          ));
        case QuoteStatus.approved:
          entries.add(_Entry(
            icon: Icons.check_circle_outline,
            title: 'Quote approved',
            body: '${q.clientName} approved the quote for $what. Waiting for the deposit.',
            time: time,
            quoteId: q.id,
          ));
        case QuoteStatus.declined:
          entries.add(_Entry(
            icon: Icons.cancel_outlined,
            title: 'Quote declined',
            body: '${q.clientName} declined the quote for $what.',
            time: time,
            quoteId: q.id,
          ));
        default:
          break;
      }
    }

    for (final doc in threads.docs) {
      final d = doc.data();
      if (d['lastFromClient'] != true) continue;
      final name = d['clientName'] as String? ?? '';
      final last = d['lastTime'];
      entries.add(_Entry(
        icon: Icons.chat_bubble_outline,
        title: 'New message from ${name.isEmpty ? 'a client' : name}',
        body: d['lastText'] as String? ?? '',
        time: last is Timestamp ? last.toDate() : now,
      ));
    }

    entries.sort((a, b) => b.time.compareTo(a.time));
    return entries.take(50).toList();
  }

  void _open(_Entry e) {
    final id = e.quoteId;
    if (id == null) {
      Navigator.pop(context);
      widget.onGoToTab(3);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => QuoteDetailScreen(quoteId: id)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<Quote>>(
        stream: _quotes,
        builder: (context, qs) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _threads,
          builder: (context, ts) {
            if (qs.hasError || ts.hasError) {
              return const EmptyState(
                title: 'Could not load notifications',
                message: 'Check your connection and try again.',
              );
            }
            if (!qs.hasData || !ts.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final entries = _entries(qs.data!, ts.data!);
            if (entries.isEmpty) {
              return const EmptyState(
                title: 'Nothing new',
                message: 'New requests, approvals and client messages appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final e = entries[i];
                return Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(e.icon),
                    title: Text(e.title),
                    subtitle: Text(
                      e.body.isEmpty ? dateText(e.time) : '${e.body}\n${dateText(e.time)}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: e.body.isNotEmpty,
                    onTap: () => _open(e),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}