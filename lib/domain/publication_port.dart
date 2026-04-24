import 'dart:io';

import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';

/// Future: push saved memes to connected channels. Stub only.
abstract class PublicationPort {
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
    File? localFile,
    bool isVideo = false,
    String? captionOverride,
  });
}

class PublicationResult {
  const PublicationResult({
    required this.comingSoon,
    this.message,
    this.telegramMessageId,
    this.telegramChatId,
    this.telegramViews,
  });

  final bool comingSoon;
  final String? message;

  /// Telegram [sendPhoto] / [sendVideo] yanıtı (kanal postu) — analitik için.
  final int? telegramMessageId;
  final String? telegramChatId;
  final int? telegramViews;
}

class StubPublicationPort implements PublicationPort {
  @override
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
    File? localFile,
    bool isVideo = false,
    String? captionOverride,
  }) async {
    return const PublicationResult(comingSoon: true);
  }
}
