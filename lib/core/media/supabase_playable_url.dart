import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// [meme_asset_versions] için oynatılabilir/kullanılabilir URL.
/// [storage_path] varsa imzalı URL üretir (gizli bucket + bozuk `file_url` / localhost).
Future<String> resolveMemeAssetPlayableUrl(
  SupabaseClient client,
  String? rawUrl,
  String? storagePath,
) async {
  final sp = (storagePath ?? '').trim();
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
