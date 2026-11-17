import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/session.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(user?.fullName ?? '', style: text.headlineSmall),
          const SizedBox(height: 4),
          Text(user?.email ?? '', style: text.bodyMedium),
          if ((user?.phone ?? '').isNotEmpty)
            Text(user!.phone, style: text.bodyMedium),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.read<Session>().signOut(),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}
