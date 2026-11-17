import 'decor_event.dart';

/// One conversation with a client. The id is the client's Firebase user id.
class ChatThread {
  const ChatThread({
    required this.clientUid,
    required this.clientName,
    required this.clientEmail,
    required this.lastText,
    required this.lastTime,
    required this.lastFromClient,
  });

  final String clientUid;
  final String clientName;
  final String clientEmail;
  final String lastText;
  final DateTime lastTime;

  /// True when the client wrote last, so the decorator still owes a reply.
  final bool lastFromClient;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.fromMe,
    required this.time,
    this.senderName = '',
  });

  final String id;
  final String text;
  final bool fromMe;
  final DateTime time;
  final String senderName;
}

/// "10:30 AM" for today, otherwise "20 May 2026".
String chatTime(DateTime t) {
  final now = DateTime.now();
  final sameDay = t.year == now.year && t.month == now.month && t.day == now.day;
  if (!sameDay) return dateText(t);
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final minute = t.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${t.hour < 12 ? 'AM' : 'PM'}';
}