import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/quote.dart';
import '../../services/client_quote_repository.dart';
import '../../services/session.dart';
import '../../widgets/empty_state.dart';
import 'client_quote_detail_screen.dart';

/// Updates on the client's quotes, newest first. Built from the quotes themselves.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  Stream<List<Quote>>? _quotes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<Session>().user?.id;
    if (_quotes == null && uid != null) {
      _quotes = ClientQuoteRepository().watchMine(uid);
    }
  }

  (IconData, String, String) _content(Quote q) {
    final name = q.themeName.isNotEmpty ? q.themeName : q.eventType;
    return switch (q.status) {
      QuoteStatus.newRequest => (
          Icons.mark_email_read_outlined,
          'Request received',
          'We have your request for $name.',
        ),
      QuoteStatus.inProgress || QuoteStatus.draft => (
          Icons.edit_note_outlined,
          'Quote being prepared',
          'Your decorator is working on your quote for $name.',
        ),
      QuoteStatus.sent => (
          Icons.description_outlined,
          'Your quote is ready',
          'Review the price for $name, then approve or decline.',
        ),
      QuoteStatus.approved => (
          Icons.check_circle_outline,
          'Quote approved',
          'Pay your deposit for $name using the bank details on the quote.',
        ),
      QuoteStatus.declined => (
          Icons.cancel_outlined,
          'Quote declined',
          'You declined the quote for $name.',
        ),
      QuoteStatus.depositPaid => (
          Icons.account_balance_wallet_outlined,
          'Deposit received',
          'Your deposit for $name has been confirmed.',
        ),
      QuoteStatus.eventInProgress => (
          Icons.celebration_outlined,
          'Your event is under way',
          'Your decorator is working on $name.',
        ),
      QuoteStatus.completed => (
          Icons.verified_outlined,
          'Event complete',
          '$name is complete. Thank you!',
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stream = _quotes;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: stream == null
          ? const EmptyState(title: 'Please log in again.')
          : StreamBuilder<List<Quote>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                    title: 'Could not load notifications',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                final now = DateTime.now();
                final list = [...snap.data!]..sort((a, b) =>
                    (b.updatedAt ?? now).compareTo(a.updatedAt ?? now));
                if (list.isEmpty) {
                  return const EmptyState(
                    title: 'No notifications yet',
                    message: 'Updates on your quotes will appear here.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final q = list[i];
                    final (icon, title, body) = _content(q);
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        leading: Icon(icon),
                        title: Text(title),
                        subtitle: Text(
                          q.updatedAt == null ? body : '$body\n${dateText(q.updatedAt!)}',
                        ),
                        isThreeLine: q.updatedAt != null,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientQuoteDetailScreen(quoteId: q.id),
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