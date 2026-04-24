import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _kPlatformTelegram = 'telegram';
const _kPlatformVk = 'vk';
const _kPlatformDzen = 'dzen';

/// Kanal / VK paylaşımı; analiz sekmesinde eşleştirme için [localArchiveId] / [supabaseVersionId].
class TelegramPublishedEntry {
  const TelegramPublishedEntry({
    required this.id,
    required this.publishedAt,
    this.messageId,
    this.chatId,
    this.views,
    this.caption,
    this.isVideo = false,
    this.platform = _kPlatformTelegram,
    this.vkGroupId,
    this.vkPostId,
    this.likesCount,
    this.repostsCount,
    this.localArchiveId,
    this.supabaseVersionId,
    this.telegramForwards,
    this.telegramReactionsJson,
    this.telegramChannelMemberCount,
    this.telegramRepliesCount,
    this.vkGroupMemberCount,
    this.vkCommentsCount,
    this.telegramMessageDate,
  });

  final String id;
  final DateTime publishedAt;
  final int? messageId;
  final String? chatId;
  final int? views;
  final int? telegramForwards;
  final String? caption;
  final bool isVideo;
  final String platform;
  final int? vkGroupId;
  final int? vkPostId;
  final int? likesCount;
  final int? repostsCount;
  final String? localArchiveId;
  final String? supabaseVersionId;
  /// JSON: `[{"label":"👍","count":2,"kind":"emoji"}, ...]`
  final String? telegramReactionsJson;
  final int? telegramChannelMemberCount;
  final int? telegramRepliesCount;
  final int? vkGroupMemberCount;
  final int? vkCommentsCount;
  /// API’den gelen gönderi tarihi (ISO), Telegram.
  final String? telegramMessageDate;

  bool get isTelegram => platform == _kPlatformTelegram;
  bool get isVk => platform == _kPlatformVk;
  bool get isDzen => platform == _kPlatformDzen;

  Map<String, dynamic> toJson() => {
        'id': id,
        'publishedAt': publishedAt.toIso8601String(),
        'messageId': messageId,
        'chatId': chatId,
        'views': views,
        'caption': caption,
        'isVideo': isVideo,
        'platform': platform,
        'vkGroupId': vkGroupId,
        'vkPostId': vkPostId,
        'likesCount': likesCount,
        'repostsCount': repostsCount,
        'localArchiveId': localArchiveId,
        'supabaseVersionId': supabaseVersionId,
        'telegramForwards': telegramForwards,
        'telegramReactionsJson': telegramReactionsJson,
        'telegramChannelMemberCount': telegramChannelMemberCount,
        'telegramRepliesCount': telegramRepliesCount,
        'vkGroupMemberCount': vkGroupMemberCount,
        'vkCommentsCount': vkCommentsCount,
        'telegramMessageDate': telegramMessageDate,
      };

  factory TelegramPublishedEntry.fromJson(Map<String, dynamic> j) {
    final plat = (j['platform'] as String?)?.trim();
    return TelegramPublishedEntry(
      id: j['id'] as String,
      publishedAt: DateTime.parse(j['publishedAt'] as String),
      messageId: (j['messageId'] as num?)?.toInt(),
      chatId: j['chatId'] as String?,
      views: (j['views'] as num?)?.toInt(),
      caption: j['caption'] as String?,
      isVideo: j['isVideo'] as bool? ?? false,
      platform: (plat == null || plat.isEmpty) ? _kPlatformTelegram : plat,
      vkGroupId: (j['vkGroupId'] as num?)?.toInt(),
      vkPostId: (j['vkPostId'] as num?)?.toInt(),
      likesCount: (j['likesCount'] as num?)?.toInt(),
      repostsCount: (j['repostsCount'] as num?)?.toInt(),
      localArchiveId: j['localArchiveId'] as String?,
      supabaseVersionId: j['supabaseVersionId'] as String?,
      telegramForwards: (j['telegramForwards'] as num?)?.toInt(),
      telegramReactionsJson: j['telegramReactionsJson'] as String?,
      telegramChannelMemberCount:
          (j['telegramChannelMemberCount'] as num?)?.toInt(),
      telegramRepliesCount: (j['telegramRepliesCount'] as num?)?.toInt(),
      vkGroupMemberCount: (j['vkGroupMemberCount'] as num?)?.toInt(),
      vkCommentsCount: (j['vkCommentsCount'] as num?)?.toInt(),
      telegramMessageDate: j['telegramMessageDate'] as String?,
    );
  }

