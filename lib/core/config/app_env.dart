import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Public configuration only. Never log key material.
class AppEnv {
  const AppEnv._();

  static String _envLine(String key) {
    final v = dotenv.env[key];
    if (v == null) return '';
    return v.trim();
  }

  /// Android emulator maps host loopback to 10.0.2.2; iOS Simulator can use 127.0.0.1.
  static String _hostLoopbackForDevice(String base) {
    if (kIsWeb) return base;
    if (defaultTargetPlatform == TargetPlatform.android &&
        base.contains('127.0.0.1')) {
      return base.replaceAll('127.0.0.1', '10.0.2.2');
    }
    return base;
  }

  static String get memeopsApiBase {
    const fromDefine = String.fromEnvironment('MEMEOPS_API_BASE');
    if (fromDefine.isNotEmpty) {
      return _hostLoopbackForDevice(fromDefine);
    }
    final fromFile = _envLine('MEMEOPS_API_BASE');
    if (fromFile.isNotEmpty) {
      return _hostLoopbackForDevice(fromFile);
    }
    if (kDebugMode) {
      return _hostLoopbackForDevice('http://127.0.0.1:3000');
    }
    return '';
  }

  static String get supabaseUrl {
    const fromDefine = String.fromEnvironment('SUPABASE_URL');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _envLine('SUPABASE_URL');
  }

  static String get supabaseAnonKey {
    const fromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (fromDefine.isNotEmpty) return fromDefine;
    return _envLine('SUPABASE_ANON_KEY');
  }

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isApiConfigured => memeopsApiBase.isNotEmpty;
}
