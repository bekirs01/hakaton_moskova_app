import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/media/supabase_playable_url.dart';
import 'package:hakaton_moskova_app/data/local/archive_publish_scheduler.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/data/repository/meme_supabase_assets_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/feed/meme_unified_feed.dart';
import 'package:hakaton_moskova_app/presentation/screens/archive_video_player_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/utils/archive_share.dart';
import 'package:hakaton_moskova_app/presentation/widgets/archive_detail_publish_section.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const double _kThumb = 48;

class MemeArchiveScreen extends StatefulWidget {
  const MemeArchiveScreen({super.key});

  @override
  State<MemeArchiveScreen> createState() => _MemeArchiveScreenState();
}

class _MemeArchiveScreenState extends State<MemeArchiveScreen> {
  final _repo = MemeLocalArchiveRepository.instance;
  late final MemeSupabaseAssetsRepository _cloudRepo =
      MemeSupabaseAssetsRepository(Supabase.instance.client);

  List<MemeFeedRow> _allRows = const [];
  bool _loading = true;
  bool _showLoadTimeoutHint = false;
  bool _supabaseFailed = false;

  @override
  void initState() {
    super.initState();
    unawaited(ArchivePublishScheduler.instance.ensureStarted());
    _repo.onChanged.addListener(_reload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_reload());
      }
    });
  }

  @override
  void dispose() {
    _repo.onChanged.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _showLoadTimeoutHint = false;
      _supabaseFailed = false;
    });
    MemeFeedLoad? load;
    try {
      load = await loadMemeUnifiedFeed();
    } catch (e, st) {
      debugPrint('MemeArchiveScreen._reload: $e\n$st');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _allRows = load?.rows ?? const [];
      _loading = false;
      _showLoadTimeoutHint = load?.loadEntriesTimedOut ?? false;
      _supabaseFailed = load?.supabaseFailed ?? true;
    });
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDateShort(DateTime d) {
    return '${_twoDigits(d.day)}.${_twoDigits(d.month)}.${d.year} · '
        '${_twoDigits(d.hour)}:${_twoDigits(d.minute)}';
  }

  /// Bulut satırı ile aynı URL’den indirilmiş yerel .mp4 varsa ağ yerine onu kullan.
  Future<({String entryId, File file})?> _localVideoForCloudAsset(
    SupabaseMemeAssetEntry v,
  ) {
    return _repo.findLocalVideoForCloudFileUrl(v.fileUrl);
  }

  String? _localPreview(MemeArchiveEntry e) {
    final c = (e.caption ?? '').trim();
    if (c.isNotEmpty) {
      return c;
    }
    return null;
  }

  String? _cloudPreview(SupabaseMemeAssetEntry v) {
    final t = (v.briefLine ?? '').trim();
    if (t.isNotEmpty) {
      return t;
    }
    return null;
  }

  Future<void> _confirmDeleteLocal(MemeArchiveEntry e) async {
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2436),
        title: Text(l10n.archiveEntryDeleteTitle),
        content: Text(
          l10n.archiveEntryDeleteMessage,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.archiveEntryDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.archiveEntryDelete),
          ),
        ],
      ),
    );
    if (go != true || !mounted) {
      return;
    }
    try {
      await _repo.removeEntry(e);
    } catch (err, st) {
      debugPrint('removeEntry: $err\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errUnexpected)),
        );
      }
    }
  }

  Future<void> _confirmDeleteCloud(SupabaseMemeAssetEntry e) async {
    final l10n = AppLocalizations.of(context);
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2436),
        title: Text(l10n.archiveEntryDeleteTitle),
        content: Text(
          l10n.archiveEntryDeleteMessage,
          style: const TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.archiveEntryDeleteCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.archiveEntryDelete),
          ),
        ],
      ),
    );
    if (go != true || !mounted) {
      return;
    }
    try {
      await _cloudRepo.deleteAssetVersion(e.id);
      if (mounted) {
        await _reload();
      }
    } catch (err, st) {
      debugPrint('deleteAssetVersion: $err\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errUnexpected)),
        );
      }
    }
  }

  Future<void> _openLocal(MemeArchiveEntry e) async {
    final l10n = AppLocalizations.of(context);
    final file = await _repo.fileFor(e);
    if (!mounted) {
      return;
    }
    if (!await file.exists()) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.archiveFileMissing)),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    if (e.kind == MemeArchiveKind.video) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ArchiveVideoPlayerScreen(
            file: file,
            title: e.sourceLabel,
            caption: e.caption,
            localArchiveId: e.id,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ArchiveLocalStillDetailPage(entry: e, file: file),
      ),
    );
  }

  Future<void> _openCloud(
    BuildContext context,
    AppLocalizations l10n,
    SupabaseMemeAssetEntry v,
  ) async {
    if (v.isVideo) {
      // Aynı video yerelde "kayıtlı"ysa: ağ URL’si bozuksa bile dosyadan oynat.
      final localTry = await _localVideoForCloudAsset(v);
      if (localTry != null && await localTry.file.exists()) {
        if (!context.mounted) {
          return;
        }
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ArchiveVideoPlayerScreen(
              file: localTry.file,
              title: l10n.tabArchive,
              caption: v.briefLine,
              localArchiveId: localTry.entryId,
            ),
          ),
        );
        return;
      }
      final resolved = resolveMemeAssetPlayableUrl(
        Supabase.instance.client,
        v.fileUrl,
        v.storagePath,
      );
      final uri = Uri.tryParse(resolved.trim());
      if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errNetworkUser)),
          );
        }
        return;
      }
      if (!context.mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ArchiveVideoPlayerScreen(
            networkUri: uri,
            storagePath: v.storagePath,
            title: l10n.tabArchive,
            caption: v.briefLine,
            supabaseVersionId: v.id,
            sourceMemeBriefId: v.sourceMemeBriefId,
          ),
        ),
      );
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _ArchiveCloudStillDetailPage(asset: v, l10n: l10n),
      ),
    );
  }

  Future<void> _shareLocal(MemeArchiveEntry e) async {
    final file = await _repo.fileFor(e);
    if (!mounted) {
      return;
    }
    await shareArchiveFile(
      context,
      file: file,
      sourceLabel: e.sourceLabel,
      kind: e.kind,
      caption: e.caption,
      localArchiveId: e.id,
    );
  }

  Future<void> _shareCloud(
    AppLocalizations l10n,
    SupabaseMemeAssetEntry v,
  ) async {
    if (v.isVideo) {
      await shareArchiveVideoFromNetworkUrl(
        context,
        url: v.fileUrl,
        sourceLabel: l10n.tabArchive,
        caption: v.briefLine,
        supabaseVersionId: v.id,
      );
    } else {
      await shareArchiveImageFromNetworkUrl(
        context,
        url: v.fileUrl,
        sourceLabel: l10n.tabArchive,
        caption: v.briefLine,
        supabaseVersionId: v.id,
      );
    }
  }

  Widget _thumbLocal(MemeArchiveEntry e) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: FutureBuilder<File>(
        future: _repo.fileFor(e),
        builder: (context, snap) {
          final f = snap.data;
          if (f == null || !f.existsSync()) {
            return Container(
              width: _kThumb,
              height: _kThumb,
              color: Colors.white.withValues(alpha: 0.06),
              child: const Icon(Icons.broken_image_outlined, size: 20),
            );
          }
          if (e.kind == MemeArchiveKind.video) {
            return Container(
              width: _kThumb,
              height: _kThumb,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    MemeopsColors.iosBlue.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.55),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.play_circle_fill_rounded,
                color: Colors.white,
                size: 26,
              ),
            );
          }
          return Image.file(
            f,
            width: _kThumb,
            height: _kThumb,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }

  Widget _thumbCloud(SupabaseMemeAssetEntry a) {
    if (a.isVideo) {
      return Container(
        width: _kThumb,
        height: _kThumb,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              MemeopsColors.iosBlue.withValues(alpha: 0.5),
              Colors.black.withValues(alpha: 0.55),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.play_circle_fill_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        a.fileUrl,
        width: _kThumb,
        height: _kThumb,
        fit: BoxFit.cover,
        errorBuilder: (c, e, st) => Container(
          width: _kThumb,
          height: _kThumb,
          color: Colors.white.withValues(alpha: 0.08),
          alignment: Alignment.center,
          child: const Icon(
            Icons.image_not_supported_outlined,
            color: Colors.white54,
            size: 20,
          ),
        ),
      ),
    );
  }

  static final _listPad = const EdgeInsets.fromLTRB(10, 0, 10, 18);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = _allRows;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showLoadTimeoutHint || _supabaseFailed)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
            child: Text(
              _showLoadTimeoutHint
                  ? l10n.archiveListLoadError
                  : l10n.archiveSupabaseLoadError,
              style: MemeopsTextStyles.caption(context).copyWith(
                fontSize: 11,
                color: MemeopsColors.iosBlueBright.withValues(alpha: 0.9),
              ),
            ),
          ),
        Expanded(
          child: _loading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: rows.isEmpty
                      ? ListView(
                          padding: _listPad,
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.sizeOf(context).height * 0.12,
                            ),
                            Center(
                              child: Text(
                                l10n.archiveEmpty,
                                textAlign: TextAlign.center,
                                style: MemeopsTextStyles.caption(context),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: _listPad,
                          itemCount: rows.length,
                          itemBuilder: (context, i) {
                            final row = rows[i];
                            if (row.isSupabase) {
                              final v = row.supabase!;
                              final line = _cloudPreview(v);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: MemeopsGlassSurface(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  borderRadius: MemeopsRadii.sm,
                                  child: InkWell(
                                    onTap: () => _openCloud(context, l10n, v),
                                    onLongPress: () =>
                                        unawaited(_confirmDeleteCloud(v)),
                                    borderRadius: BorderRadius.circular(
                                      MemeopsRadii.sm,
                                    ),
                                    child: Row(
                                      children: [
                                        _thumbCloud(v),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                _formatDateShort(v.createdAt),
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  height: 1.1,
                                                  fontWeight: FontWeight.w600,
                                                  color: MemeopsColors
                                                      .iosBlueBright
                                                      .withValues(alpha: 0.95),
                                                ),
                                              ),
                                              if (line != null) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  line,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    height: 1.2,
                                                    color: Colors.white
                                                        .withValues(
                                                      alpha: 0.88,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          visualDensity: VisualDensity
                                              .compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          icon: Icon(
                                            Icons.share_rounded,
                                            size: 20,
                                            color: MemeopsColors.iosBlueBright
                                                .withValues(alpha: 0.95),
                                          ),
                                          onPressed: () =>
                                              _shareCloud(l10n, v),
                                        ),
                                        Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18,
                                          color: Colors.white.withValues(
                                            alpha: 0.25,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                            final e = row.local!;
                            final line = _localPreview(e);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: MemeopsGlassSurface(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                borderRadius: MemeopsRadii.sm,
                                child: InkWell(
                                  onTap: () => _openLocal(e),
                                  onLongPress: () =>
                                      unawaited(_confirmDeleteLocal(e)),
                                  borderRadius: BorderRadius.circular(
                                    MemeopsRadii.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      _thumbLocal(e),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              _formatDateShort(e.createdAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                height: 1.1,
                                                fontWeight: FontWeight.w600,
                                                color: MemeopsColors
                                                    .iosBlueBright
                                                    .withValues(alpha: 0.95),
                                              ),
                                            ),
                                            if (line != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                line,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 12.5,
                                                  height: 1.2,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.88),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 36,
                                          minHeight: 36,
                                        ),
                                        icon: Icon(
                                          Icons.share_rounded,
                                          size: 20,
                                          color: MemeopsColors.iosBlueBright
                                              .withValues(alpha: 0.95),
                                        ),
                                        onPressed: () => _shareLocal(e),
                                      ),
                                      Icon(
                                        Icons.chevron_right_rounded,
                                        size: 18,
                                        color: Colors.white.withValues(
                                          alpha: 0.25,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );
  }
}

class _ArchiveLocalStillDetailPage extends StatefulWidget {
  const _ArchiveLocalStillDetailPage({
    required this.entry,
    required this.file,
  });

  final MemeArchiveEntry entry;
  final File file;

  @override
  State<_ArchiveLocalStillDetailPage> createState() =>
      _ArchiveLocalStillDetailPageState();
}

class _ArchiveLocalStillDetailPageState extends State<_ArchiveLocalStillDetailPage> {
  final _publishKey = GlobalKey<ArchiveDetailPublishSectionState>();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final e = widget.entry;
    return Scaffold(
      backgroundColor: MemeopsColors.bgMid,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        title: Text(e.sourceLabel, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: l10n.archiveShare,
            onPressed: () => _publishKey.currentState?.submitPublish(),
            icon: const Icon(Icons.share_rounded, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4,
              child: Image.file(widget.file, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),
          ArchiveDetailPublishSection(
            key: _publishKey,
            sourceLabel: e.sourceLabel,
            initialCaption: e.caption,
            mediaKind: e.kind,
            localFile: widget.file,
            localArchiveId: e.id,
          ),
        ],
      ),
    );
  }
}

class _ArchiveCloudStillDetailPage extends StatefulWidget {
  const _ArchiveCloudStillDetailPage({
    required this.asset,
    required this.l10n,
  });

  final SupabaseMemeAssetEntry asset;
  final AppLocalizations l10n;

  @override
  State<_ArchiveCloudStillDetailPage> createState() =>
      _ArchiveCloudStillDetailPageState();
}

class _ArchiveCloudStillDetailPageState extends State<_ArchiveCloudStillDetailPage> {
  final _publishKey = GlobalKey<ArchiveDetailPublishSectionState>();

  @override
  Widget build(BuildContext context) {
    final v = widget.asset;
    final l10n = widget.l10n;
    return Scaffold(
      backgroundColor: MemeopsColors.bgMid,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        title: Text(l10n.tabArchive, style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: l10n.archiveShare,
            onPressed: () => _publishKey.currentState?.submitPublish(),
            icon: const Icon(Icons.share_rounded, size: 22),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 4,
              child: Image.network(
                v.fileUrl,
                fit: BoxFit.contain,
                loadingBuilder: (c, w, p) {
                  if (p == null) {
                    return w;
                  }
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (c, e, st) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.imageLoadError,
                    style: MemeopsTextStyles.caption(context),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ArchiveDetailPublishSection(
            key: _publishKey,
            sourceLabel: l10n.tabArchive,
            initialCaption: v.briefLine,
            mediaKind: MemeArchiveKind.image,
            networkUrl: v.fileUrl,
            supabaseVersionId: v.id,
            sourceMemeBriefId: v.sourceMemeBriefId,
          ),
        ],
      ),
    );
  }
}
