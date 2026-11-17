import 'package:flutter/material.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../services/quote_repository.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'new_quote_screen.dart';
import 'quote_detail_screen.dart';

class QuotesScreen extends StatefulWidget {
  const QuotesScreen({super.key});

  @override
  State<QuotesScreen> createState() => _QuotesScreenState();
}

class _QuotesScreenState extends State<QuotesScreen> {
  late final Stream<List<Quote>> _quotes = QuoteRepository().watchAll();

  static const _labels = ['All', 'New', 'In progress', 'Drafts', 'Sent', 'Booked', 'Complete', 'Declined'];

  bool _matches(int tab, Quote q) => switch (tab) {
        1 => q.status == QuoteStatus.newRequest,
        2 => q.status == QuoteStatus.inProgress,
        3 => q.status == QuoteStatus.draft,
        4 => q.status == QuoteStatus.sent,
        5 => q.status == QuoteStatus.approved ||
            q.status == QuoteStatus.depositPaid ||
            q.status == QuoteStatus.eventInProgress,
        6 => q.status == QuoteStatus.completed,
        7 => q.status == QuoteStatus.declined,
        _ => true,
      };

  Widget _list(List<Quote> quotes) {
    if (quotes.isEmpty) {
      return const EmptyState(
        title: 'No quotes here',
        message: 'Tap "New quote" to add a client request.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
      itemCount: quotes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _QuoteCard(
        quote: quotes[i],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuoteDetailScreen(quoteId: quotes[i].id)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Quote>>(
      stream: _quotes,
      builder: (context, snap) {
        final all = snap.data;
        final list = all ?? const <Quote>[];

        return DefaultTabController(
          length: _labels.length,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Quote Requests'),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  for (var i = 0; i < _labels.length; i++)
                    Tab(text: '${_labels[i]} (${list.where((q) => _matches(i, q)).length})'),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NewQuoteScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('New quote'),
            ),
            body: snap.hasError
                ? const EmptyState(
                    title: 'Could not load quotes',
                    message: 'Check your connection and try again.',
                  )
                : all == null
                    ? const Center(child: CircularProgressIndicator())
                    : TabBarView(
                        children: [
                          for (var i = 0; i < _labels.length; i++)
                            _list(list.where((q) => _matches(i, q)).toList()),
                        ],
                      ),
          ),
        );
      },
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote, required this.onTap});

  final Quote quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taupe.withAlpha(128)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(quote.clientName, style: text.titleMedium)),
                StatusBadge(quote.status.label, color: quoteStatusColor(quote.status)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${quote.eventType} • ${dateText(quote.date)}', style: text.bodyMedium),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  quote.lines.isEmpty ? 'No items yet' : '${moneyText(quote.totalCents)} (Est.)',
                  style: text.labelLarge,
                ),
                const Spacer(),
                Text(
                  'Requested ${dateText(quote.createdAt ?? DateTime.now())}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}