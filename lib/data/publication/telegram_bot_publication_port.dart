import 'dart:convert';
import 'dart:io';

import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/core/config/telegram_publish_channel.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_bot_chat_info.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:http/http.dart' as http;

/// Telegram Bot API ile kanala görsel gönderir (`sendPhoto` / `sendVideo`).
class TelegramBotPublicationPort implements PublicationPort {
  TelegramBotPublicationPort();

  static const _timeout = Duration(seconds: 45);

  String _botTokenForSend(String rawInput) {
    final def = AppEnv.telegramPublishBotToken;
    final d = TelegramPublishChannel.findForChatId(
      AppEnv.telegramPublishDestinations,
      rawInput,
    );
    if (d == null) {
      return def;
    }
    return d.effectiveBotToken(def);
  }

  @override
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
    File? localFile,
    bool isVideo = false,
    String? captionOverride,
    String? telegramChatId,
  }) async {
    if (!AppEnv.isTelegramPublishConfigured) {
      return const PublicationResult(comingSoon: true);
    }
    final raw = (telegramChatId != null && telegramChatId.trim().isNotEmpty)
        ? telegramChatId
        : AppEnv.telegramPublishChannel;
    final botToken = _botTokenForSend(raw);
    if (botToken.isEmpty) {
      return const PublicationResult(
        comingSoon: false,
        message: 'No Telegram bot token (check .env).',
      );
    }
    final resolved = await resolveTelegramIdForSend(raw, botToken: botToken);
    if (resolved.abortWithMessage != null) {
      return PublicationResult(
        comingSoon: false,
        message: resolved.abortWithMessage,
      );
    }
    final effectiveId = resolved.idForApi;
    if (effectiveId.isEmpty) {
      return const PublicationResult(
        comingSoon: false,
        message: 'No chat_id for Telegram send.',
      );
    }
    final caption = (captionOverride?.trim().isNotEmpty == true
            ? captionOverride!.trim()
            : (brief?.displayLine ?? '').trim());
    if (localFile != null) {
      return _publishLocalFile(
        localFile,
        isVideo: isVideo,
        caption: caption,
        chatId: effectiveId,
        botToken: botToken,
      );
    }
    final photo = imageUrl?.trim() ?? '';
    if (photo.isEmpty) {
      return const PublicationResult(
        comingSoon: false,
        message: 'No image URL to publish.',
      );
    }
    final uri = Uri.parse('https://api.telegram.org/bot$botToken/sendPhoto');
    final body = <String, String>{
      'chat_id': effectiveId,
      'photo': photo,
      if (caption.isNotEmpty)
        'caption': caption.length > 1024 ? caption.substring(0, 1024) : caption,
    };
    try {
      final res = await http.post(uri, body: body).timeout(_timeout);
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      final ok = decoded?['ok'] == true;
      if (ok) {
        return _parseOk(decoded ?? <String, dynamic>{});
      }
      final desc =
          decoded?['description'] as String? ?? 'HTTP ${res.statusCode}: ${res.body}';
      return PublicationResult(comingSoon: false, message: desc);
    } catch (e) {
      return PublicationResult(comingSoon: false, message: e.toString());
    }
  }

  Future<PublicationResult> _publishLocalFile(
    File file, {
    required bool isVideo,
    required String caption,
    required String chatId,
    required String botToken,
  }) async {
    final method = isVideo ? 'sendVideo' : 'sendPhoto';
    final field = isVideo ? 'video' : 'photo';
    final uri = Uri.parse('https://api.telegram.org/bot$botToken/$method');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = chatId;
      if (caption.isNotEmpty) {
        request.fields['caption'] =
            caption.length > 1024 ? caption.substring(0, 1024) : caption;
      }
      request.files.add(await http.MultipartFile.fromPath(field, file.path));
      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      final ok = decoded?['ok'] == true;
      if (ok) {
        return _parseOk(decoded ?? <String, dynamic>{});
      }
      final desc =
          decoded?['description'] as String? ?? 'HTTP ${res.statusCode}: ${res.body}';
      return PublicationResult(comingSoon: false, message: desc);
    } catch (e) {
      return PublicationResult(comingSoon: false, message: e.toString());
    }
  }

  static PublicationResult _parseOk(Map<String, dynamic> decoded) {
    final r = decoded['result'];
    if (r is! Map) {
      return const PublicationResult(comingSoon: false);
    }
    final rm = Map<String, dynamic>.from(r);
    int? messageId;
    final mid = rm['message_id'];
    if (mid is int) {
      messageId = mid;
    } else if (mid is num) {
      messageId = mid.toInt();
    }
    String? chatId;
    final chat = rm['chat'];
    if (chat is Map) {
      final m = Map<String, dynamic>.from(chat);
      final id = m['id'];
      if (id != null) {
        chatId = id.toString();
      }
    }
    int? views;
    final v = rm['views'];
    if (v is int) {
      views = v;
    } else if (v is num) {
      views = v.toInt();
    }
    int? forwards;
    for (final k in <String>['forwards', 'forward_count']) {
      final x = rm[k];
      if (x is int) {
        forwards = x;
        break;
      }
      if (x is num) {
        forwards = x.toInt();
        break;
      }
    }
    return PublicationResult(
      comingSoon: false,
      telegramMessageId: messageId,
      telegramChatId: chatId,
      telegramViews: views,
      telegramForwards: forwards,
    );
  }
}
