import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Cihazda saklanan tek bir meme görseli kaydı (indirilmiş dosya).
class MemeArchiveEntry {
  const MemeArchiveEntry({
    required this.id,
    required this.localFileName,
    required this.createdAt,
    this.caption,
    required this.sourceLabel,
  });

  final String id;
  final String localFileName;
  final DateTime createdAt;
  final String? caption;
  final String sourceLabel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'localFileName': localFileName,
        'createdAt': createdAt.toIso8601String(),
        'caption': caption,
        'sourceLabel': sourceLabel,
      };

  factory MemeArchiveEntry.fromJson(Map<String, dynamic> j) {
    return MemeArchiveEntry(
      id: j['id'] as String,
      localFileName: j['localFileName'] as String,
      createdAt: DateTime.parse(j['createdAt'] as String),
      caption: j['caption'] as String?,
      sourceLabel: (j['sourceLabel'] as String?) ?? '',
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
  }) async {
    final uri = Uri.parse(imageUrl);
    final resp = await http.get(uri).timeout(const Duration(minutes: 2));
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
    );
    final existing = await loadEntries();
    existing.insert(0, entry);
    await _saveEntries(existing);
    onChanged.value++;
  }
}
