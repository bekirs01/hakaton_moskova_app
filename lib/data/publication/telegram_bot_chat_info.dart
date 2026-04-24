import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:http/http.dart' as http;

/// [getChat] ile kanal adı; Bot API, kanal yöneticisi bot için çalışır.
Future<String?> fetchTelegramChannelTitleForCurrentPublish() async {
  if (!AppEnv.isTelegramPublishConfigured) {
    return null;
  }
  final token = AppEnv.telegramPublishBotToken;
  final chatId = AppEnv.telegramPublishChannel;
  final u = Uri.parse(
    'https://api.telegram.org/bot$token/getChat?'
    'chat_id=${Uri.encodeQueryComponent(chatId)}',
  );
  const timeout = Duration(seconds: 12);
  try {
    final res = await http.get(u).timeout(timeout);
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
