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

/// Aynı depo nesnesi: imza veya host farklı olsa da [Uri.path] eşleşir.
String _dedupKeyForUrl(String url) {
  final t = _normAssetUrl(url);
  final u = Uri.tryParse(t);
  if (u != null && u.path.isNotEmpty) {
    return u.path;
  }
  return t;
}

/// Yerel + bulut girdilerini birleştirir; arşiv ekranı aşamalı yükleme için dışa açık.
MemeFeedLoad buildMemeFeedLoad({
  required List<MemeArchiveEntry> localList,
  required List<SupabaseMemeAssetEntry> cloudList,
  required bool loadEntriesTimedOut,
  required bool supabaseFailed,
}) {
  // Aynı sourceUrl (ör. arşiv iki kez yazıldıysa) yerelde tek satır.
  final localDeduped = <MemeArchiveEntry>[];
  final seenLocalSource = <String>{};
  for (final e in localList) {
    final su = e.sourceUrl?.trim();
    if (su != null && su.isNotEmpty) {
      final k = _dedupKeyForUrl(su);
      if (k.isNotEmpty && seenLocalSource.contains(k)) {
        continue;
      }
      if (k.isNotEmpty) {
        seenLocalSource.add(k);
      }
    }
    localDeduped.add(e);
  }

  final localAssetKeys = <String>{
    for (final e in localDeduped)
      if (e.sourceUrl != null && e.sourceUrl!.trim().isNotEmpty)
        _dedupKeyForUrl(e.sourceUrl!),
  };
  final cloudDeduped = cloudList
      .where((v) => !localAssetKeys.contains(_dedupKeyForUrl(v.fileUrl)))
      .toList();

  final merged = <MemeFeedRow>[];
  for (final e in localDeduped) {
    merged.add(MemeFeedRow.local(e));
  }
  for (final v in cloudDeduped) {
    merged.add(MemeFeedRow.cloud(v));
  }
  // En yeni üstte: tek tip UTC ile karşılaştır (yerel/Supabase farkı sırayı bozmasın).
  merged.sort((a, b) {
    final da = a.isSupabase ? a.supabase!.createdAt : a.local!.createdAt;
    final db = b.isSupabase ? b.supabase!.createdAt : b.local!.createdAt;
    final c = db.toUtc().compareTo(da.toUtc());
    if (c != 0) {
      return c;
    }
    final sa = a.isSupabase ? a.supabase!.id : a.local!.id;
    final sb = b.isSupabase ? b.supabase!.id : b.local!.id;
    return sa.compareTo(sb);
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
