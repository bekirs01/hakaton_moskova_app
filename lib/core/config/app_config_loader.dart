import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads layered public config: [assets/env/bootstrap.env] then optional root [.env] asset.
/// `--dart-define` values are read at compile time in [AppEnv] and take precedence there.
class AppConfigLoader {
  const AppConfigLoader._();

  static bool _didLoad = false;

  static Future<void> ensureLoaded() async {
    if (_didLoad) return;
    await dotenv.load(fileName: 'assets/env/bootstrap.env');
    try {
      await dotenv.load(fileName: '.env', mergeWith: dotenv.env);
    } catch (_) {
      // Root `.env` may be absent from the asset bundle in some builds; defines still apply.
    }
    _didLoad = true;
  }
}
