/// Telegram Bot API [chat_id] dizesi (.env kopya hatalarına karşı).
class TelegramChatId {
  const TelegramChatId._();

  static String normalizeForApi(String raw) {
    var s = raw.replaceAll('\uFEFF', '').trim();
    if (s.isEmpty) {
      return s;
    }
    final at = s.indexOf('@');
    if (at >= 0) {
      final uname = s
          .substring(at + 1)
          .replaceAll('@', '')
          .replaceAll('\u0000', '')
          .trim();
      if (uname.isEmpty) {
        return s;
      }
      return '@${uname.toLowerCase()}';
    }
    s = s.replaceAll(
      RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2015\u2212\ufe58\ufe63\uff0d]'),
      '-',
    );
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s;
  }
}
