import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';

Future<void> shareArchiveFile(
  BuildContext context, {
  required File file,
  required String sourceLabel,
  String? caption,
}) async {
  final l10n = AppLocalizations.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final render = context.findRenderObject();
  final box = render is RenderBox ? render : null;
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
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: sourceLabel,
        text: shareText,
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.archiveShareFailed)),
    );
  }
}
