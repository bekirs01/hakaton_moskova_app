import 'package:hakaton_moskova_app/core/config/telegram_publish_channel.dart';

/// Gönderi metnine göre en uygun Telegram kanalını anahtar kelime skoruyla seçer.
class TelegramChannelRouter {
  TelegramChannelRouter._();

  /// Skoru en yüksek kanalın dizini. Liste boşsa 0; tek elemanlıysa 0.
  static int recommendIndex(
    List<TelegramPublishChannel> channels,
    String contentBlob,
  ) {
    if (channels.isEmpty) {
      return 0;
    }
    if (channels.length == 1) {
      return 0;
    }
    final blob = _normalize(contentBlob);
    var bestI = 0;
    var bestScore = -1;
    for (var i = 0; i < channels.length; i++) {
      final s = _score(blob, channels[i].keywords);
      if (s > bestScore) {
        bestScore = s;
        bestI = i;
      }
    }
    if (bestScore <= 0) {
      return 0;
    }
    return bestI;
  }

  static String _normalize(String raw) {
    var s = raw.toLowerCase().trim().replaceAll('ё', 'е');
    s = s.replaceAll(
      RegExp(r'[^a-z0-9\s\u0400-\u04FFığüşöçıİĞÜŞÖÇ]'),
      ' ',
    );
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static int _score(String blob, List<String> keywords) {
    if (keywords.isEmpty) {
      return 0;
    }
    var score = 0;
    for (final kw in keywords) {
      if (kw.isEmpty) {
        continue;
      }
      if (blob.contains(kw)) {
        score += kw.length >= 4 ? 3 : 2;
      }
    }
    return score;
  }
}
