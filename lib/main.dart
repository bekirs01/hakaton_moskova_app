import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hakaton_moskova_app/core/config/app_config_loader.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/memeops_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfigLoader.ensureLoaded();
  if (AppEnv.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MemeopsApp());
}
