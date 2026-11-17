import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../localization/strings.dart';
import '../../models/business.dart';
import '../../models/quote.dart';
import '../../services/business_repository.dart';
import '../../services/client_quote_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../theme_dark.dart';
import 'drafts_screen.dart';
import 'notifications_screen.dart';
import 'portfolio_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key, required this.onGoToTab});

  /// Switches the bottom navigation (1 Quotes, 2 Chats, 3 Profile).
  final ValueChanged<int> onGoToTab;

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  late final Stream<BusinessProfile> _business =
      BusinessRepository().watchProfile();
  Stream<List<Quote>>? _quotes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uid = context.read<Session>().user?.id;
    if (_quotes == null && uid != null) {
      _quotes = ClientQuoteRepository().watchMine(uid);
    }
  }

  void _open(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = context.watch<Session>().user?.firstName ?? '';

    return StreamBuilder<BusinessProfile>(
      stream: _business,
      builder: (context, snap) {
        final name = snap.data?.name ?? '';

        return Scaffold(
          appBar: AppBar(
            title: Text(name.isEmpty ? 'Decorra' : name),
            actions: [
              IconButton(
                tooltip: context.tr('notifications'),
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => _open(const NotificationsScreen()),
              ),
            ],
          ),
          body: StreamBuilder<List<Quote>>(
            stream: _quotes,
            builder: (context, qSnap) {
              final quotes = qSnap.data ?? const <Quote>[];
              final now = DateTime.now();

              final openQuotes = quotes
                  .where((q) =>
                      q.status == QuoteStatus.newRequest ||
                      q.status == QuoteStatus.inProgress ||
                      q.status == QuoteStatus.draft ||
                      q.status == QuoteStatus.sent)
                  .length;
              final upcomingEvents = quotes
                  .where((q) =>
                      (q.status == QuoteStatus.approved ||
                          q.status == QuoteStatus.depositPaid) &&
                      !q.date.isBefore(now))
                  .length;
              final depositsDue = quotes
                  .where((q) => q.status == QuoteStatus.approved)
                  .length;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    first.isEmpty
                        ? context.tr('welcomeBackNoName')
                        : context.tr('welcomeBack', {'name': first}),
                    style: text.titleLarge,
                  ),
                  if (quotes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _CountTile(
                            icon: Icons.description_outlined,
                            label: 'Open quotes',
                            value: openQuotes,
                            onTap: () => widget.onGoToTab(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CountTile(
                            icon: Icons.event_outlined,
                            label: 'Upcoming events',
                            value: upcomingEvents,
                            onTap: () => widget.onGoToTab(1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _CountTile(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Deposit due',
                            value: depositsDue,
                            onTap: () => widget.onGoToTab(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CountTile(
                            icon: Icons.chat_bubble_outline,
                            label: 'Message decorator',
                            value: 0,
                            onTap: () => widget.onGoToTab(2),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else
                    const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: sand.withAlpha(90),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('startJourney'),
                            style: text.titleMedium),
                        const SizedBox(height: 4),
                        Text(context.tr('browsePrompt'),
                            style: text.bodyMedium),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _open(const PortfolioScreen()),
                          child: Text(context.tr('browsePortfolio')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _Tile(
                          icon: Icons.description_outlined,
                          label: context.tr('myQuotes'),
                          onTap: () => widget.onGoToTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Tile(
                          icon: Icons.palette_outlined,
                          label: context.tr('myDesigns'),
                          onTap: () => _open(const DraftsScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _Tile(
                          icon: Icons.chat_bubble_outline,
                          label: context.tr('messageDecorator'),
                          onTap: () => widget.onGoToTab(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Tile(
                          icon: Icons.person_outline,
                          label: context.tr('profile'),
                          onTap: () => widget.onGoToTab(3),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surfaceCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: taupe.withAlpha(128)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 110,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32),
              const SizedBox(height: 8),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: surfaceCard(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: taupe.withAlpha(128)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 100,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 20),
                const Spacer(),
                Text('$value', style: text.headlineSmall),
                Text(
                  label,
                  style: text.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}