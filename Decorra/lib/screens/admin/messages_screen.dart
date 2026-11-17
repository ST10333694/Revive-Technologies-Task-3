import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/chat.dart';
import '../../services/chat_repository.dart';
import '../../services/client_admin_repository.dart';
import '../../services/session.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';
import 'chat_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final _repo = ChatRepository();
  late final Stream<List<ChatThread>> _threads = _repo.watchThreads();
  late final Stream<ChatMessage?> _teamLast = _repo.watchTeamLast();
  late final Stream<List<AppUser>> _clients = ClientAdminRepository()
      .watchClients()
      .map((snap) => snap.docs.map(AppUser.fromDoc).whereType<AppUser>().toList()
        ..sort((a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase())));
  final _search = TextEditingController();
  bool _searching = false;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openThread(ChatThread t) {
    final stream = _repo.watchThreadMessages(t.clientUid);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          title: t.clientName,
          subtitle: t.clientEmail,
          messages: stream,
          onSend: (text) => _repo.sendToClient(t.clientUid, text),
        ),
      ),
    );
  }

  void _openClient(AppUser c) {
    final stream = _repo.watchThreadMessages(c.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          title: c.fullName,
          subtitle: c.email,
          messages: stream,
          onSend: (text) => _repo.sendToClient(c.id, text),
        ),
      ),
    );
  }

  void _openTeam() {
    final name = context.read<Session>().user?.fullName ?? 'Team member';
    final stream = _repo.watchTeamMessages();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          title: 'Team chat',
          subtitle: 'Everyone on your team',
          showSender: true,
          messages: stream,
          onSend: (text) => _repo.sendToTeam(text, name),
        ),
      ),
    );
  }

  Widget _threadTile(ChatThread t) {
    final unread = t.lastFromClient;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: sand,
        child: Text(
          t.clientName.isEmpty ? '?' : t.clientName[0].toUpperCase(),
          style: const TextStyle(color: espresso),
        ),
      ),
      title: Text(
        t.clientName,
        style: TextStyle(fontWeight: unread ? FontWeight.w700 : FontWeight.w400),
      ),
      subtitle: Text(t.lastText, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(chatTime(t.lastTime), style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          if (unread)
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(color: espresso, shape: BoxShape.circle),
            ),
        ],
      ),
      onTap: () => _openThread(t),
    );
  }

  Widget _clientTile(AppUser c) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: sand,
        child: Text(
          c.firstName.isEmpty ? '?' : c.firstName[0].toUpperCase(),
          style: const TextStyle(color: espresso),
        ),
      ),
      title: Text(c.disabled ? '${c.fullName} (disabled)' : c.fullName),
      subtitle: const Text('No messages yet'),
      onTap: () => _openClient(c),
    );
  }

  Widget _teamTile(ChatMessage? last) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: sage,
        child: Icon(Icons.groups_outlined, color: espresso),
      ),
      title: const Text('Team chat'),
      subtitle: Text(
        last == null ? 'Start a conversation with your team' : last.text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: last == null
          ? null
          : Text(chatTime(last.time), style: Theme.of(context).textTheme.bodySmall),
      onTap: _openTeam,
    );
  }

  Widget _list(List<Widget> tiles, String emptyMessage) {
    if (tiles.isEmpty) {
      return EmptyState(title: 'No conversations', message: emptyMessage);
    }
    return ListView.separated(
      itemCount: tiles.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => tiles[i],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: _searching
              ? TextField(
                  controller: _search,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Search messages',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                )
              : const Text('Messages'),
          actions: [
            IconButton(
              tooltip: _searching ? 'Close search' : 'Search',
              icon: Icon(_searching ? Icons.close : Icons.search),
              onPressed: () => setState(() {
                _searching = !_searching;
                if (!_searching) {
                  _query = '';
                  _search.clear();
                }
              }),
            ),
          ],
          bottom: const TabBar(
            tabs: [Tab(text: 'All'), Tab(text: 'Clients'), Tab(text: 'Team')],
          ),
        ),
        body: StreamBuilder<List<ChatThread>>(
          stream: _threads,
          builder: (context, ts) => StreamBuilder<List<AppUser>>(
            stream: _clients,
            builder: (context, cs) => StreamBuilder<ChatMessage?>(
              stream: _teamLast,
              builder: (context, tl) {
                final q = _query.trim().toLowerCase();
                final allThreads = ts.data ?? const <ChatThread>[];
                final clients = cs.data ?? const <AppUser>[];
                final clientIds = clients.map((c) => c.id).toSet();

                // Clients who already have a conversation.
                final threads = allThreads
                    .where((t) => clientIds.contains(t.clientUid))
                    .where((t) =>
                        q.isEmpty ||
                        t.clientName.toLowerCase().contains(q) ||
                        t.lastText.toLowerCase().contains(q))
                    .toList();

                // Clients who have not messaged yet.
                final threadIds = allThreads.map((t) => t.clientUid).toSet();
                final fresh = clients
                    .where((c) => !threadIds.contains(c.id))
                    .where((c) => q.isEmpty || c.fullName.toLowerCase().contains(q))
                    .toList();

                final last = tl.data;
                final teamVisible = q.isEmpty ||
                    'team'.contains(q) ||
                    (last?.text.toLowerCase().contains(q) ?? false);

                final clientTiles = <Widget>[
                  ...threads.map(_threadTile),
                  ...fresh.map(_clientTile),
                ];
                final teamTile = _teamTile(last);

                return TabBarView(
                  children: [
                    _list(
                      [if (teamVisible) teamTile, ...clientTiles],
                      'Conversations will appear here.',
                    ),
                    _list(
                      clientTiles,
                      'Client accounts appear here as soon as people register.',
                    ),
                    _list(
                      [if (teamVisible) teamTile],
                      'No team messages match your search.',
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}