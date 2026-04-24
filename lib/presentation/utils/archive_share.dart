import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/data/publication/vk_wall_client.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/utils/share_target.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<MemeopsShareTarget?> _pickOrInform(
  BuildContext context, {
  required AppLocalizations l10n,
}) async {
  final hasTg = AppEnv.isTelegramPublishConfigured;
  final hasVk = AppEnv.isVkPublishConfigured;
  if (!hasTg && !hasVk) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.shareNoServiceConfigured)),
      );
    }
    return null;
  }
  if (!context.mounted) {
    return null;
  }
  return pickShareTarget(
    context,
    hasTelegram: hasTg,
    hasVk: hasVk,
  );
}

Future<void> _shareTelegram(
  BuildContext context, {
  required File file,
  required MemeArchiveKind kind,
  required String shareText,
  required AppLocalizations l10n,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final publish = createPublicationPort();
  final result = await publish.publishMeme(
    imageUrl: null,
    brief: null,
    localFile: file,
    isVideo: kind == MemeArchiveKind.video,
    captionOverride: shareText,
  );
  if (!context.mounted) {
    return;
  }
  unawaited(
    TelegramPublishedLogRepository.instance
        .recordIfPublished(
          result,
          caption: shareText,
          isVideo: kind == MemeArchiveKind.video,
        )
        .catchError((Object e, StackTrace s) {
          debugPrint('recordIfPublished: $e\n$s');
        }),
  );
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        result.comingSoon
            ? l10n.publicationComingSoon
            : (result.message?.isNotEmpty == true
                ? result.message!
                : l10n.publicationDone),
      ),
    ),
  );
}

Future<void> _shareVk(
  BuildContext context, {
  required File file,
  required MemeArchiveKind kind,
  required String shareText,
  required AppLocalizations l10n,
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  try {
    final r = await VkWallClient.instance.publishFile(
      file,
      isVideo: kind == MemeArchiveKind.video,
      message: shareText,
    );
    final g = int.tryParse(AppEnv.vkGroupId) ?? 0;
    if (g > 0 && r.postId != null) {
      unawaited(
        TelegramPublishedLogRepository.instance
            .recordVkPost(
              vkGroupId: g,
              vkPostId: r.postId,
              caption: shareText,
              isVideo: kind == MemeArchiveKind.video,
            )
            .catchError((Object e, StackTrace s) {
              debugPrint('recordVkPost: $e\n$s');
            }),
      );
    }
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.vkPostDone)),
      );
    }
  } catch (e) {
    debugPrint('VK share: $e');
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('${l10n.vkPostFailed} $e'),
        ),
      );
    }
  }
}

/// Yerel arşiv dosyasını Telegram veya VK’ya gönderir; iki servis açıksa hedef sorulur.
Future<void> shareArchiveFile(
  BuildContext context, {
  required File file,
  required String sourceLabel,
  required MemeArchiveKind kind,
  String? caption,
}) async {
  final l10n = AppLocalizations.of(context);
  final shareText = (caption != null && caption.trim().isNotEmpty)
      ? caption.trim()
      : sourceLabel;

  final exists = await file.exists();
  if (!context.mounted) {
    return;
  }
  if (!exists) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.archiveFileMissing)),
    );
    return;
  }

  final target = await _pickOrInform(context, l10n: l10n);
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  try {
    if (target == MemeopsShareTarget.telegram) {
      await _shareTelegram(
        context,
        file: file,
        kind: kind,
        shareText: shareText,
        l10n: l10n,
      );
    } else {
      await _shareVk(
        context,
        file: file,
        kind: kind,
        shareText: shareText,
        l10n: l10n,
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.archiveShareFailed)),
      );
    }
  }
}

/// Ağdaki .mp4’ü indirip aynı hedef seçim akışıyla kabul eder.
Future<void> shareArchiveVideoFromNetworkUrl(
  BuildContext context, {
  required String url,
  required String sourceLabel,
  String? caption,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final target = await _pickOrInform(context, l10n: l10n);
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  try {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 3));
    if (res.statusCode != 200) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.archiveDownloadFailed(res.statusCode))),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final f = File(
      p.join(
        dir.path,
        'share_${DateTime.now().microsecondsSinceEpoch}.mp4',
      ),
    );
    await f.writeAsBytes(res.bodyBytes);
    if (!context.mounted) {
      return;
    }

    final shareText = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : sourceLabel;

    if (target == MemeopsShareTarget.telegram) {
      await _shareTelegram(
        context,
        file: f,
        kind: MemeArchiveKind.video,
        shareText: shareText,
        l10n: l10n,
      );
    } else {
      await _shareVk(
        context,
        file: f,
        kind: MemeArchiveKind.video,
        shareText: shareText,
        l10n: l10n,
      );
    }
  } catch (e, st) {
    debugPrint('shareArchiveVideoFromNetworkUrl: $e\n$st');
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.archiveShareFailed)),
      );
    }
  }
}

String _extForImageUrl(String url) {
  final l = url.toLowerCase();
  if (l.contains('.png')) {
    return '.png';
  }
  if (l.contains('.webp')) {
    return '.webp';
  }
  if (l.contains('.gif')) {
    return '.gif';
  }
  return '.jpg';
}

/// Ağdaki görseli indirip Telegram / VK akışıyla paylaşır.
Future<void> shareArchiveImageFromNetworkUrl(
  BuildContext context, {
  required String url,
  required String sourceLabel,
  String? caption,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final target = await _pickOrInform(context, l10n: l10n);
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  try {
    final res = await http
        .get(Uri.parse(url))
        .timeout(const Duration(minutes: 3));
    if (res.statusCode != 200) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.archiveDownloadFailed(res.statusCode))),
      );
      return;
    }
    final dir = await getTemporaryDirectory();
    final ext = _extForImageUrl(url);
    final f = File(
      p.join(
        dir.path,
        'share_img_${DateTime.now().microsecondsSinceEpoch}$ext',
      ),
    );
    await f.writeAsBytes(res.bodyBytes);
    if (!context.mounted) {
      return;
    }

    final shareText = (caption != null && caption.trim().isNotEmpty)
        ? caption.trim()
        : sourceLabel;

    if (target == MemeopsShareTarget.telegram) {
      await _shareTelegram(
        context,
        file: f,
        kind: MemeArchiveKind.image,
        shareText: shareText,
        l10n: l10n,
      );
    } else {
      await _shareVk(
        context,
        file: f,
        kind: MemeArchiveKind.image,
        shareText: shareText,
        l10n: l10n,
      );
    }
  } catch (e, st) {
    debugPrint('shareArchiveImageFromNetworkUrl: $e\n$st');
    if (context.mounted) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.archiveShareFailed)),
      );
    }
  }
}
