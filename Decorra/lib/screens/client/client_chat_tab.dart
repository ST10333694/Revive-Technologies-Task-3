import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business.dart';
import '../../models/chat.dart';
import '../../services/business_repository.dart';
import '../../services/client_chat_repository.dart';
import '../../services/session.dart';
import '../admin/chat_screen.dart';

/// The client's chat with the decorator. Reuses the same chat screen as the admin side.
class ClientChatTab extends StatefulWidget {
  const ClientChatTab({super.key});

  @override
  State<ClientChatTab> createState() => _ClientChatTabState();
}

class _ClientChatTabState extends State<ClientChatTab> {
  final _repo = ClientChatRepository();
  late final Stream<List<ChatMessage>> _messages = _repo.watchMine();
  late final Stream<BusinessProfile> _business = BusinessRepository().watchProfile();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user;

    return StreamBuilder<BusinessProfile>(
      stream: _business,
      builder: (context, snap) {
        final name = snap.data?.name ?? '';
        return ChatScreen(
          title: name.isEmpty ? 'Your decorator' : name,
          messages: _messages,
          onSend: (text) => _repo.send(
            text,
            name: user?.fullName ?? '',
            email: user?.email ?? '',
          ),
        );
      },
    );
  }
}