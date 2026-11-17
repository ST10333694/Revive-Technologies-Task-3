// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Keeps this phone's push token saved on the signed-in user's profile
/// (users/{uid}.fcmTokens), so the push worker knows where to send.
class PushService {
  PushService._();
  static final instance = PushService._();

  StreamSubscription<User?>? _auth;
  StreamSubscription<String>? _refresh;

  /// Call once, after Firebase.initializeApp.
  void start() {
    _auth ??= FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _register(user.uid);
    });
    // ignore: deprecated_member_use
    _refresh ??= FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _save(uid, token);
    });
  }

  Future<void> _register(String uid) async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _save(uid, token);
    } catch (_) {
      // Push is optional: the app works without it.
    }
  }

  /// A brand-new account's profile may not exist for a few seconds, so retry.
  Future<void> _save(String uid, String token) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(uid);
    for (var attempt = 0; attempt < 4; attempt++) {
      try {
        await doc.update({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }).timeout(const Duration(seconds: 8));
        return;
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 4));
      }
    }
  }

  /// Call before signing out, so the next person on this phone
  /// does not receive the previous user's notifications.
  Future<void> unregister() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    try {
      // ignore: deprecated_member_use
      final token = await FirebaseMessaging.instance.getToken();
      if (uid != null && token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmTokens': FieldValue.arrayRemove([token]),
        }).timeout(const Duration(seconds: 5));
      }
      // ignore: deprecated_member_use
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }
}