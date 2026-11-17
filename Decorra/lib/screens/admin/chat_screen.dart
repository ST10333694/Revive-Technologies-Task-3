import 'package:flutter/material.dart';

import '../../models/chat.dart';
import '../../theme.dart';
import '../../widgets/empty_state.dart';

/// One conversation. Used for client chats and for the team chat.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.title,
    this.subtitle,
    required this.messages,
    required this.onSend,
    this.showSender = false,
  });

  final String title;
  final String? subtitle;
  final Stream<List<ChatMessage>> messages;
  final Future<void> Function(String text) onSend;

  /// Show who wrote each message (for the group chat).
  final bool showSender;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    widget.onSend(text).catchError((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That message could not be sent.')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title),
            if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
              Text(widget.subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: widget.messages,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const EmptyState(
                    title: 'Could not load messages',
                    message: 'Check your connection and try again.',
                  );
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final items = snap.data!.reversed.toList();
                if (items.isEmpty) {
                  return const EmptyState(title: 'No messages yet', message: 'Say hello below.');
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _Bubble(message: items[i], showSender: widget.showSender),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Type a message',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Send',
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.showSender});

  final ChatMessage message;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromMe;
    final text = Theme.of(context).textTheme;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? sand : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: mine ? null : Border.all(color: taupe.withAlpha(128)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSender && !mine && message.senderName.isNotEmpty)
              Text(
                message.senderName,
                style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            Text(message.text, style: text.bodyLarge),
            const SizedBox(height: 2),
            Text(chatTime(message.time), style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}