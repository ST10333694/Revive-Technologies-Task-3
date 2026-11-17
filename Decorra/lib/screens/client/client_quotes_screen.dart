import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_event.dart';
import '../../models/decor_item.dart';
import '../../models/quote.dart';
import '../../services/client_quote_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_badge.dart';
import 'client_quote_detail_screen.dart';
import 'portfolio_screen.dart';

/// Wording the client sees for each status.
String clientStatusLabel(QuoteStatus s) => switch (s) {
      QuoteStatus.newRequest => 'REQUESTED',
      QuoteStatus.inProgress => 'BEING PREPARED',
      QuoteStatus.draft => 'BEING PREPARED',
      QuoteStatus.sent => 'READY FOR YOU',
      QuoteStatus.approved => 'APPROVED',
      QuoteStatus.declined => 'DECLINED',
      QuoteStatus.depositPaid => 'DEPOSIT PAID',
      QuoteStatus.eventInProgress => 'IN PROGRESS',
      QuoteStatus.completed => 'COMPLETE',
    };

/// The price is only shown once the decorator has sent the quote.
bool quotePriced(Quote q) => switch (q.status) {
      QuoteStatus.newRequest || QuoteStatus.inProgress || QuoteStatus.draft => false,
      _ => true,
    };

/// The client has approved the quote (including every later step).
bool quoteAccepted(Quote q) => switch (q.status) {
      QuoteStatus.approved ||
      QuoteStatus.depositPaid ||
      QuoteStatus.eventInProgress ||
      QuoteStatus.completed =>
        true,
      _ => false,
    };

/// The deposit has been received.
bool quotePaid(Quote q) => switch (q.status) {
      QuoteStatus.depositPaid || QuoteStatus.eventInProgress || QuoteStatus.completed => true,
      _ => false,
    };

int quoteDepositCents(Quote q) => (q.totalCents * q.depositPercent + 50) ~/ 100;

/// The client's own quote requests, newest first.
class ClientQuotesScreen extends StatefulWidget {
  const ClientQuotesScreen({super.key});

  @override
  State<ClientQuotesScreen> createState() => _ClientQuotesScreenState();
}

class _ClientQuotesScreenState extends State<ClientQuotesScreen> {
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
      appBar: AppBar(title: const Text('My Quotes')),
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
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!;
                if (list.isEmpty) {
                  return EmptyState(
                    title: 'No quotes yet',
                    message: 'Browse the portfolio and request your first quote.',
                    action: FilledButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PortfolioScreen()),
                      ),
                      child: const Text('Browse Portfolio'),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _QuoteCard(quote: list[i]),
                );
              },
            ),
    );
  }
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    final text = Theme.of(context).textTheme;
    final title = q.themeName.isNotEmpty ? q.themeName : q.eventType;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ClientQuoteDetailScreen(quoteId: q.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: surfaceCard(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: taupe.withAlpha(128)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '${q.eventType} · ${dateText(q.date)}',
                    style: text.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quotePriced(q) ? moneyText(q.totalCents) : 'Price to follow',
                    style: text.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            StatusBadge(clientStatusLabel(q.status), color: quoteStatusColor(q.status)),
          ],
        ),
      ),
    );
  }
}