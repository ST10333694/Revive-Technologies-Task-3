import 'package:flutter/material.dart';

import '../../localization/strings.dart';
import '../shared/language_screen.dart';
import '../shared/notification_settings_screen.dart';
import '../shared/privacy_policy_screen.dart';
import '../shared/theme_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_screen.dart';

/// Used by both decorators and clients.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _row(BuildContext context, IconData icon, String label,
      VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _open(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        children: [
          _row(
              context,
              Icons.tune,
              context.tr('generalSettings'),
              () => _open(context, const EditProfileScreen())),
          _row(
              context,
              Icons.notifications_outlined,
              context.tr('notifications'),
              () => _open(context, const NotificationSettingsScreen())),
          _row(context, Icons.palette_outlined, context.tr('theme'),
              () => _open(context, const ThemeScreen())),
          _row(context, Icons.language, context.tr('language'),
              () => _open(context, const LanguageScreen())),
          _row(context, Icons.lock_outline, context.tr('privacy'),
              () => _open(context, const PrivacyScreen())),
          _row(
              context,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              () => _open(context, const PrivacyPolicyScreen())),
          _row(
            context,
            Icons.info_outline,
            context.tr('aboutApp'),
            () => showAboutDialog(
              context: context,
              applicationName: 'Decorra',
              applicationVersion: '0.1.0',
              applicationLegalese: 'Excellence in every event.',
            ),
          ),
        ],
      ),
    );
  }
}