import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/chat.dart';

/// The client's own conversation: threads/{myUid} and its messages.
/// Same layout the Android app used, so old conversations carry over.
class ClientChatRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DateTime _time(Object? value) => value is Timestamp ? value.toDate() : DateTime.now();

  Stream<List<ChatMessage>> watchMine() {
    final uid = _uid;
    if (uid == null) return Stream.value(const <ChatMessage>[]);
    return _db
        .collection('threads')
        .doc(uid)
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
                fromMe: d['fromClient'] as bool? ?? true,
                time: _time(d['sentAt']),
              );
            }).toList());
  }

  /// Queued by Firestore while offline and sent when the phone reconnects.
  Future<void> send(String text, {required String name, required String email}) {
    final uid = _uid;
    if (uid == null) return Future.error(StateError('Not signed in'));

    final thread = _db.collection('threads').doc(uid);
    final message = thread.collection('messages').doc();
    final batch = _db.batch()
      ..set(message, {
        'text': text,
        'fromClient': true,
        'senderUid': uid,
        'sentAt': FieldValue.serverTimestamp(),
      })
      ..set(
        thread,
        {
          'clientUid': uid,
          'clientName': name,
          'clientEmail': email,
          'lastText': text,
          'lastFromClient': true,
          'lastTime': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    return batch.commit();
  }
}