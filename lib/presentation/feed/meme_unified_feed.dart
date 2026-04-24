import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/data/repository/meme_supabase_assets_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Arşiv ve Analiz sekmeleri aynı birleşik listeyi kullanır (yerel + Supabase).
@immutable
class MemeFeedRow {
  const MemeFeedRow._(this.local, this.supabase);

  factory MemeFeedRow.local(MemeArchiveEntry e) => MemeFeedRow._(e, null);

  factory MemeFeedRow.cloud(SupabaseMemeAssetEntry e) => MemeFeedRow._(null, e);

  final MemeArchiveEntry? local;
  final SupabaseMemeAssetEntry? supabase;

  bool get isSupabase => supabase != null;
}

@immutable
class MemeFeedLoad {
  const MemeFeedLoad({
    required this.rows,
    required this.loadEntriesTimedOut,
    required this.supabaseFailed,
  });

  final List<MemeFeedRow> rows;
  final bool loadEntriesTimedOut;
  final bool supabaseFailed;
}

String _normAssetUrl(String url) {
  final t = url.trim();
  final q = t.indexOf('?');
  return q < 0 ? t : t.substring(0, q);
}

/// Yerel + bulut girdilerini birleştirir; arşiv ekranı aşamalı yükleme için dışa açık.
MemeFeedLoad buildMemeFeedLoad({
  required List<MemeArchiveEntry> localList,
  required List<SupabaseMemeAssetEntry> cloudList,
  required bool loadEntriesTimedOut,
  required bool supabaseFailed,
}) {
  final localAssetKeys = <String>{
    for (final e in localList)
      if (e.sourceUrl != null && e.sourceUrl!.trim().isNotEmpty)
        _normAssetUrl(e.sourceUrl!),
  };
  final cloudDeduped = cloudList
      .where((v) => !localAssetKeys.contains(_normAssetUrl(v.fileUrl)))
      .toList();

  final merged = <MemeFeedRow>[];
  for (final e in localList) {
    merged.add(MemeFeedRow.local(e));
  }
  for (final v in cloudDeduped) {
    merged.add(MemeFeedRow.cloud(v));
  }
  merged.sort((a, b) {
    final ta = a.isSupabase ? a.supabase!.createdAt : a.local!.createdAt;
    final tb = b.isSupabase ? b.supabase!.createdAt : b.local!.createdAt;
    return tb.compareTo(ta);
  });

  return MemeFeedLoad(
    rows: merged,
    loadEntriesTimedOut: loadEntriesTimedOut,
    supabaseFailed: supabaseFailed,
  );
}

/// Yerel [meme_archive] + [meme_asset_versions] sorgusu; sonuçlar en yeni üstte.
/// Yerel ve bulut listeleri paralel çekilir (bekleme süresi kısalır).
Future<MemeFeedLoad> loadMemeUnifiedFeed() async {
  final repo = MemeLocalArchiveRepository.instance;
  final cloudRepo = MemeSupabaseAssetsRepository(Supabase.instance.client);

  var localList = const <MemeArchiveEntry>[];
  var loadTimedOut = false;
  var cloudList = const <SupabaseMemeAssetEntry>[];
  var supabaseFailed = false;

  await Future.wait<void>([
    () async {
      try {
        final r = await repo.loadEntries();
        localList = r.entries;
        loadTimedOut = r.loadEntriesTimedOut;
      } catch (e, st) {
        debugPrint('loadMemeUnifiedFeed local: $e\n$st');
      }
    }(),
    () async {
      try {
        cloudList = await cloudRepo.listAccountAssets();
      } catch (e, st) {
        debugPrint('loadMemeUnifiedFeed cloud: $e\n$st');
        supabaseFailed = true;
      }
    }(),
  ]);

  return buildMemeFeedLoad(
    localList: localList,
    cloudList: cloudList,
    loadEntriesTimedOut: loadTimedOut,
    supabaseFailed: supabaseFailed,
  );
}