  TelegramPublishedEntry copyWith({
    int? views,
    int? likesCount,
    int? repostsCount,
    int? telegramForwards,
    String? telegramReactionsJson,
    int? telegramChannelMemberCount,
    int? telegramRepliesCount,
    int? vkGroupMemberCount,
    int? vkCommentsCount,
    String? telegramMessageDate,
  }) {
    return TelegramPublishedEntry(
      id: id,
      publishedAt: publishedAt,
      messageId: messageId,
      chatId: chatId,
      views: views ?? this.views,
      caption: caption,
      isVideo: isVideo,
      platform: platform,
      vkGroupId: vkGroupId,
      vkPostId: vkPostId,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      localArchiveId: localArchiveId,
      supabaseVersionId: supabaseVersionId,
      telegramForwards: telegramForwards ?? this.telegramForwards,
      telegramReactionsJson: telegramReactionsJson ?? this.telegramReactionsJson,
      telegramChannelMemberCount:
          telegramChannelMemberCount ?? this.telegramChannelMemberCount,
      telegramRepliesCount: telegramRepliesCount ?? this.telegramRepliesCount,
      vkGroupMemberCount: vkGroupMemberCount ?? this.vkGroupMemberCount,
      vkCommentsCount: vkCommentsCount ?? this.vkCommentsCount,
      telegramMessageDate: telegramMessageDate ?? this.telegramMessageDate,
    );
  }
}

/// Başarılı yanıtları cihazda listeler; [PublicationResult] ve VK ile dolar.
class TelegramPublishedLogRepository {
  TelegramPublishedLogRepository._();
  static final instance = TelegramPublishedLogRepository._();

  final ValueNotifier<int> onChanged = ValueNotifier<int>(0);
  final List<TelegramPublishedEntry> _items = [];
  bool _loaded = false;

  List<TelegramPublishedEntry> get items =>
      List<TelegramPublishedEntry>.unmodifiable(_items);

  /// Arşiv satırı ile paylaşım kaydını eşleştirir.
  TelegramPublishedEntry? findForArchiveItem({
    String? localArchiveId,
    String? supabaseVersionId,
  }) {
    for (final e in _items) {
      if (localArchiveId != null &&
          e.localArchiveId != null &&
          e.localArchiveId == localArchiveId) {
        return e;
      }
      if (supabaseVersionId != null &&
          e.supabaseVersionId != null &&
          e.supabaseVersionId == supabaseVersionId) {
        return e;
      }
    }
    return null;
  }

  /// Id eşleşmediyse: aynı tür, altyazı ve zaman yakınlığı (eski paylaşımlar için).
  TelegramPublishedEntry? findFuzzyForArchiveItem({
    MemeArchiveEntry? local,
    SupabaseMemeAssetEntry? cloud,
  }) {
    final direct = findForArchiveItem(
      localArchiveId: local?.id,
      supabaseVersionId: cloud?.id,
    );
    if (direct != null) {
      return direct;
    }
    final l = local;
    final isVid = l != null
        ? l.kind == MemeArchiveKind.video
        : cloud!.isVideo;
    final t0 = l != null ? l.createdAt : cloud!.createdAt;
    var cap = l != null
        ? (l.caption ?? '').trim()
        : (cloud!.briefLine ?? '').trim();

    TelegramPublishedEntry? best;
    for (final e in _items) {
      if (e.isVideo != isVid) {
        continue;
      }
      final ec = (e.caption ?? '').trim();
      if (cap.isNotEmpty) {
        if (ec != cap) {
          continue;
        }
        if (e.publishedAt.difference(t0).inHours.abs() > 24 * 7) {
          continue;
        }
      } else {
        if (e.publishedAt.difference(t0).inSeconds.abs() > 600) {
          continue;
        }
      }
      if (best == null || e.publishedAt.isAfter(best.publishedAt)) {
        best = e;
      }
    }
    return best;
  }

