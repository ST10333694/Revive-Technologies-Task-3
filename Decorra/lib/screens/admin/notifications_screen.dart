import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../models/decor_event.dart';
import '../../services/chat_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';

class _Entry {
  const _Entry(this.icon, this.title, this.body, this.time);
  final IconData icon;
  final String title;
  final String body;
  final DateTime? time;
}

/// Inbox of what needs the decorator's attention, plus notification settings.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _db = FirebaseFirestore.instance;
  late final String _uid;
  late final Stream<List<ChatThread>> _threads = ChatRepository().watchThreads();
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _quotesStream =
      _db.collection('quotes').snapshots();

  bool _messages = true;
  bool _quotes = true;
  bool _events = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final user = context.read<Session>().user;
    _uid = user?.id ?? '';
    _messages = user?.pushMessages ?? true;
    _loadOthers();
  }

  Future<void> _loadOthers() async {
    try {
      final doc = await _db.collection('userSettings').doc(_uid).get();
      final d = doc.data() ?? <String, dynamic>{};
      if (!mounted) return;
      setState(() {
        _quotes = d['pushQuotes'] as bool? ?? true;
        _events = d['pushEvents'] as bool? ?? true;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save(
    String field,
    bool value, {
    required bool inUsers,
    required VoidCallback revert,
  }) async {
    try {
      if (inUsers) {
        await _db.collection('users').doc(_uid).update({field: value});
      } else {
        await _db
            .collection('userSettings')
            .doc(_uid)
            .set({field: value}, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('SAVE ERROR: $e');
      if (!mounted) return;
      revert();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save that setting. Check your connection.')),
      );
    }
  }

  static DateTime? _ts(dynamic v) => v is Timestamp ? v.toDate() : null;

  static String _ago(DateTime? t) {
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return dateText(t);
  }

  List<_Entry> _entries(
    List<ChatThread> threads,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> quotes,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <_Entry>[];

    if (_messages) {
      for (final t in threads) {
        if (!t.lastFromClient) continue;
        final DateTime? when = t.lastTime;
        out.add(_Entry(
          Icons.chat_bubble_outline,
          'New message from ${t.clientName}',
          t.lastText,
          when,
        ));
      }
    }

    for (final doc in quotes) {
      final d = doc.data();
      final status = d['status'] as String? ?? '';
      final who = d['clientName'] as String? ?? 'A client';
      final eventType = d['eventType'] as String? ?? 'Event';
      final eventDate = _ts(d['date']);

      if (_quotes && status == 'newRequest') {
        out.add(_Entry(
          Icons.request_quote_outlined,
          'New quote request from $who',
          [eventType, if (eventDate != null) dateText(eventDate)].join(' · '),
          _ts(d['createdAt']),
        ));
      }
      if (_quotes && status == 'approved') {
        out.add(_Entry(
          Icons.check_circle_outline,
          '$who approved their quote',
          [eventType, if (eventDate != null) dateText(eventDate)].join(' · '),
          _ts(d['updatedAt']) ?? _ts(d['createdAt']),
        ));
      }
      if (_events &&
          eventDate != null &&
          (status == 'approved' || status == 'depositPaid')) {
        final days = eventDate.difference(today).inDays;
        if (days >= 0 && days <= 7) {
          out.add(_Entry(
            Icons.event_outlined,
            days == 0 ? 'Event today: $who' : 'Event in $days days: $who',
            [eventType, dateText(eventDate)].join(' · '),
            now,
          ));
        }
      }
    }

    out.sort((a, b) {
      if (a.time == null && b.time == null) return 0;
      if (a.time == null) return 1;
      if (b.time == null) return -1;
      return b.time!.compareTo(a.time!);
    });
    return out;
  }

  Widget _inbox() {
    return StreamBuilder<List<ChatThread>>(
      stream: _threads,
      builder: (context, ts) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _quotesStream,
        builder: (context, qs) {
          if (ts.hasError || qs.hasError) {
            return const EmptyState(
              title: 'Could not load notifications',
              message: 'Check your connection and try again.',
            );
          }
          if (!ts.hasData && !qs.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = _entries(
            ts.data ?? const <ChatThread>[],
            qs.data?.docs ?? const [],
          );
          if (items.isEmpty) {
            return const EmptyState(
              title: 'Nothing new',
              message: 'New messages, quote requests and event reminders show up here.',
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final e = items[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: sand,
                  child: Icon(e.icon, color: espresso),
                ),
                title: Text(e.title),
                subtitle: e.body.isEmpty
                    ? null
                    : Text(e.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: Text(_ago(e.time), style: Theme.of(context).textTheme.bodySmall),
              );
            },
          );
        },
      ),
    );
  }

  Widget _settings() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        SwitchListTile(
          title: const Text('New messages'),
          subtitle: const Text('When a client sends you a message'),
          value: _messages,
          onChanged: (v) {
            setState(() => _messages = v);
            _save('pushMessages', v,
                inUsers: true, revert: () => setState(() => _messages = !v));
          },
        ),
        SwitchListTile(
          title: const Text('New quote requests'),
          subtitle: const Text('When a client asks for a quote'),
          value: _quotes,
          onChanged: (v) {
            setState(() => _quotes = v);
            _save('pushQuotes', v,
                inUsers: false, revert: () => setState(() => _quotes = !v));
          },
        ),
        SwitchListTile(
          title: const Text('Event reminders'),
          subtitle: const Text('Before an upcoming event'),
          value: _events,
          onChanged: (v) {
            setState(() => _events = v);
            _save('pushEvents', v,
                inUsers: false, revert: () => setState(() => _events = !v));
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Text(
            'Your choices are saved. They also decide what appears in your inbox.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          bottom: const TabBar(tabs: [Tab(text: 'Inbox'), Tab(text: 'Settings')]),
        ),
        body: TabBarView(children: [_inbox(), _settings()]),
      ),
    );
  }
}