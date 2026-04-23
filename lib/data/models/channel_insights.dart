class ChannelInsights {
  const ChannelInsights({
    required this.channelUrl,
    required this.mainTopic,
    required this.recurringThemes,
    required this.tone,
    required this.mediaTypes,
    required this.memeableAngles,
    this.channelTitle,
    this.toneProfile,
    this.postTypes = const [],
    this.mediaInsights = const [],
    this.recentHighlights = const [],
    this.analysisSource,
  });

  final String channelUrl;
  final String mainTopic;
  final List<String> recurringThemes;
  final String tone;
  final List<String> mediaTypes;
  final List<String> memeableAngles;

  /// Telegram channel title when available (live analysis).
  final String? channelTitle;
  final String? toneProfile;
  final List<String> postTypes;
  final List<String> mediaInsights;
  final List<String> recentHighlights;

  /// `telethon_live` | `offline_stub` | null (legacy servers).
  final String? analysisSource;

  bool get isOfflineStub => analysisSource == 'offline_stub';
  bool get isTelethonLive => analysisSource == 'telethon_live';

  /// JSON for POST `/api/v1/telegram/meme-variants` (local Python).
  Map<String, dynamic> toServerJson() {
    return {
      'channelUrl': channelUrl,
      'channelTitle': channelTitle ?? '',
      'mainTopic': mainTopic,
      'recurringThemes': recurringThemes,
      'tone': tone,
      'toneProfile': toneProfile ?? '',
      'mediaTypes': mediaTypes,
      'mediaInsights': mediaInsights,
      'postTypes': postTypes,
      'recentHighlights': recentHighlights,
      'memeableAngles': memeableAngles,
      'analysisSource': analysisSource ?? '',
    };
  }

  /// Human-readable block for profession / brief generators.
  String toProfessionContext() {
    final lines = <String>[
      'Channel: $channelUrl',
      if (channelTitle != null && channelTitle!.isNotEmpty) 'Title: $channelTitle',
      'Main topic: $mainTopic',
      'Recurring themes: ${recurringThemes.join(", ")}',
      'Tone: $tone',
      if (toneProfile != null && toneProfile!.isNotEmpty) 'Tone profile: $toneProfile',
      'Post mix: ${postTypes.join("; ")}',
      'Media: ${mediaTypes.join(", ")}',
      if (mediaInsights.isNotEmpty) 'Media notes: ${mediaInsights.join(" | ")}',
      if (recentHighlights.isNotEmpty)
        'Recent samples: ${recentHighlights.join(" · ")}',
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
    List<String> ls(String k) =>
        (m[k] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [];

    return ChannelInsights(
      channelUrl: m['channelUrl'] as String? ?? '',
      mainTopic: m['mainTopic'] as String? ?? '',
      recurringThemes: ls('recurringThemes'),
      tone: m['tone'] as String? ?? '',
      mediaTypes: ls('mediaTypes'),
      memeableAngles: ls('memeableAngles'),
      channelTitle: m['channelTitle'] as String?,
      toneProfile: m['toneProfile'] as String?,
      postTypes: ls('postTypes'),
      mediaInsights: ls('mediaInsights'),
      recentHighlights: ls('recentHighlights'),
      analysisSource: m['analysisSource'] as String?,
    );
  }
}
