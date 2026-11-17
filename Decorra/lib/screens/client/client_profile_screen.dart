import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/decor_item.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../admin/settings_screen.dart';
import 'client_quote_list_screen.dart';
import 'client_quotes_screen.dart';
import 'inspiration_screen.dart';

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final session = context.read<Session>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (ok == true) await session.signOut();
  }

  Widget _row(BuildContext context, IconData icon, String label, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: sand,
                  child: Icon(Icons.person, size: 36, color: espresso),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.fullName ?? '', style: text.titleLarge),
                      Text(user?.email ?? '', style: text.bodyMedium),
                      if ((user?.phone ?? '').isNotEmpty) Text(user!.phone, style: text.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _row(
            context,
            Icons.event_outlined,
            'My Events',
            ClientQuoteListScreen(
              title: 'My Events',
              filter: quoteAccepted,
              byEventDate: true,
              emptyTitle: 'No events yet',
              emptyMessage: 'Events appear here once you approve a quote.',
            ),
          ),
          _row(
            context,
            Icons.account_balance_wallet_outlined,
            'Payment History',
            ClientQuoteListScreen(
              title: 'Payment History',
              filter: quotePaid,
              subtitle: (q) => 'Deposit paid ${moneyText(quoteDepositCents(q))}'
                  ' · Total ${moneyText(q.totalCents)}',
              emptyTitle: 'No payments yet',
              emptyMessage: 'Deposits appear here once your decorator confirms them.',
            ),
          ),
          _row(
            context,
            Icons.download_outlined,
            'Saved Quotes',
            ClientQuoteListScreen(
              title: 'Saved Quotes',
              filter: quotePriced,
              emptyTitle: 'No saved quotes',
              emptyMessage: 'Quotes your decorator sends you are kept here.',
            ),
          ),
          _row(context, Icons.bookmark_border, 'My Inspiration', const InspirationScreen()),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}