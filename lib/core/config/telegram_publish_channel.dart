import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Tek bir Telegram yayın hedefi (aynı bot token; farklı [chatId]).
@immutable
class TelegramPublishChannel {
  const TelegramPublishChannel({
    required this.chatId,
    required this.label,
    required this.keywords,
  });

  final String chatId;
  final String label;
  final List<String> keywords;

  /// [.env] içindeki `TELEGRAM_PUBLISH_CHANNELS_JSON` satırını ayrıştırır.
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
        final id = (m['id'] ?? m['chat_id'] ?? '') as String? ?? '';
        if (id.trim().isEmpty) {
          continue;
        }
        final label = (m['label'] ?? m['name'] ?? '') as String? ?? '';
        final kwRaw = m['kw'] ?? m['keywords'];
        final List<String> kws;
        if (kwRaw is List) {
          kws = kwRaw
              .map((e) => _normToken('$e'))
              .where((e) => e.isNotEmpty)
              .toList();
        } else {
          kws = _splitKeywords((kwRaw as String?) ?? '');
        }
        out.add(
          TelegramPublishChannel(
            chatId: id.trim(),
            label: label.trim().isEmpty ? id.trim() : label.trim(),
            keywords: kws,
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
}
