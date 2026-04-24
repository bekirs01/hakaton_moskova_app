import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// `file_url` içinde `.../meme-assets/<object path>` bölgesinden depo nesne yolunu üretir.
/// Eski satırlarda [storage_path] boş, `file_url` public/sign formatında kaldığında imza için gerekir.
String? tryExtractMemeAssetsStoragePathFromUrl(String? fileUrl) {
  final t = (fileUrl ?? '').trim();
  if (t.isEmpty) {
    return null;
  }
  final u = Uri.tryParse(t);
  if (u == null || !u.hasScheme) {
    return null;
  }
  final segs = u.pathSegments;
  final i = segs.indexOf('meme-assets');
  if (i < 0 || i >= segs.length - 1) {
    return null;
  }
  return segs.sublist(i + 1).join('/');
}

/// [meme_asset_versions] için oynatılabilir/kullanılabilir URL.
/// [storage_path] yoksa `file_url` yolundan çıkarılan object path ile imzalı URL üretir
/// (gizli bucket, bozuk/localhost [file_url]).
Future<String> resolveMemeAssetPlayableUrl(
  SupabaseClient client,
  String? rawUrl,
  String? storagePath,
) async {
  var sp = (storagePath ?? '').trim();
  if (sp.isEmpty) {
    sp = (tryExtractMemeAssetsStoragePathFromUrl(rawUrl) ?? '').trim();
  }
  if (sp.isNotEmpty) {
    try {
      return await client.storage
          .from('meme-assets')
          .createSignedUrl(sp, 60 * 60);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('resolveMemeAssetPlayableUrl signed: $e\n$st');
      }
      return client.storage.from('meme-assets').getPublicUrl(sp);
    }
  }
  final raw = (rawUrl ?? '').trim();
  if (!looksUnplayableLocalhost(raw)) {
    return raw;
  }
  return raw;
}

bool looksUnplayableLocalhost(String u) {
  if (u.isEmpty) {
    return true;
  }
  final p = Uri.tryParse(u);
  if (p == null || !p.hasScheme) {
    return true;
  }
  if (p.host.isEmpty) {
    return true;
  }
  final h = p.host.toLowerCase();
  if (h == '127.0.0.1' ||
      h == 'localhost' ||
      h == '0.0.0.0' ||
      h == '10.0.2.2') {
    return true;
  }
  return false;
}
