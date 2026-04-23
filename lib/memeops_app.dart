import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/presentation/screens/auth_sign_in_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/config_missing_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/home_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemeopsApp extends StatelessWidget {
  const MemeopsApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppEnv.isSupabaseConfigured || !AppEnv.isApiConfigured) {
      return const MaterialApp(
        title: 'MemeOps',
        home: ConfigMissingScreen(),
      );
    }
    return MaterialApp(
      title: 'MemeOps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const _SessionGate(),
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
