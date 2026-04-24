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

  /// MEMEOPS base as configured (define / .env / debug default), before Android loopback rewrite.
  static String get rawMemeopsApiBase {
    const fromDefine = String.fromEnvironment('MEMEOPS_API_BASE');
    if (fromDefine.isNotEmpty) return fromDefine.trim();
    final fromFile = _envLine('MEMEOPS_API_BASE');
    if (fromFile.isNotEmpty) return fromFile;
    if (kDebugMode) return 'http://127.0.0.1:3000';
    return '';
  }

  static String get memeopsApiBase {
    final raw = rawMemeopsApiBase;
    if (raw.isEmpty) return '';
    return _hostLoopbackForDevice(raw);
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

  /// `MEMEOPS_USE_PYTHON_API=1` → skip in-app Dart stub so port 3000 is free for `./run_telegram_api.sh`.
  static bool get skipEmbeddedMemeopsStub {
    const d = String.fromEnvironment('MEMEOPS_USE_PYTHON_API');
    if (d == '1' || d.toLowerCase() == 'true') return true;
    final f = _envLine('MEMEOPS_USE_PYTHON_API').toLowerCase();
    return f == '1' || f == 'true' || f == 'yes';
  }

  /// @BotFather bot token — yalnızca kanala paylaşım için; repoya yazmayın.
  static String get telegramPublishBotToken {
    const fromDefine = String.fromEnvironment('TELEGRAM_PUBLISH_BOT_TOKEN');
    if (fromDefine.isNotEmpty) return fromDefine.trim();
    return _envLine('TELEGRAM_PUBLISH_BOT_TOKEN');
  }

  /// Kanal kullanıcı adı (`@memasicspace`) veya sayısal `chat_id` (`-100...`).
  static String get telegramPublishChannel {
    const fromDefine = String.fromEnvironment('TELEGRAM_PUBLISH_CHANNEL');
    if (fromDefine.isNotEmpty) return fromDefine.trim();
    return _envLine('TELEGRAM_PUBLISH_CHANNEL');
  }

  static bool get isTelegramPublishConfigured =>
      telegramPublishBotToken.isNotEmpty && telegramPublishChannel.isNotEmpty;

  /// OAuth istemci id (yalnızca `setup_vk_user_token.sh` / dokümantasyon; API çağrılarında kullanılmaz).
  static String get vkAppId {
    const fromDefine = String.fromEnvironment('VK_APP_ID');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return _envLine('VK_APP_ID');
  }

  /// VK: uygulamada ayrıca set edilebilen ham token (geçmiş uyumluluk). Repoya koyma.
  static String get vkAccessToken {
    const fromDefine = String.fromEnvironment('VK_ACCESS_TOKEN');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return _envLine('VK_ACCESS_TOKEN');
  }

  /// Kullanıcı (OAuth) access token. Topluluk/gizli grup token’ı ile
  /// `photos.getWallUploadServer` çağrılamaz; doluysa tüm [VkWallClient] istekleri buna gider.
  static String get vkUserAccessToken {
    const fromDefine = String.fromEnvironment('VK_USER_ACCESS_TOKEN');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return _envLine('VK_USER_ACCESS_TOKEN');
  }

  /// [VkWallClient] için: önce kullanıcı token, yoksa [vkAccessToken].
  static String get vkApiAccessToken {
    final u = vkUserAccessToken;
    if (u.isNotEmpty) {
      return u;
    }
    return vkAccessToken;
  }

  /// Pozitif grup id (vk.com/club[ … ]), boş bırakılırsa sadece kendi duvarı (destek sınırlı).
  static String get vkGroupId {
    const fromDefine = String.fromEnvironment('VK_GROUP_ID');
    if (fromDefine.isNotEmpty) {
      return fromDefine.trim();
    }
    return _envLine('VK_GROUP_ID');
  }

  static bool get isVkPublishConfigured =>
      vkGroupId.isNotEmpty && vkApiAccessToken.isNotEmpty;
}
