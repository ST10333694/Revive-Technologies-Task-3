import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _hide = true;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _change() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      _toast('Please log in again and retry.');
      return;
    }

    setState(() => _saving = true);
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: email, password: _current.text),
      );
      await user.updatePassword(_new.text);
      _current.clear();
      _new.clear();
      _confirm.clear();
      _toast('Password changed');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          _toast('Your current password is wrong.');
        case 'weak-password':
          _toast('Choose a stronger password.');
        case 'network-request-failed':
          _toast('No connection. Check your internet and try again.');
        case 'requires-recent-login':
          _toast('Please log out, sign in again, then try once more.');
        default:
          _toast('Could not change the password.');
      }
    } catch (_) {
      _toast('Could not change the password.');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Change password', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _current,
              enabled: !_saving,
              obscureText: _hide,
              decoration: InputDecoration(
                labelText: 'Current password',
                suffixIcon: IconButton(
                  tooltip: _hide ? 'Show passwords' : 'Hide passwords',
                  icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _hide = !_hide),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'This field is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _new,
              enabled: !_saving,
              obscureText: _hide,
              decoration: const InputDecoration(labelText: 'New password'),
              validator: (v) {
                if (v == null || v.isEmpty) return 'This field is required';
                return v.length < 8 ? 'Use at least 8 characters' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirm,
              enabled: !_saving,
              obscureText: _hide,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
              validator: (v) => v == _new.text ? null : 'Passwords do not match',
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _change,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Change password'),
            ),
          ],
        ),
      ),
    );
  }
}