import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_chat_id.dart';
import 'package:http/http.dart' as http;

const Duration _kChatTimeout = Duration(seconds: 15);

class TelegramSendIdOutcome {
  const TelegramSendIdOutcome({
    required this.idForApi,
    this.abortWithMessage,
  });
  final String idForApi;
  final String? abortWithMessage;
}

/// token + normalize(raw) -> Telegram’ın [getChat] [id] önbelleği
final Map<String, String> _resolveCache = <String, String>{};

/// [botToken] bu kanalda yönetici olmalı.
Future<TelegramSendIdOutcome> resolveTelegramIdForSend(
  String raw, {
  required String botToken,
}) async {
  final n = TelegramChatId.normalizeForApi(raw);
  if (n.isEmpty) {
    return const TelegramSendIdOutcome(
      idForApi: '',
      abortWithMessage: 'Missing Telegram chat_id (check .env).',
    );
  }
  if (botToken.isEmpty) {
    return const TelegramSendIdOutcome(
      idForApi: '',
      abortWithMessage: 'Missing Telegram bot token (check .env).',
    );
  }
  final cacheKey = '$n|$botToken';
  final hit = _resolveCache[cacheKey];
  if (hit != null) {
    return TelegramSendIdOutcome(idForApi: hit);
  }
  final u = Uri.parse(
    'https://api.telegram.org/bot$botToken/getChat?'
    'chat_id=${Uri.encodeQueryComponent(n)}',
  );
  try {
    final res = await http.get(u).timeout(_kChatTimeout);
    final m = jsonDecode(res.body) as Map<String, dynamic>?;
    if (m?['ok'] == true) {
      final r = m!['result'];
      if (r is! Map) {
        return TelegramSendIdOutcome(idForApi: n);
      }
      final id = r['id'];
      if (id == null) {
        return TelegramSendIdOutcome(idForApi: n);
      }
      final s = id.toString();
      _resolveCache[cacheKey] = s;
      return TelegramSendIdOutcome(idForApi: s);
    }
    final desc = (m?['description'] as String?)?.trim() ?? 'getChat failed';
    return TelegramSendIdOutcome(idForApi: n, abortWithMessage: desc);
  } catch (e, st) {
    debugPrint('getChat (resolve for send): $e\n$st');
    return TelegramSendIdOutcome(idForApi: n);
  }
}

/// Kanal adı; [botToken] o kanalda yönetici olmalı.
Future<String?> fetchTelegramChannelTitleForChatId(
  String chatId, {
  required String botToken,
}) async {
  final id = TelegramChatId.normalizeForApi(chatId);
  if (id.isEmpty || botToken.isEmpty) {
    return null;
  }
  final u = Uri.parse(
    'https://api.telegram.org/bot$botToken/getChat?'
    'chat_id=${Uri.encodeQueryComponent(id)}',
  );
  try {
    final res = await http.get(u).timeout(const Duration(seconds: 12));
    final m = jsonDecode(res.body) as Map<String, dynamic>?;
    if (m?['ok'] != true) {
      return null;
    }
    final r = m!['result'];
    if (r is! Map) {
      return null;
    }
    final rm = Map<String, dynamic>.from(r);
    final title = (rm['title'] as String?)?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }
    final un = (rm['username'] as String?)?.trim();
    if (un != null && un.isNotEmpty) {
      return '@$un';
    }
  } catch (e, st) {
    debugPrint('getChat: $e\n$st');
  }
  return null;
}

/// Varsayılan hedef; [AppEnv.telegramPublishChannel] + global token.
Future<String?> fetchTelegramChannelTitleForCurrentPublish() async {
  if (!AppEnv.isTelegramPublishConfigured) {
    return null;
  }
  final t = AppEnv.telegramPublishBotToken;
  if (t.isEmpty) {
    return null;
  }
  return fetchTelegramChannelTitleForChatId(
    AppEnv.telegramPublishChannel,
    botToken: t,
  );
}
