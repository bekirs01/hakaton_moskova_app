/// POST `/api/v1/telegram/channel-post-stats` yanıtı.
class TelegramChannelPostStats {
  const TelegramChannelPostStats({
    required this.views,
    required this.forwards,
    required this.reactions,
  });

  final int views;
  final int forwards;
  final List<TelegramPostReactionRow> reactions;

  factory TelegramChannelPostStats.fromMap(Map<String, dynamic> m) {
    final raw = m['reactions'] as List<dynamic>? ?? const [];
    return TelegramChannelPostStats(
      views: (m['views'] as num?)?.toInt() ?? 0,
      forwards: (m['forwards'] as num?)?.toInt() ?? 0,
      reactions: raw
          .map(
            (e) => TelegramPostReactionRow.fromMap(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}

class TelegramPostReactionRow {
  const TelegramPostReactionRow({
    required this.label,
    required this.count,
    required this.kind,
  });

  final String label;
  final int count;
  final String kind;

  factory TelegramPostReactionRow.fromMap(Map<String, dynamic> m) {
    return TelegramPostReactionRow(
      label: (m['label'] as String? ?? '').trim(),
      count: (m['count'] as num?)?.toInt() ?? 0,
      kind: (m['kind'] as String? ?? 'emoji').trim(),
    );
  }
}
