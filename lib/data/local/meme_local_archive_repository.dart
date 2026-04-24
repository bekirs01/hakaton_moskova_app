import 'dart:async';
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
    this.sourceUrl,
  });

  final String id;
  final String localFileName;
  final DateTime createdAt;
  final String? caption;
  final String sourceLabel;
  final MemeArchiveKind kind;
  final int? durationSeconds;

  /// Aynı üretim URL’si tekrar arşive eklenmesin (paylaş sonrası yedek vs.).
  final String? sourceUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'localFileName': localFileName,
        'createdAt': createdAt.toIso8601String(),
        'caption': caption,
        'sourceLabel': sourceLabel,
        'kind': kind.name,
        'durationSeconds': durationSeconds,
        if (sourceUrl != null) 'sourceUrl': sourceUrl,
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
      sourceUrl: j['sourceUrl'] as String?,
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

  static const _loadEntriesTimeout = Duration(seconds: 30);

  /// [loadEntriesTimedOut] true ise indeks okuma süresi aşıldı; liste boş olabilir.
  Future<({List<MemeArchiveEntry> entries, bool loadEntriesTimedOut})> loadEntries() async {
    var timedOut = false;
    try {
      final list = await _loadEntriesImpl().timeout(
        _loadEntriesTimeout,
        onTimeout: () {
          timedOut = true;
          debugPrint('MemeLocalArchiveRepository.loadEntries: timed out after $_loadEntriesTimeout');
          return <MemeArchiveEntry>[];
        },
      );
      return (entries: list, loadEntriesTimedOut: timedOut);
    } catch (e, st) {
      debugPrint('MemeLocalArchiveRepository.loadEntries: $e\n$st');
      return (entries: <MemeArchiveEntry>[], loadEntriesTimedOut: false);
    }
  }

  Future<List<MemeArchiveEntry>> _loadEntriesImpl() async {
    final f = await _indexFile();
    if (!await f.exists()) {
      return [];
    }
    final raw = await f.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      debugPrint('MemeLocalArchiveRepository.loadEntries: index.json is not a list');
      return [];
    }
    final entries = <MemeArchiveEntry>[];
    for (var i = 0; i < decoded.length; i++) {
      final e = decoded[i];
      if (e is! Map) {
        debugPrint('MemeLocalArchiveRepository.loadEntries: skip non-map at index $i');
        continue;
      }
      try {
        entries.add(
          MemeArchiveEntry.fromJson(
            Map<String, dynamic>.from(e),
          ),
        );
      } catch (err, st) {
        debugPrint('MemeLocalArchiveRepository.loadEntries: skip entry $i: $err\n$st');
      }
    }
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
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

  String _urlKey(String url) {
    final t = url.trim();
    final q = t.indexOf('?');
    return q < 0 ? t : t.substring(0, q);
  }

  Future<void> addFromNetworkUrl({
    required String imageUrl,
    String? caption,
    required String sourceLabel,
    MemeArchiveKind kind = MemeArchiveKind.image,
    int? durationSeconds,
  }) async {
    final load0 = await loadEntries();
    final key = _urlKey(imageUrl);
    for (final e in load0.entries) {
      if (e.sourceUrl != null && _urlKey(e.sourceUrl!) == key) {
        return;
      }
    }

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
      sourceUrl: imageUrl.trim(),
    );
    final existing = List<MemeArchiveEntry>.from(load0.entries);
    existing.insert(0, entry);
    await _saveEntries(existing);
    onChanged.value++;
  }

  /// [index.json] içinde açıklamayı günceller (boş string → null).
  Future<void> updateEntryCaption(String id, String? caption) async {
    final list = await _loadEntriesImpl();
    final idx = list.indexWhere((e) => e.id == id);
    if (idx < 0) {
      return;
    }
    final e = list[idx];
    final trimmed = caption?.trim();
    final nextCaption = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
    list[idx] = MemeArchiveEntry(
      id: e.id,
      localFileName: e.localFileName,
      createdAt: e.createdAt,
      caption: nextCaption,
      sourceLabel: e.sourceLabel,
      kind: e.kind,
      durationSeconds: e.durationSeconds,
      sourceUrl: e.sourceUrl,
    );
    await _saveEntries(list);
    onChanged.value++;
  }

  /// İndeksten çıkarır ve dosyayı siler.
  Future<void> removeEntry(MemeArchiveEntry e) async {
    final list = await _loadEntriesImpl();
    final next = list.where((x) => x.id != e.id).toList();
    if (next.length == list.length) {
      return;
    }
    try {
      final f = await fileFor(e);
      if (await f.exists()) {
        await f.delete();
      }
    } catch (err, st) {
      debugPrint('removeEntry file: $err\n$st');
    }
    await _saveEntries(next);
    onChanged.value++;
  }
}
