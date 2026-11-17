import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'push_service.dart';

enum SessionStatus { loading, signedOut, signedIn }

enum SignInResult { success, invalid, wrongRole, disabled, network, failed }

enum RegisterResult { success, invalidCode, emailTaken, network, failed }

enum ActionResult { success, network, failed }

/// Who is signed in. Accounts live in Firebase Authentication; each person's
/// profile and role live in the Firestore "users" collection.
///
/// [user] is only set once the role has been checked, so the app never flashes
/// the wrong home screen for a moment.
class Session extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SessionStatus status = SessionStatus.loading;
  AppUser? user;

  /// Called once at start-up: picks up a person who is still signed in.
  Future<void> restore() async {
    final current = _auth.currentUser;
    if (current == null) {
      _set(SessionStatus.signedOut, null);
      return;
    }
    try {
      final profile = await _loadProfile(current.uid);
      if (profile == null || profile.disabled) {
        // A disabled account is signed out on this device too.
        await _auth.signOut();
        _set(SessionStatus.signedOut, null);
        return;
      }
      _set(SessionStatus.signedIn, profile);
    } catch (_) {
      _set(SessionStatus.signedOut, null);
    }
  }

  Future<SignInResult> signIn(
    String email,
    String password,
    UserRole role,
  ) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user?.uid;
      if (uid == null) return SignInResult.failed;

      final profile = await _loadProfile(uid);
      if (profile == null) {
        await _auth.signOut();
        return SignInResult.failed;
      }
      if (profile.role != role) {
        await _auth.signOut();
        return SignInResult.wrongRole;
      }
      if (profile.disabled) {
        await _auth.signOut();
        return SignInResult.disabled;
      }
      _set(SessionStatus.signedIn, profile);
      return SignInResult.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-credential':
        case 'invalid-email':
        case 'user-not-found':
        case 'wrong-password':
        case 'user-disabled':
          return SignInResult.invalid;
        case 'network-request-failed':
          return SignInResult.network;
        default:
          return SignInResult.failed;
      }
    } on FirebaseException catch (e) {
      return e.code == 'unavailable'
          ? SignInResult.network
          : SignInResult.failed;
    } catch (_) {
      return SignInResult.failed;
    }
  }

  /// Clients register freely. A decorator also needs the access code that the
  /// owner keeps in the Firebase console; the Firestore rules check it, so it
  /// cannot be skipped from the app.
  Future<RegisterResult> register({
    required String first,
    required String last,
    required String email,
    required String phone,
    required String password,
    required UserRole role,
    required String accessCode,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    UserCredential cred;
    try {
      cred = await _auth.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return RegisterResult.emailTaken;
        case 'network-request-failed':
          return RegisterResult.network;
        default:
          return RegisterResult.failed;
      }
    } catch (_) {
      return RegisterResult.failed;
    }

    final firebaseUser = cred.user;
    if (firebaseUser == null) return RegisterResult.failed;

    final data = <String, dynamic>{
      'firstName': first.trim(),
      'lastName': last.trim(),
      'email': cleanEmail,
      'phone': phone.trim(),
      'role': role == UserRole.decorator ? 'decorator' : 'client',
      'disabled': false,
      'fcmTokens': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (role == UserRole.decorator) data['accessCode'] = accessCode.trim();

    try {
      await _db.collection('users').doc(firebaseUser.uid).set(data);
      final profile = await _loadProfile(firebaseUser.uid);
      if (profile == null) return RegisterResult.failed;
      _set(SessionStatus.signedIn, profile);
      return RegisterResult.success;
    } on FirebaseException catch (e) {
      // No profile was created, so do not leave a half-made account behind.
      try {
        await firebaseUser.delete();
      } catch (_) {}
      if (role == UserRole.decorator && e.code == 'permission-denied') {
        return RegisterResult.invalidCode;
      }
      return e.code == 'unavailable'
          ? RegisterResult.network
          : RegisterResult.failed;
    } catch (_) {
      try {
        await firebaseUser.delete();
      } catch (_) {}
      return RegisterResult.failed;
    }
  }

  /// Sends a reset link. Reports success even for unknown emails, so accounts
  /// cannot be probed.
  Future<ActionResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return ActionResult.success;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return ActionResult.success;
      return e.code == 'network-request-failed'
          ? ActionResult.network
          : ActionResult.failed;
    } catch (_) {
      return ActionResult.failed;
    }
  }

  /// Reloads the signed-in person's profile, for example after they edit it.
  /// Also signs the person out if the profile vanished or was disabled.
  Future<void> refreshProfile() async {
    final current = _auth.currentUser;
    if (current == null) return;
    try {
      final profile = await _loadProfile(current.uid);
      if (profile == null || profile.disabled) {
        await _auth.signOut();
        _set(SessionStatus.signedOut, null);
      } else {
        _set(SessionStatus.signedIn, profile);
      }
    } catch (_) {}
  }

  Future<void> signOut() async {
    await PushService.instance.unregister();
    await _auth.signOut();
    _set(SessionStatus.signedOut, null);
  }

  Future<AppUser?> _loadProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return AppUser.fromDoc(doc);
  }

  void _set(SessionStatus status, AppUser? user) {
    this.status = status;
    this.user = user;
    notifyListeners();
  }
}