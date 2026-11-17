import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../../widgets/empty_state.dart';

/// Push notification switches, for clients and decorators.
/// Stored on the user's profile as pushMessages and pushQuotes (both default to on).
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>>? _doc = _uid == null
      ? null
      : FirebaseFirestore.instance.collection('users').doc(_uid).snapshots();
  late final Future<NotificationSettings> _permission =
      FirebaseMessaging.instance.getNotificationSettings();

  void _set(String key, bool value) {
    final uid = _uid;
    if (uid == null) return;
    final messenger = ScaffoldMessenger.of(context);
    FirebaseFirestore.instance.collection('users').doc(uid).update({key: value}).catchError((_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update. Check your connection.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final doc = _doc;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: doc == null
          ? const EmptyState(title: 'Please log in again.')
          : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: doc,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                    title: 'Could not load your settings',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                final data = snap.data!.data() ?? <String, dynamic>{};
                final decorator = data['role'] == 'decorator';
                final messages = data['pushMessages'] as bool? ?? true;
                final quotes = data['pushQuotes'] as bool? ?? true;

                return ListView(
                  children: [
                    FutureBuilder<NotificationSettings>(
                      future: _permission,
                      builder: (context, perm) {
                        final denied =
                            perm.data?.authorizationStatus == AuthorizationStatus.denied;
                        if (!denied) return const SizedBox.shrink();
                        return const ListTile(
                          leading: Icon(Icons.notifications_off_outlined),
                          title: Text('Notifications are turned off for this app'),
                          subtitle: Text(
                            "Turn them on in your phone's settings, under Apps, then this app.",
                          ),
                        );
                      },
                    ),
                    SwitchListTile(
                      title: Text(decorator ? 'Client messages' : 'Messages from your decorator'),
                      subtitle: Text(
                        decorator
                            ? 'Get notified when a client sends you a message.'
                            : 'Get notified when your decorator replies.',
                      ),
                      value: messages,
                      onChanged: (v) => _set('pushMessages', v),
                    ),
                    SwitchListTile(
                      title: const Text('Quote updates'),
                      subtitle: Text(
                        decorator
                            ? 'New requests, and when a client approves or declines a quote.'
                            : 'When your quote is ready, your deposit is confirmed and your event progresses.',
                      ),
                      value: quotes,
                      onChanged: (v) => _set('pushQuotes', v),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text('Notifications can take up to a minute to arrive.'),
                    ),
                  ],
                );
              },
            ),
    );
  }
}