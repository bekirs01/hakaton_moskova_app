import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_channel_router.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/core/ui/memeops_messenger.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/utils/share_target.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_archive_publish_sheet.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

AppLocalizations _l10n(BuildContext? context) {
  if (context != null) {
    return AppLocalizations.of(context);
  }
  return lookupAppLocalizations(AppLocaleController.instance.locale);
}

void _snackSafe(BuildContext? context, String text) {
  ScaffoldMessengerState? m;
  if (context != null && context.mounted) {
    m = ScaffoldMessenger.maybeOf(context);
  }
  m ??= MemeopsMessenger.scaffoldMessengerKey.currentState;
  m?.showSnackBar(SnackBar(content: Text(text)));
}

/// Kök [Navigator] + `useRootNavigator` ile açılır; iç içe rotada «paylaş menüsü açılamadı» riskini azaltır.
Future<MemeopsShareTarget?> _pickMemeopsShareTarget(BuildContext context) {
  return showMemeopsArchivePublishSheet(context);
}

Future<void> _shareTelegram({
  required File file,
  required MemeArchiveKind kind,
  required String shareText,
  required AppLocalizations l10n,
  String? localArchiveId,
  String? supabaseVersionId,
  String? telegramChatId,
}) async {
  final publish = createPublicationPort();
  final result = await publish.publishMeme(
    imageUrl: null,
    brief: null,
    localFile: file,
    isVideo: kind == MemeArchiveKind.video,
    captionOverride: shareText,
    telegramChatId: telegramChatId,
  );
  unawaited(
    TelegramPublishedLogRepository.instance
        .recordIfPublished(
          result,
          caption: shareText,
          isVideo: kind == MemeArchiveKind.video,
          localArchiveId: localArchiveId,
          supabaseVersionId: supabaseVersionId,
        )
        .catchError((Object e, StackTrace s) {
          debugPrint('recordIfPublished: $e\n$s');
        }),
  );
  final msg = result.comingSoon
      ? l10n.publicationComingSoon
      : (result.message?.isNotEmpty == true
          ? result.message!
          : l10n.publicationDone);
  _snackSafe(null, msg);
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

String? _telegramChatIdForQuickShare(String shareText, String sourceLabel) {
  final d = AppEnv.telegramPublishDestinations;
  if (d.isEmpty) {
    return null;
  }
  if (d.length == 1) {
    return d.first.chatId;
  }
  final blob = '$shareText $sourceLabel';
  final i = TelegramChannelRouter.recommendIndex(d, blob);
  return d[i].chatId;
}

/// Tek giriş noktası: yerel dosya ve/veya ağ URL’si ile Telegram, VK; Dzen sadece simüle.
Future<void> executeArchivePublish(
  BuildContext? context, {
  required MemeopsShareTarget target,
  required MemeArchiveKind kind,
  required String shareText,
  required String sourceLabel,
  File? localFile,
  String? networkUrl,
  String? localArchiveId,
  String? supabaseVersionId,
  String? telegramChatId,
}) async {
  final l10n = _l10n(context);
  if (target == MemeopsShareTarget.dzen) {
    _snackSafe(context, l10n.dzenPublishSimulated);
    unawaited(
      TelegramPublishedLogRepository.instance.recordDzenSimulated(
        caption: shareText.trim().isNotEmpty ? shareText.trim() : sourceLabel,
        isVideo: kind == MemeArchiveKind.video,
        localArchiveId: localArchiveId,
        supabaseVersionId: supabaseVersionId,
      ),
    );
    return;
  }
  // Yalnızca Telegram gerçek gönderim; VK arayüzde «paylaşıldı» (ağ yok).
  if (target == MemeopsShareTarget.vk) {
    _snackSafe(context, l10n.vkPostDone);
    return;
  }
  assert(
    localFile != null || (networkUrl != null && networkUrl.trim().isNotEmpty),
    'Yerel dosya veya networkUrl gerekli',
  );
  final text = shareText.trim().isNotEmpty ? shareText.trim() : sourceLabel;

  late final File file;
  if (localFile != null) {
    if (!await localFile.exists()) {
      _snackSafe(null, l10n.archiveFileMissing);
      return;
    }
    file = localFile;
  } else {
    try {
      final res = await http
          .get(Uri.parse(networkUrl!.trim()))
          .timeout(const Duration(minutes: 3));
      if (res.statusCode != 200) {
        _snackSafe(null, l10n.archiveDownloadFailed(res.statusCode));
        return;
      }
      final dir = await getTemporaryDirectory();
      final ext = kind == MemeArchiveKind.video
          ? '.mp4'
          : _extForImageUrl(networkUrl);
      file = File(
        p.join(
          dir.path,
          'publish_${DateTime.now().microsecondsSinceEpoch}$ext',
        ),
      );
      await file.writeAsBytes(res.bodyBytes);
    } catch (e, st) {
      debugPrint('executeArchivePublish download: $e\n$st');
      _snackSafe(null, l10n.archiveShareFailedWithError(e.toString()));
      return;
    }
  }

  try {
    if (target == MemeopsShareTarget.telegram) {
      final tid = telegramChatId ??
          _telegramChatIdForQuickShare(text, sourceLabel);
      await _shareTelegram(
        file: file,
        kind: kind,
        shareText: text,
        l10n: l10n,
        localArchiveId: localArchiveId,
        supabaseVersionId: supabaseVersionId,
        telegramChatId: tid,
      );
    }
  } catch (e, st) {
    debugPrint('executeArchivePublish: $e\n$st');
    _snackSafe(null, l10n.archiveShareFailedWithError(e.toString()));
  }
}

/// Yerel arşiv dosyasını Telegram veya VK’ya gönderir; iki servis açıksa hedef sorulur.
Future<void> shareArchiveFile(
  BuildContext context, {
  required File file,
  required String sourceLabel,
  required MemeArchiveKind kind,
  String? caption,
  String? localArchiveId,
  String? supabaseVersionId,
}) async {
  final l10n = _l10n(context);
  final shareText = (caption != null && caption.trim().isNotEmpty)
      ? caption.trim()
      : sourceLabel;

  final exists = await file.exists();
  if (!context.mounted) {
    return;
  }
  if (!exists) {
    _snackSafe(context, l10n.archiveFileMissing);
    return;
  }

  MemeopsShareTarget? target;
  try {
    target = await _pickMemeopsShareTarget(context);
  } catch (e, st) {
    debugPrint('Arşiv hedef seçimi: $e\n$st');
    if (context.mounted) {
      _snackSafe(context, l10n.archiveShareFailedWithError(e.toString()));
    }
    return;
  }
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  await executeArchivePublish(
    context,
    target: target,
    kind: kind,
    shareText: shareText,
    sourceLabel: sourceLabel,
    localFile: file,
    localArchiveId: localArchiveId,
    supabaseVersionId: supabaseVersionId,
  );
}

/// Ağdaki .mp4’ü indirip aynı hedef seçim akışıyla kabul eder.
Future<void> shareArchiveVideoFromNetworkUrl(
  BuildContext context, {
  required String url,
  required String sourceLabel,
  String? caption,
  String? supabaseVersionId,
}) async {
  final l10n = _l10n(context);
  MemeopsShareTarget? target;
  try {
    target = await _pickMemeopsShareTarget(context);
  } catch (e, st) {
    debugPrint('Arşiv hedef seçimi (video URL): $e\n$st');
    if (context.mounted) {
      _snackSafe(context, l10n.archiveShareFailedWithError(e.toString()));
    }
    return;
  }
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  final shareText = (caption != null && caption.trim().isNotEmpty)
      ? caption.trim()
      : sourceLabel;

  await executeArchivePublish(
    context,
    target: target,
    kind: MemeArchiveKind.video,
    shareText: shareText,
    sourceLabel: sourceLabel,
    networkUrl: url,
    supabaseVersionId: supabaseVersionId,
  );
}

/// Ağdaki görseli indirip Telegram / VK akışıyla paylaşır.
Future<void> shareArchiveImageFromNetworkUrl(
  BuildContext context, {
  required String url,
  required String sourceLabel,
  String? caption,
  String? supabaseVersionId,
}) async {
  final l10n = _l10n(context);
  MemeopsShareTarget? target;
  try {
    target = await _pickMemeopsShareTarget(context);
  } catch (e, st) {
    debugPrint('Arşiv hedef seçimi (görsel URL): $e\n$st');
    if (context.mounted) {
      _snackSafe(context, l10n.archiveShareFailedWithError(e.toString()));
    }
    return;
  }
  if (target == null) {
    return;
  }
  if (!context.mounted) {
    return;
  }

  final shareText = (caption != null && caption.trim().isNotEmpty)
      ? caption.trim()
      : sourceLabel;

  await executeArchivePublish(
    context,
    target: target,
    kind: MemeArchiveKind.image,
    shareText: shareText,
    sourceLabel: sourceLabel,
    networkUrl: url,
    supabaseVersionId: supabaseVersionId,
  );
}
