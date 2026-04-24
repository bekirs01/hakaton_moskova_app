import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_chat_id.dart';

/// Bir Telegram hedefi; [botToken] yoksa genel [TELEGRAM_PUBLISH_BOT_TOKEN] kullanılır.
/// [uiName] = [.env] `display_name` (dil değişse de sabit gösterim); yoksa [label].
@immutable
class TelegramPublishChannel {
  const TelegramPublishChannel({
    required this.chatId,
    required this.label,
    required this.keywords,
    required this.uiName,
    this.botToken,
  });

  final String chatId;
  final String label;
  final List<String> keywords;
  final String uiName;
  final String? botToken;

  /// [fallback] genelde [AppEnv.telegramPublishBotToken].
  String effectiveBotToken(String fallback) {
    final t = botToken?.trim();
    if (t != null && t.isNotEmpty) {
      return t;
    }
    return fallback;
  }

  static TelegramPublishChannel? findForChatId(
    List<TelegramPublishChannel> list,
    String rawChatId,
  ) {
    final n = TelegramChatId.normalizeForApi(rawChatId);
    for (final d in list) {
      if (TelegramChatId.normalizeForApi(d.chatId) == n) {
        return d;
      }
    }
    return null;
  }

  static List<TelegramPublishChannel> parseJsonList(String raw) {
    final t = raw.trim();
    if (t.isEmpty) {
      return const [];
    }
    try {
      final decoded = jsonDecode(t);
      if (decoded is! List) {
        return const [];
      }
      final out = <TelegramPublishChannel>[];
      for (final e in decoded) {
        if (e is! Map) {
          continue;
        }
        final m = Map<String, dynamic>.from(e);
        final rawId = m['id'] ?? m['chat_id'];
        final id = rawId == null ? '' : rawId.toString().trim();
        if (id.isEmpty) {
          continue;
        }
        final rawLabel = m['label'] ?? m['name'];
        final label =
            rawLabel == null ? '' : rawLabel.toString().trim();
        final rawDisplay =
            m['display_name'] ?? m['displayName'] ?? m['channel_name'];
        final display = rawDisplay == null
            ? ''
            : rawDisplay.toString().trim();
        final rawBt = m['bot_token'] ?? m['bot'] ?? m['token'];
        final bt = rawBt == null
            ? null
            : (rawBt.toString().trim().isEmpty
                ? null
                : rawBt.toString().trim());
        final kwRaw = m['kw'] ?? m['keywords'];
        final List<String> base;
        if (kwRaw is List) {
          base = kwRaw
              .map((e) => _normToken('$e'))
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          base = _splitKeywords((kwRaw as String?) ?? '');
        }
        final kws = List<String>.from(base);
        for (final t in _splitHint(m['hint'] ?? m['ai_hint'] ?? m['router_hint'])) {
          if (t.isNotEmpty && !kws.contains(t)) {
            kws.add(t);
          }
        }
        final cid = TelegramChatId.normalizeForApi(id);
        final ui = display.isNotEmpty
            ? display
            : (label.isNotEmpty ? label : cid);
        out.add(
          TelegramPublishChannel(
            chatId: cid,
            label: label.isEmpty ? cid : label,
            keywords: kws,
            uiName: ui,
            botToken: bt,
          ),
        );
      }
      return out;
    } catch (e, st) {
      debugPrint('TelegramPublishChannel.parseJsonList: $e\n$st');
      return const [];
    }
  }

  static List<String> _splitKeywords(String s) {
    if (s.trim().isEmpty) {
      return const [];
    }
    return s
        .split(RegExp(r'[,;|]'))
        .map((e) => _normToken(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static String _normToken(String s) {
    return s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static List<String> _splitHint(dynamic raw) {
    if (raw == null) {
      return const [];
    }
    var s = raw.toString().trim();
    if (s.isEmpty) {
      return const [];
    }
    s = s.replaceAll(RegExp(r'[,;|]'), ' ');
    return s
        .split(RegExp(r'\s+'))
        .map((e) => _normToken(e))
        .where((e) => e.isNotEmpty)
        .toList();
  }
}
