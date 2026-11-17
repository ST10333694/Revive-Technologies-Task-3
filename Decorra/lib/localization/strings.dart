import 'package:flutter/widgets.dart';

class AppLanguage {
  const AppLanguage(this.code, this.nativeName, this.englishName);

  final String code;
  final String nativeName;
  final String englishName;
}

/// Only add languages that Flutter's built-in widgets support (the date picker, dialogs
/// and so on): English, Afrikaans and isiZulu are covered. isiXhosa and Sesotho are not.
const supportedLanguages = [
  AppLanguage('en', 'English', 'English'),
  AppLanguage('af', 'Afrikaans', 'Afrikaans'),
  AppLanguage('zu', 'isiZulu', 'Zulu'),
];

final supportedLocales = [for (final l in supportedLanguages) Locale(l.code)];

extension Translate on BuildContext {
  /// Looks the text up in the current language, falling back to English.
  /// Values like {name} are filled from [args].
  String tr(String key, [Map<String, String> args = const {}]) {
    final code = Localizations.localeOf(this).languageCode;
    var text = _strings[code]?[key] ?? _strings['en']![key] ?? key;
    args.forEach((name, value) => text = text.replaceAll('{$name}', value));
    return text;
  }
}

const _strings = <String, Map<String, String>>{
  'en': {
    'home': 'Home',
    'quotes': 'Quotes',
    'chats': 'Chats',
    'profile': 'Profile',
    'settings': 'Settings',
    'generalSettings': 'General Settings',
    'notifications': 'Notifications',
    'theme': 'Theme',
    'language': 'Language',
    'privacy': 'Privacy & Security',
    'aboutApp': 'About App',
    'appearance': 'Appearance',
    'systemDefault': 'Phone default',
    'light': 'Light',
    'dark': 'Dark',
    'themeNote': 'Saved on this phone.',
    'languageNote': 'Some screens are still in English while the app is being translated.',
    'welcomeBack': 'Welcome back, {name}!',
    'welcomeBackNoName': 'Welcome back!',
    'startJourney': 'Start your journey',
    'browsePrompt': 'Browse our portfolio and create your perfect event.',
    'browsePortfolio': 'Browse Portfolio',
    'myQuotes': 'My Quotes',
    'myDesigns': 'My Designs',
    'messageDecorator': 'Message Decorator',
  },
  'af': {
    'home': 'Tuis',
    'quotes': 'Kwotasies',
    'chats': 'Gesprekke',
    'profile': 'Profiel',
    'settings': 'Instellings',
    'generalSettings': 'Algemene instellings',
    'notifications': 'Kennisgewings',
    'theme': 'Tema',
    'language': 'Taal',
    'privacy': 'Privaatheid en sekuriteit',
    'aboutApp': 'Oor die toepassing',
    'appearance': 'Voorkoms',
    'systemDefault': 'Foonverstek',
    'light': 'Lig',
    'dark': 'Donker',
    'themeNote': 'Op hierdie foon gestoor.',
    'languageNote': 'Sommige skerms is nog in Engels terwyl die toepassing vertaal word.',
    'welcomeBack': 'Welkom terug, {name}!',
    'welcomeBackNoName': 'Welkom terug!',
    'startJourney': 'Begin jou reis',
    'browsePrompt': 'Blaai deur ons portefeulje en skep jou perfekte geleentheid.',
    'browsePortfolio': 'Blaai deur portefeulje',
    'myQuotes': 'My kwotasies',
    'myDesigns': 'My ontwerpe',
    'messageDecorator': 'Stuur boodskap aan versierder',
  },
  'zu': {
    'home': 'Ikhaya',
    'quotes': 'Amakhotheshini',
    'chats': 'Izingxoxo',
    'profile': 'Iphrofayela',
    'settings': 'Izilungiselelo',
    'generalSettings': 'Izilungiselelo ezijwayelekile',
    'notifications': 'Izaziso',
    'theme': 'Ukubukeka',
    'language': 'Ulimi',
    'privacy': 'Ubumfihlo nokuphepha',
    'aboutApp': 'Mayelana nohlelo lokusebenza',
    'appearance': 'Ukubukeka',
    'systemDefault': 'Okuzenzakalelayo kwefoni',
    'light': 'Okukhanyayo',
    'dark': 'Okumnyama',
    'themeNote': 'Kugcinwe kule foni.',
    'languageNote': 'Ezinye izikrini zisesesiNgisini kuze kuhunyushwe uhlelo lokusebenza.',
    'welcomeBack': 'Siyakwamukela futhi, {name}!',
    'welcomeBackNoName': 'Siyakwamukela futhi!',
    'startJourney': 'Qala uhambo lwakho',
    'browsePrompt': 'Phequlula iphotifoliyo yethu bese wakha umcimbi wakho oyiphelele.',
    'browsePortfolio': 'Phequlula iphotifoliyo',
    'myQuotes': 'Amakhotheshini ami',
    'myDesigns': 'Imiklamo yami',
    'messageDecorator': 'Thumela umyalezo kumhlobisi',
  },
};