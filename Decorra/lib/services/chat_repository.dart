import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat.dart';

/// Client chats use the same Firestore layout as the Android app:
///   threads/{clientUid}            summary of the conversation
///   threads/{clientUid}/messages   the messages
/// The team chat is one group chat in "teamMessages".
class ChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// A message the server has not stamped yet counts as "now".
  DateTime _time(Object? value) => value is Timestamp ? value.toDate() : DateTime.now();

  Stream<List<ChatThread>> watchThreads() => _db.collection('threads').snapshots().map((snap) {
        final list = snap.docs.map((doc) {
          final d = doc.data();
          final email = d['clientEmail'] as String? ?? '';
          final name = d['clientName'] as String? ?? '';
          return ChatThread(
            clientUid: doc.id,
            clientName: name.isNotEmpty ? name : (email.isNotEmpty ? email : 'Client'),
            clientEmail: email,
            lastText: d['lastText'] as String? ?? '',
            lastTime: _time(d['lastTime']),
            lastFromClient: d['lastFromClient'] as bool? ?? false,
          );
        }).toList();
        list.sort((a, b) => b.lastTime.compareTo(a.lastTime));
        return list;
      });

  Stream<List<ChatMessage>> watchThreadMessages(String threadId) => _db
      .collection('threads')
      .doc(threadId)
      .collection('messages')
      .orderBy('sentAt')
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
            final d = doc.data();
            final text = d['text'] as String? ?? '';
            final file = d['fileName'] as String?;
            return ChatMessage(
              id: doc.id,
              text: text.isEmpty && file != null ? 'Attachment: $file' : text,
              fromMe: !(d['fromClient'] as bool? ?? true),
              time: _time(d['sentAt']),
            );
          }).toList());

  /// Queued by Firestore while offline and sent when the phone reconnects.
  Future<void> sendToClient(String threadId, String text) {
    final thread = _db.collection('threads').doc(threadId);
    final message = thread.collection('messages').doc();
    final batch = _db.batch()
      ..set(message, {
        'text': text,
        'fromClient': false,
        'senderUid': _uid,
        'sentAt': FieldValue.serverTimestamp(),
      })
      ..set(
        thread,
        {
          'lastText': text,
          'lastFromClient': false,
          'lastTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    return batch.commit();
  }

  ChatMessage _teamMessage(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data();
    return ChatMessage(
      id: doc.id,
      text: d['text'] as String? ?? '',
      fromMe: d['senderUid'] == _uid,
      senderName: d['senderName'] as String? ?? '',
      time: _time(d['sentAt']),
    );
  }

  Stream<List<ChatMessage>> watchTeamMessages() => _db
      .collection('teamMessages')
      .orderBy('sentAt')
      .snapshots()
      .map((snap) => snap.docs.map(_teamMessage).toList());

  /// The newest team message, or null when nobody has written yet.
  Stream<ChatMessage?> watchTeamLast() => _db
      .collection('teamMessages')
      .orderBy('sentAt', descending: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : _teamMessage(snap.docs.first));

  Future<void> sendToTeam(String text, String senderName) => _db
      .collection('teamMessages')
      .add({
        'text': text,
        'senderUid': _uid,
        'senderName': senderName,
        'sentAt': FieldValue.serverTimestamp(),
      })
      .then((_) {});
}