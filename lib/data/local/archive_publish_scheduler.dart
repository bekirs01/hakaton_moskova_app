import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/core/ui/memeops_messenger.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/utils/archive_share.dart';
import 'package:hakaton_moskova_app/presentation/utils/share_target.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arşiv gönderimini uygulama açıkken yerel sıraya alır; süre gelince [executeArchivePublish] çalışır.
/// Uygulama tamamen kapalıyken gönderim garanti edilmez.
class ArchivePublishScheduler {
  ArchivePublishScheduler._();
  static final instance = ArchivePublishScheduler._();

  static const _prefsKey = 'archive_publish_queue_v1';
  bool _started = false;
  bool _processing = false;

  Future<void> ensureStarted() async {
    if (_started) {
      return;
    }
    _started = true;
    unawaited(processDue());
    Timer.periodic(const Duration(seconds: 20), (_) {
      unawaited(processDue());
    });
  }

  Future<List<Map<String, dynamic>>> _loadRaw() async {
    final p = await SharedPreferences.getInstance();
    final s = p.getString(_prefsKey);
    if (s == null || s.isEmpty) {
      return [];
    }
    final decoded = jsonDecode(s);
    if (decoded is! List) {
      return [];
    }
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<void> _saveRaw(List<Map<String, dynamic>> list) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_prefsKey, jsonEncode(list));
  }

  Future<void> enqueue({
    required MemeopsShareTarget target,
    required MemeArchiveKind kind,
    required String shareText,
    required String sourceLabel,
    required DateTime scheduledFor,
    String? localFilePath,
    String? networkUrl,
    String? localArchiveId,
    String? supabaseVersionId,
  }) async {
    final list = await _loadRaw();
    list.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'target': target.name,
      'kind': kind.name,
      'shareText': shareText,
      'sourceLabel': sourceLabel,
      'scheduledFor': scheduledFor.toIso8601String(),
      'localFilePath': localFilePath,
      'networkUrl': networkUrl,
      'localArchiveId': localArchiveId,
      'supabaseVersionId': supabaseVersionId,
    });
    await _saveRaw(list);
    unawaited(processDue());
  }

  Future<void> processDue() async {
    if (_processing) {
      return;
    }
    _processing = true;
    try {
      final now = DateTime.now();
      final list = await _loadRaw();
      if (list.isEmpty) {
        return;
      }
      final l10n = lookupAppLocalizations(AppLocaleController.instance.locale);
      final next = <Map<String, dynamic>>[];
      for (final job in list) {
        final when = DateTime.tryParse(job['scheduledFor'] as String? ?? '');
        if (when == null || when.isAfter(now)) {
          next.add(job);
          continue;
        }
        try {
          final target = MemeopsShareTarget.values.byName(
            job['target'] as String,
          );
          final kind = MemeArchiveKind.values.byName(job['kind'] as String);
          final localPath = job['localFilePath'] as String?;
          final net = job['networkUrl'] as String?;
          File? file;
          if (localPath != null && localPath.isNotEmpty) {
            file = File(localPath);
            if (!await file.exists()) {
              throw StateError('local_missing');
            }
          }
          await executeArchivePublish(
            null,
            target: target,
            kind: kind,
            shareText: (job['shareText'] as String?) ?? '',
            sourceLabel: (job['sourceLabel'] as String?) ?? '',
            localFile: file,
            networkUrl: (net != null && net.isNotEmpty) ? net : null,
            localArchiveId: job['localArchiveId'] as String?,
            supabaseVersionId: job['supabaseVersionId'] as String?,
          );
        } catch (e, st) {
          debugPrint('ArchivePublishScheduler: $e\n$st');
          MemeopsMessenger.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(l10n.archiveShareFailedWithError(e.toString())),
            ),
          );
        }
      }
      await _saveRaw(next);
    } finally {
      _processing = false;
    }
  }
}
