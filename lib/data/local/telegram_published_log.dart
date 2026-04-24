import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _kPlatformTelegram = 'telegram';
const _kPlatformVk = 'vk';

/// Kanal / VK paylaşımı; analiz sekmesinde listelenir.
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
  });

  final String id;
  final DateTime publishedAt;
  final int? messageId;
  final String? chatId;
  final int? views;
  final String? caption;
  final bool isVideo;
  final String platform;
  final int? vkGroupId;
  final int? vkPostId;
  final int? likesCount;
  final int? repostsCount;

  bool get isTelegram => platform == _kPlatformTelegram;
  bool get isVk => platform == _kPlatformVk;

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
    );
  }

  TelegramPublishedEntry copyWith({
    int? views,
    int? likesCount,
    int? repostsCount,
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
      ),
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.recordVkPost: $e\n$st');
    }
    onChanged.value++;
  }

  /// Detay ekranında VK metriklerini yenilemek için.
  Future<void> updateEntry(
    String id, {
    int? views,
    int? likesCount,
    int? repostsCount,
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
    );
    try {
      await _persist();
    } catch (e, st) {
      debugPrint('TelegramPublishedLogRepository.updateEntry: $e\n$st');
    }
    onChanged.value++;
  }
}
