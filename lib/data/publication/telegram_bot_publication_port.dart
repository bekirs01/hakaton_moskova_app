import 'dart:convert';
import 'dart:io';

import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:http/http.dart' as http;

/// Telegram Bot API ile kanala görsel gönderir (`sendPhoto`).
/// Bot, hedef kanalda **yönetici** olmalı ve mesaj gönderme yetkisi olmalı.
class TelegramBotPublicationPort implements PublicationPort {
  TelegramBotPublicationPort();

  static const _timeout = Duration(seconds: 45);

  @override
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
    File? localFile,
    bool isVideo = false,
    String? captionOverride,
  }) async {
    if (!AppEnv.isTelegramPublishConfigured) {
      return const PublicationResult(comingSoon: true);
    }
    final caption = (captionOverride?.trim().isNotEmpty == true
            ? captionOverride!.trim()
            : (brief?.displayLine ?? '').trim());
    if (localFile != null) {
      return _publishLocalFile(
        localFile,
        isVideo: isVideo,
        caption: caption,
      );
    }
    final photo = imageUrl?.trim() ?? '';
    if (photo.isEmpty) {
      return const PublicationResult(
        comingSoon: false,
        message: 'No image URL to publish.',
      );
    }
    final token = AppEnv.telegramPublishBotToken;
    final chatId = AppEnv.telegramPublishChannel;
    final uri = Uri.parse('https://api.telegram.org/bot$token/sendPhoto');
    final body = <String, String>{
      'chat_id': chatId,
      'photo': photo,
      if (caption.isNotEmpty)
        'caption': caption.length > 1024 ? caption.substring(0, 1024) : caption,
    };
    try {
      final res = await http.post(uri, body: body).timeout(_timeout);
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      final ok = decoded?['ok'] == true;
      if (ok) {
        return const PublicationResult(comingSoon: false);
      }
      final desc =
          decoded?['description'] as String? ?? 'HTTP ${res.statusCode}: ${res.body}';
      return PublicationResult(comingSoon: false, message: desc);
    } catch (e) {
      return PublicationResult(comingSoon: false, message: e.toString());
    }
  }

  Future<PublicationResult> _publishLocalFile(
    File file, {
    required bool isVideo,
    required String caption,
  }) async {
    final token = AppEnv.telegramPublishBotToken;
    final chatId = AppEnv.telegramPublishChannel;
    final method = isVideo ? 'sendVideo' : 'sendPhoto';
    final field = isVideo ? 'video' : 'photo';
    final uri = Uri.parse('https://api.telegram.org/bot$token/$method');
    try {
      final request = http.MultipartRequest('POST', uri)
        ..fields['chat_id'] = chatId;
      if (caption.isNotEmpty) {
        request.fields['caption'] =
            caption.length > 1024 ? caption.substring(0, 1024) : caption;
      }
      request.files.add(await http.MultipartFile.fromPath(field, file.path));
      final streamed = await request.send().timeout(_timeout);
      final res = await http.Response.fromStream(streamed);
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(res.body) as Map<String, dynamic>?;
      } catch (_) {}
      final ok = decoded?['ok'] == true;
      if (ok) {
        return const PublicationResult(comingSoon: false);
      }
      final desc =
          decoded?['description'] as String? ?? 'HTTP ${res.statusCode}: ${res.body}';
      return PublicationResult(comingSoon: false, message: desc);
    } catch (e) {
      return PublicationResult(comingSoon: false, message: e.toString());
    }
  }
}
