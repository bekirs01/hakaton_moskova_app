import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/media/supabase_playable_url.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Giriş yapmış kullanıcı için [meme_asset_versions] (tüm görseller + videolar, RLS).
class MemeSupabaseAssetsRepository {
  MemeSupabaseAssetsRepository(this._client);

  final SupabaseClient _client;

  static bool _isVideoUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final u = url.toLowerCase();
    return u.contains('.mp4') ||
        u.contains('.webm') ||
        u.contains('/video-') ||
        u.contains('.mov');
  }

  static bool _isImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final u = url.toLowerCase();
    if (_isVideoUrl(url)) {
      return false;
    }
    return u.contains('.png') ||
        u.contains('.jpg') ||
        u.contains('.jpeg') ||
        u.contains('.webp') ||
        u.contains('.gif');
  }

  static String? _lineFromBrief(Map<String, dynamic> b) {
    for (final k in <String>['memotype_idea', 'brief_title', 'suggested_caption_ru']) {
      final t = (b[k] as String?)?.trim();
      if (t != null && t.isNotEmpty) {
        return t;
      }
    }
    return null;
  }

  /// [file_url] dolu, görsel veya video uzantısı eşleşen tüm sürümler (en yeni üstte).
  Future<List<SupabaseMemeAssetEntry>> listAccountAssets() async {
    final raw = await _client
        .from('meme_asset_versions')
        .select(
          'id, file_url, storage_path, created_at, version_number, source_meme_brief_id',
        )
        .order('created_at', ascending: false)
        .limit(300) as List<dynamic>;

    final rowMaps = <Map<String, dynamic>>[];
    for (final e in raw) {
      if (e is! Map) {
        continue;
      }
      rowMaps.add(Map<String, dynamic>.from(e));
    }

    await Future.wait<void>(
      rowMaps.map((m) async {
        final sp = m['storage_path'] as String?;
        final rawUrl = m['file_url'] as String?;
        final url = await resolveMemeAssetPlayableUrl(
          _client,
          rawUrl,
          sp,
        );
        m['_resolved_file_url'] = url;
      }),
    );

    final rows = <Map<String, dynamic>>[];
    for (final m in rowMaps) {
      final u = (m['_resolved_file_url'] as String?)?.trim() ?? '';
      if (u.isEmpty) {
        continue;
      }
      if (!_isImageUrl(u) && !_isVideoUrl(u)) {
        continue;
      }
      rows.add(m);
    }
    if (rows.isEmpty) {
      return [];
    }

    final briefIdSet = <String>{};
    for (final m in rows) {
      final bid = m['source_meme_brief_id'] as String?;
      if (bid != null) {
        briefIdSet.add(bid);
      }
    }
    final briefIds = briefIdSet.toList();
    var briefById = <String, Map<String, dynamic>>{};
    if (briefIds.isNotEmpty) {
      try {
        final bRaw = await _client
            .from('meme_briefs')
            .select('id, brief_title, memotype_idea, suggested_caption_ru')
            .inFilter('id', briefIds) as List<dynamic>;
        for (final b in bRaw) {
          if (b is! Map) {
            continue;
          }
          final row = Map<String, dynamic>.from(b);
          final id = row['id'] as String?;
          if (id != null) {
            briefById[id] = row;
          }
        }
      } catch (e, st) {
        debugPrint('meme_briefs batch: $e\n$st');
        briefById = {};
      }
    }

    return rows.map((m) {
      final u = (m['_resolved_file_url'] as String?)?.trim() ?? '';
      final isVid = _isVideoUrl(u);
      final id = m['id'] as String;
      final createdAt = DateTime.parse(m['created_at'] as String);
      final vn = (m['version_number'] as num?)?.toInt() ?? 0;
      final bid = m['source_meme_brief_id'] as String?;
      String? bl;
      if (bid != null) {
        final b = briefById[bid];
        if (b != null) {
          bl = _lineFromBrief(b);
        }
      }
      return SupabaseMemeAssetEntry(
        id: id,
        fileUrl: u,
        storagePath: (m['storage_path'] as String?)?.trim(),
        createdAt: createdAt,
        versionNumber: vn,
        isVideo: isVid,
        briefLine: bl,
        sourceMemeBriefId: bid,
      );
    }).toList();
  }

  /// Arşivde düzenlenen açıklamayı [suggested_caption_ru] alanına yazar.
  Future<void> updateBriefSuggestedCaption(String briefId, String caption) async {
    final t = caption.trim();
    await _client.from('meme_briefs').update({
      'suggested_caption_ru': t,
    }).eq('id', briefId);
  }

  /// [meme_asset_versions] satırını siler; [storage_path] varsa depo dosyasını kaldırmayı dener.
  Future<void> deleteAssetVersion(String id) async {
    try {
      final row = await _client
          .from('meme_asset_versions')
          .select('storage_path')
          .eq('id', id)
          .maybeSingle();
      if (row != null) {
        final sp = row['storage_path'] as String?;
        if (sp != null && sp.isNotEmpty) {
          try {
            await _client.storage.from('meme-assets').remove([sp]);
          } catch (e, st) {
            debugPrint('meme-assets remove: $e\n$st');
          }
        }
      }
    } catch (e, st) {
      debugPrint('deleteAssetVersion prefetch: $e\n$st');
    }
    await _client.from('meme_asset_versions').delete().eq('id', id);
  }
}
