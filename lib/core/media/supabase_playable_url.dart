import 'package:supabase_flutter/supabase_flutter.dart';

/// [meme_asset_versions.file_url] boş / bozuk / localhost ise [storage_path] ile
/// **public** URL üretir (DNS "hostname not found" çoğu zaman bu yüzden olur).
/// İmzalı URL gerekirse oynatıcıda ayrıca [ArchiveVideoPlayerScreen] yedekler.
String resolveMemeAssetPlayableUrl(
  SupabaseClient client,
  String? rawUrl,
  String? storagePath,
) {
  final raw = (rawUrl ?? '').trim();
  final sp = (storagePath ?? '').trim();

  bool looksBroken(String u) {
    if (u.isEmpty) {
      return true;
    }
    final p = Uri.tryParse(u);
    if (p == null) {
      return true;
    }
    if (!p.hasScheme) {
      return true;
    }
    if (p.host.isEmpty) {
      return true;
    }
    if (p.host == '127.0.0.1' || p.host == 'localhost' || p.host == '0.0.0.0') {
      return true;
    }
    return false;
  }

  if (!looksBroken(raw)) {
    return raw;
  }
  if (sp.isNotEmpty) {
    return client.storage.from('meme-assets').getPublicUrl(sp);
  }
  return raw;
}
