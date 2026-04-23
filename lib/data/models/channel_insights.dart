class ChannelInsights {
  const ChannelInsights({
    required this.channelUrl,
    required this.mainTopic,
    required this.recurringThemes,
    required this.tone,
    required this.mediaTypes,
    required this.memeableAngles,
  });

  final String channelUrl;
  final String mainTopic;
  final List<String> recurringThemes;
  final String tone;
  final List<String> mediaTypes;
  final List<String> memeableAngles;

  /// Human-readable block for [profession.description] / [futureContext] to feed the existing brief generator.
  String toProfessionContext() {
    final lines = <String>[
      'Channel: $channelUrl',
      'Main topic: $mainTopic',
      'Recurring themes: ${recurringThemes.join(", ")}',
      'Tone: $tone',
      'Media: ${mediaTypes.join(", ")}',
      'Meme angles: ${memeableAngles.join(" | ")}',
    ];
    return lines.join('\n');
  }

  List<String> summaryLines() {
    return [
      mainTopic,
      'Themes: ${recurringThemes.join(", ")}',
      'Tone: $tone',
    ];
  }

  static ChannelInsights fromMap(Map<String, dynamic> m) {
    return ChannelInsights(
      channelUrl: m['channelUrl'] as String? ?? '',
      mainTopic: m['mainTopic'] as String? ?? '',
      recurringThemes: (m['recurringThemes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tone: m['tone'] as String? ?? '',
      mediaTypes:
          (m['mediaTypes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      memeableAngles:
          (m['memeableAngles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
    );
  }
}
