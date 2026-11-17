import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../services/client_quote_repository.dart';
import '../../services/session.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'client_quote_detail_screen.dart';
import 'client_quotes_screen.dart';

/// A filtered view of the client's own quotes.
class ClientQuoteListScreen extends StatefulWidget {
  const ClientQuoteListScreen({
    super.key,
    required this.title,
    required this.filter,
    required this.emptyTitle,
    required this.emptyMessage,
    this.byEventDate = false,
    this.subtitle,
  });

  final String title;
  final bool Function(Quote) filter;
  final String emptyTitle;
  final String emptyMessage;
  /// Replaces the default date and price line.
  final String Function(Quote)? subtitle;
  /// Sort by event date (soonest first) instead of newest request first.
  final bool byEventDate;

  @override
  State<ClientQuoteListScreen> createState() => _ClientQuoteListScreenState();
}

class _ClientQuoteListScreenState extends State<ClientQuoteListScreen> {
  Stream<List<Quote>>? _quotes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<Session>().user?.id;
    if (_quotes == null && uid != null) {
      _quotes = ClientQuoteRepository().watchMine(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stream = _quotes;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: stream == null
          ? const EmptyState(title: 'Please log in again.')
          : StreamBuilder<List<Quote>>(
              stream: stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                    title: 'Could not load your quotes',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final list = snap.data!.where(widget.filter).toList();
                if (widget.byEventDate) list.sort((a, b) => a.date.compareTo(b.date));
                if (list.isEmpty) {
                  return EmptyState(title: widget.emptyTitle, message: widget.emptyMessage);
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final q = list[i];
                    final title = q.themeName.isNotEmpty ? q.themeName : q.eventType;
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: Text(title),
                        subtitle: Text(
  widget.subtitle?.call(q) ??
      '${dateText(q.date)} · '
          '${quotePriced(q) ? moneyText(q.totalCents) : 'Price to follow'}',
),
                        trailing: StatusBadge(
                          clientStatusLabel(q.status),
                          color: quoteStatusColor(q.status),
                        ),
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