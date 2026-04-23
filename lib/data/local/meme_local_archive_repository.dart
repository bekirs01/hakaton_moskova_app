import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Arşiv kaydının türü (görsel veya video).
enum MemeArchiveKind { image, video }

/// Cihazda saklanan tek bir meme kaydı (indirilmiş dosya; görsel veya video).
class MemeArchiveEntry {
  const MemeArchiveEntry({
    required this.id,
    required this.localFileName,
    required this.createdAt,
    this.caption,
    required this.sourceLabel,
    this.kind = MemeArchiveKind.image,
    this.durationSeconds,
  });

  final String id;
  final String localFileName;
  final DateTime createdAt;
  final String? caption;
  final String sourceLabel;
  final MemeArchiveKind kind;
  final int? durationSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'localFileName': localFileName,
        'createdAt': createdAt.toIso8601String(),
        'caption': caption,
        'sourceLabel': sourceLabel,
        'kind': kind.name,
        'durationSeconds': durationSeconds,
      };

  factory MemeArchiveEntry.fromJson(Map<String, dynamic> j) {
    final kindRaw = (j['kind'] as String?)?.toLowerCase();
    final kind = kindRaw == 'video' ? MemeArchiveKind.video : MemeArchiveKind.image;
    return MemeArchiveEntry(
      id: j['id'] as String,
      localFileName: j['localFileName'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      caption: j['caption'] as String?,
      sourceLabel: (j['sourceLabel'] as String?) ?? '',
      kind: kind,
      durationSeconds: (j['durationSeconds'] as num?)?.toInt(),
    );
  }
}

/// Üretilen görselleri uygulama belgesi klasörüne indirip indeksler.
class MemeLocalArchiveRepository {
  MemeLocalArchiveRepository._();
  static final instance = MemeLocalArchiveRepository._();

  final ValueNotifier<int> onChanged = ValueNotifier<int>(0);

  Directory? _root;

  Future<Directory> getArchiveDirectory() async {
    if (_root != null) {
      return _root!;
    }
    final doc = await getApplicationDocumentsDirectory();
    _root = Directory(p.join(doc.path, 'meme_archive'));
    if (!await _root!.exists()) {
      await _root!.create(recursive: true);
    }
    return _root!;
  }

  Future<File> _indexFile() async {
    final dir = await getArchiveDirectory();
    return File(p.join(dir.path, 'index.json'));
  }

  Future<List<MemeArchiveEntry>> loadEntries() async {
    final f = await _indexFile();
    if (!await f.exists()) {
      return [];
    }
    try {
      final raw = await f.readAsString();
      final list = jsonDecode(raw) as List<dynamic>;
      final entries = list
          .map((e) => MemeArchiveEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return entries;
    } catch (e, st) {
      debugPrint('MemeLocalArchiveRepository.loadEntries: $e\n$st');
      return [];
    }
  }

  Future<void> _saveEntries(List<MemeArchiveEntry> entries) async {
    final f = await _indexFile();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await f.writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  String _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
    if (path.endsWith('.png')) {
      return '.png';
    }
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
      return '.jpg';
    }
    if (path.endsWith('.webp')) {
      return '.webp';
    }
    if (path.endsWith('.mp4')) {
      return '.mp4';
    }
    if (path.endsWith('.gif')) {
      return '.gif';
    }
    return '.img';
  }

  Future<File> fileFor(MemeArchiveEntry e) async {
    final dir = await getArchiveDirectory();
    return File(p.join(dir.path, e.localFileName));
  }

  Future<void> addFromNetworkUrl({
    required String imageUrl,
    String? caption,
    required String sourceLabel,
    MemeArchiveKind kind = MemeArchiveKind.image,
    int? durationSeconds,
  }) async {
    final uri = Uri.parse(imageUrl);
    // Video dosyaları için daha geniş timeout.
    final timeout = kind == MemeArchiveKind.video
        ? const Duration(minutes: 5)
        : const Duration(minutes: 2);
    final resp = await http.get(uri).timeout(timeout);
    if (resp.statusCode != 200) {
      throw StateError(
        lookupAppLocalizations(AppLocaleController.instance.locale)
            .archiveDownloadFailed(resp.statusCode),
      );
    }
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final ext = _extFromUrl(imageUrl);
    final dir = await getArchiveDirectory();
    final fileName = '$id$ext';
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(resp.bodyBytes);

    final entry = MemeArchiveEntry(
      id: id,
      localFileName: fileName,
      createdAt: DateTime.now(),
      caption: caption,
      sourceLabel: sourceLabel,
      kind: kind,
      durationSeconds: durationSeconds,
    );
    final existing = await loadEntries();
    existing.insert(0, entry);
    await _saveEntries(existing);
    onChanged.value++;
  }
}
