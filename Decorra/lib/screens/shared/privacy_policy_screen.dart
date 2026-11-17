import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _text = '''
PLACEHOLDER — replace with your real POPIA-compliant policy.

Decorra collects the information you provide when you register
(name, email, phone) and the event details you submit. This
information is used only to prepare quotes and manage your events.

Your data is stored in Google Firebase (Firestore and Authentication),
which provides encryption in transit and at rest. We do not sell your
data.

You may request deletion of your account by contacting the decorator.

This policy is governed by the Protection of Personal Information Act
(POPIA) of South Africa.
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(_text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}