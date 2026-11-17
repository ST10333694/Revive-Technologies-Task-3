import 'package:flutter/material.dart';

import '../../localization/strings.dart';
import '../../services/app_settings.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  static const _options = [
    (ThemeMode.system, Icons.phone_android, 'systemDefault'),
    (ThemeMode.light, Icons.light_mode_outlined, 'light'),
    (ThemeMode.dark, Icons.dark_mode_outlined, 'dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('theme'))),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(context.tr('appearance'), style: text.titleSmall),
            ),
            for (final (mode, icon, key) in _options)
              ListTile(
                leading: Icon(icon),
                title: Text(context.tr(key)),
                selected: settings.themeMode == mode,
                trailing: settings.themeMode == mode ? const Icon(Icons.check) : null,
                onTap: () => settings.setThemeMode(mode),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(context.tr('themeNote'), style: text.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}