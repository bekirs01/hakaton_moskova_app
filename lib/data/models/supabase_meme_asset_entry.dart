import 'package:flutter/foundation.dart';

/// RLS sonrası [meme_asset_versions] (görsel + video) satırı.
@immutable
class SupabaseMemeAssetEntry {
  const SupabaseMemeAssetEntry({
    required this.id,
    required this.fileUrl,
    required this.createdAt,
    required this.versionNumber,
    required this.isVideo,
    this.briefLine,
    this.sourceMemeBriefId,
  });

  final String id;
  final String fileUrl;
  final DateTime createdAt;
  final int versionNumber;
  final bool isVideo;
  final String? briefLine;

  /// [meme_briefs] satırı; açıklama kaydı için gerekli.
  final String? sourceMemeBriefId;
}
