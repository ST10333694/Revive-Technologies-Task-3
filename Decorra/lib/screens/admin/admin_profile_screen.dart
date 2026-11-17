import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../services/business_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/decor_image.dart';
import 'business_profile_screen.dart';
import 'manage_screen.dart';
import 'notifications_screen.dart';
import 'payment_screen.dart';
import 'settings_screen.dart';
import 'team_screen.dart';
import 'clients_screen.dart';


class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  late final Stream<BusinessProfile> _business = BusinessRepository().watchProfile();

  Future<void> _confirmLogout() async {
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

  Widget _row(IconData icon, String label, Widget page) {
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
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          StreamBuilder<BusinessProfile>(
            stream: _business,
            builder: (context, snap) {
              final business = snap.data;
              final name = (business?.name ?? '').isNotEmpty ? business!.name : (user?.fullName ?? '');
              final logo = business?.logoUrl;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (logo != null && logo.isNotEmpty)
                      ClipOval(child: DecorImage(logo, width: 64, height: 64, radius: 32))
                    else
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
                          Text(name, style: text.titleLarge),
                          Text('Administrator', style: text.bodyMedium),
                          Text(user?.email ?? '', style: text.bodyMedium),
                          if ((user?.phone ?? '').isNotEmpty) Text(user!.phone, style: text.bodyMedium),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          _row(Icons.storefront_outlined, 'Business Profile', const BusinessProfileScreen()),
          _row(Icons.people_outline, 'Clients', const ClientsScreen()),
          _row(Icons.groups_outlined, 'Team Management', const TeamScreen()),
          _row(Icons.groups_outlined, 'Team Management', const TeamScreen()),
          _row(Icons.inventory_2_outlined, 'Service & Item Management', const ManageScreen()),
          _row(Icons.account_balance_outlined, 'Payment & Bank Details', const PaymentScreen()),
          _row(Icons.notifications_outlined, 'Notifications', const NotificationsScreen()),
          _row(Icons.settings_outlined, 'App Settings', const SettingsScreen()),
          
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OutlinedButton.icon(
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}