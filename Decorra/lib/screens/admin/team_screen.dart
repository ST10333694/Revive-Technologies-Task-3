import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _team = FirebaseFirestore.instance
      .collection('users')
      .where('role', isEqualTo: 'decorator')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final myId = context.watch<Session>().user?.id;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _team,
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(
              title: 'Could not load your team',
              message: 'Check your connection and try again.',
            );
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final members = snap.data!.docs.map(AppUser.fromDoc).whereType<AppUser>().toList()
            ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sand.withAlpha(90),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'To add someone to your team, ask them to register as a Decorator '
                  'using your decorator access code.',
                ),
              ),
              const SizedBox(height: 12),
              for (final m in members)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: sand,
                    child: Text(
                      m.firstName.isEmpty ? '?' : m.firstName[0].toUpperCase(),
                      style: const TextStyle(color: espresso),
                    ),
                  ),
                  title: Text(m.id == myId ? '${m.fullName} (you)' : m.fullName),
                  subtitle: Text(m.phone.isEmpty ? m.email : '${m.email}\n${m.phone}'),
                  isThreeLine: m.phone.isNotEmpty,
                ),
            ],
          );
        },
      ),
    );
  }
}