  Future<File> _file() async {
    final doc = await getApplicationDocumentsDirectory();
    return File(p.join(doc.path, 'telegram_published_log.json'));
  }

  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    try {
      final f = await _file();
      if (await f.exists()) {
        final raw = await f.readAsString();
        final d = jsonDecode(raw);
        if (d is List) {
          for (final e in d) {
            if (e is! Map) {
              continue;
            }
            try {
              _items.add(
                TelegramPublishedEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              );
            } catch (err, st) {
              debugPrint('TelegramPublishedLogRepository: skip: $err\n$st');
            }
          }
          _items.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
        }
      }
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.ensureLoaded: $e\n$st');
    }
    _loaded = true;
    onChanged.value++;
  }

  Future<void> _persist() async {
    final f = await _file();
    final enc = jsonEncode(_items.map((e) => e.toJson()).toList());
    await f.writeAsString(enc);
  }

  int _ix(String id) => _items.indexWhere((e) => e.id == id);

  /// Başarılı kanal paylaşımı sonrası (stub değil) çağır.
  Future<void> recordIfPublished(
    PublicationResult r, {
    String? caption,
    bool isVideo = false,
    String? localArchiveId,
    String? supabaseVersionId,
  }) async {
    if (r.comingSoon) {
      return;
    }
    if (r.message != null && r.message!.trim().isNotEmpty) {
      return;
    }
    final mid = r.telegramMessageId;
    if (mid == null) {
      return;
    }
    await ensureLoaded();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _items.insert(
      0,
      TelegramPublishedEntry(
        id: id,
        publishedAt: DateTime.now(),
        messageId: mid,
        chatId: r.telegramChatId,
        views: r.telegramViews,
        caption: caption,
        isVideo: isVideo,
        platform: _kPlatformTelegram,
        localArchiveId: localArchiveId,
        supabaseVersionId: supabaseVersionId,
        telegramForwards: r.telegramForwards,
      ),
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.recordIfPublished: $e\n$st');
    }
    onChanged.value++;
  }

  /// VK [wall.post] sonrası.
  Future<void> recordVkPost({
    required int vkGroupId,
    required int? vkPostId,
    String? caption,
    bool isVideo = false,
    String? localArchiveId,
    String? supabaseVersionId,
  }) async {
    if (vkPostId == null) {
      return;
    }
    await ensureLoaded();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _items.insert(
      0,
      TelegramPublishedEntry(
        id: id,
        publishedAt: DateTime.now(),
        caption: caption,
        isVideo: isVideo,
        platform: _kPlatformVk,
        vkGroupId: vkGroupId,
        vkPostId: vkPostId,
        localArchiveId: localArchiveId,
        supabaseVersionId: supabaseVersionId,
      ),
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.recordVkPost: $e\n$st');
    }
    onChanged.value++;
  }

  /// Dzen (simüle) — analizde platform sekmesi için yalnızca kayıt.
  Future<void> recordDzenSimulated({
    String? caption,
    bool isVideo = false,
    String? localArchiveId,
    String? supabaseVersionId,
  }) async {
    await ensureLoaded();
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    _items.insert(
      0,
      TelegramPublishedEntry(
        id: id,
        publishedAt: DateTime.now(),
        caption: caption,
        isVideo: isVideo,
        platform: _kPlatformDzen,
        localArchiveId: localArchiveId,
        supabaseVersionId: supabaseVersionId,
      ),
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.recordDzenSimulated: $e\n$st');
    }
    onChanged.value++;
  }

  /// Detay ekranında VK / Telethon ile çekilen metrikleri kaydetmek için.
  Future<void> updateEntry(
    String id, {
    int? views,
    int? likesCount,
    int? repostsCount,
    int? telegramForwards,
    String? telegramReactionsJson,
    int? telegramChannelMemberCount,
    int? telegramRepliesCount,
    int? vkGroupMemberCount,
    int? vkCommentsCount,
    String? telegramMessageDate,
  }) async {
    await ensureLoaded();
    final i = _ix(id);
    if (i < 0) {
      return;
    }
    _items[i] = _items[i].copyWith(
      views: views,
      likesCount: likesCount,
      repostsCount: repostsCount,
      telegramForwards: telegramForwards,
      telegramReactionsJson: telegramReactionsJson,
      telegramChannelMemberCount: telegramChannelMemberCount,
      telegramRepliesCount: telegramRepliesCount,
      vkGroupMemberCount: vkGroupMemberCount,
      vkCommentsCount: vkCommentsCount,
      telegramMessageDate: telegramMessageDate,
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.updateEntry: $e\n$st');
    }
    onChanged.value++;
  }
}
