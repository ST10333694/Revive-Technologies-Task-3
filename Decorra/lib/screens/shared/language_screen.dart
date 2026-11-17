import 'package:flutter/material.dart';

import '../../localization/strings.dart';
import '../../services/app_settings.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('language'))),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          final current = settings.locale?.languageCode;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_android),
                title: Text(context.tr('systemDefault')),
                selected: current == null,
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () => settings.setLanguage(null),
              ),
              for (final language in supportedLanguages)
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(language.nativeName),
                  subtitle: language.nativeName == language.englishName
                      ? null
                      : Text(language.englishName),
                  selected: current == language.code,
                  trailing: current == language.code ? const Icon(Icons.check) : null,
                  onTap: () => settings.setLanguage(language.code),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(context.tr('languageNote'), style: text.bodySmall),
              ),
            ],
          );
        },
      ),
    );
  }
}