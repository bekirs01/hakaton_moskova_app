import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hakaton_moskova_app/core/config/app_config_loader.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/core/dev/embedded_memeops_dev_api.dart';
import 'package:hakaton_moskova_app/core/dev/memeops_local_probe.dart';
import 'package:hakaton_moskova_app/memeops_app.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfigLoader.ensureLoaded();
  await AppLocaleController.instance.load();
  if (kDebugMode) {
    if (AppEnv.skipEmbeddedMemeopsStub) {
      final apiUp = await memeopsLocalHealthOk();
      if (!apiUp && kDebugMode) {
        // ignore: avoid_print
        print(
          lookupAppLocalizations(AppLocaleController.instance.locale)
              .debugApiNotRunning(AppEnv.memeopsApiBase),
        );
      }
      // Python API yokken sahte Telegram + şablon fikirler üretme — bağlantı hatası gösterilir.
    } else {
      await EmbeddedMemeopsDevApi.tryStart();
    }
  }
  if (AppEnv.isSupabaseConfigured) {
    await Supabase.initialize(
      url: AppEnv.supabaseUrl,
      anonKey: AppEnv.supabaseAnonKey,
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const MemeopsApp());
}
