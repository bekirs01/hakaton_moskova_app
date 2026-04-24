import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/core/ui/memeops_messenger.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/screens/auth_sign_in_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/config_missing_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/home_shell.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemeopsApp extends StatelessWidget {
  const MemeopsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = memeopsDarkTheme();
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        final title = lookupAppLocalizations(AppLocaleController.instance.locale).appTitle;
        if (!AppEnv.isSupabaseConfigured || !AppEnv.isApiConfigured) {
          return MaterialApp(
            title: title,
            theme: theme,
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: MemeopsMessenger.scaffoldMessengerKey,
            locale: AppLocaleController.instance.locale,
            supportedLocales: const [Locale('tr'), Locale('ru')],
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            localeResolutionCallback: (_, _) => AppLocaleController.instance.locale,
            home: const ConfigMissingScreen(),
          );
        }
        return MaterialApp(
          title: title,
          theme: theme,
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: MemeopsMessenger.scaffoldMessengerKey,
          locale: AppLocaleController.instance.locale,
          supportedLocales: const [Locale('tr'), Locale('ru')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          localeResolutionCallback: (_, _) => AppLocaleController.instance.locale,
          home: const _SessionGate(),
        );
      },
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session == null) {
          return const AuthSignInScreen();
        }
        return const HomeShell();
      },
    );
  }
}
