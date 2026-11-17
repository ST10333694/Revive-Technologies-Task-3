import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'localization/strings.dart';
import 'models/app_user.dart';
import 'screens/admin/admin_shell.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/client/client_shell.dart';
import 'services/app_settings.dart';
import 'services/catalog_repository.dart';
import 'services/push_service.dart';
import 'services/session.dart';
import 'theme.dart';
import 'theme_dark.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Must come after Firebase is initialised.
  PushService.instance.start();

  // Reads the saved theme and language before the first screen draws.
  await AppSettings.instance.load();

  runApp(const DecorraApp());
}

class DecorraApp extends StatelessWidget {
  const DecorraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Session()..restore()),
        Provider(create: (_) => CatalogRepository()),
      ],
      child: ListenableBuilder(
        listenable: AppSettings.instance,
        builder: (context, _) => MaterialApp(
          title: 'Decorra',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: AppSettings.instance.themeMode,
          locale: AppSettings.instance.locale,
          supportedLocales: supportedLocales,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Chooses the first screen: loading, sign in, decorator or client.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return switch (session.status) {
      SessionStatus.loading =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
      SessionStatus.signedOut => const AuthScreen(),
      SessionStatus.signedIn => session.user?.role == UserRole.decorator
          ? const AdminShell()
          : const ClientShell(),
    };
  }
}
