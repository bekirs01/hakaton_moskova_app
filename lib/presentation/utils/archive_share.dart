import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';

Future<void> shareArchiveFile(
  BuildContext context, {
  required File file,
  required String sourceLabel,
  required MemeArchiveKind kind,
  String? caption,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final publish = createPublicationPort();
  final shareText = (caption != null && caption.trim().isNotEmpty)
      ? caption.trim()
      : sourceLabel;

  if (!await file.exists()) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.archiveFileMissing)),
    );
    return;
  }

  try {
    final result = await publish.publishMeme(
      imageUrl: null,
      brief: null,
      localFile: file,
      isVideo: kind == MemeArchiveKind.video,
      captionOverride: shareText,
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
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.archiveShareFailed)),
    );
  }
}
