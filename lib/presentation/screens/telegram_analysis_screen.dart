import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart'
    show MemeArchiveEntry, MemeArchiveKind, MemeLocalArchiveRepository;
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/presentation/feed/meme_unified_feed.dart'
    show MemeFeedRow, buildMemeFeedLoad;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hakaton_moskova_app/data/repository/meme_supabase_assets_repository.dart';
import 'package:hakaton_moskova_app/presentation/screens/archive_item_analysis_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/screens/my_publications_analytics_full_screen.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';

/// Son başarılı feed; sekme değişiminde anında göster (Supabase bekleme yok).
List<MemeFeedRow> _analysisFeedRowCache = const [];
bool _analysisFeedCacheTimeout = false;
bool _analysisFeedCacheSupabaseFailed = false;

/// Arşiv ile aynı medya seti; tıklanınca paylaşım metrik analizi.
class TelegramAnalysisScreen extends StatefulWidget {
  const TelegramAnalysisScreen({super.key});

  @override
  State<TelegramAnalysisScreen> createState() => _TelegramAnalysisScreenState();
}

class _TelegramAnalysisScreenState extends State<TelegramAnalysisScreen> {
  final _repo = MemeLocalArchiveRepository.instance;
  late final MemeSupabaseAssetsRepository _cloudRepo =
      MemeSupabaseAssetsRepository(Supabase.instance.client);

  List<MemeFeedRow> _rows = const [];
  /// Arka planda tazelenecek; tam ekran spinner yok, üstte ince progress.
  bool _feedRefreshing = false;
  bool _loadTimeout = false;
  bool _supabaseFailed = false;

  @override
  void initState() {
    super.initState();
    if (_analysisFeedRowCache.isNotEmpty) {
      _rows = List<MemeFeedRow>.from(_analysisFeedRowCache);
      _loadTimeout = _analysisFeedCacheTimeout;
      _supabaseFailed = _analysisFeedCacheSupabaseFailed;
    }
    _repo.onChanged.addListener(_reload);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(
          TelegramPublishedLogRepository.instance.ensureLoaded().catchError(
            (Object e, StackTrace s) {
              debugPrint('analysis ensureLoaded: $e\n$s');
            },
          ),
        );
        unawaited(_reload());
      }
    });
  }

  @override
  void dispose() {
    _repo.onChanged.removeListener(_reload);
    super.dispose();
  }

  void _updateRowsAndCache(
    List<MemeFeedRow> rows, {
    required bool loadTimeout,
    required bool supabaseFailed,
  }) {
    _rows = rows;
    _loadTimeout = loadTimeout;
    _supabaseFailed = supabaseFailed;
    _analysisFeedRowCache = List<MemeFeedRow>.from(_rows);
    _analysisFeedCacheTimeout = _loadTimeout;
    _analysisFeedCacheSupabaseFailed = _supabaseFailed;
  }

  /// Arşiv ile aynı: önce yerel indeks anında, sonra bulut satırları birleşir.
  Future<void> _reload() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _feedRefreshing = _rows.isEmpty;
    });

    var localList = const <MemeArchiveEntry>[];
    var loadTimedOut = false;
    try {
      final r = await _repo.loadEntries();
      localList = r.entries;
      loadTimedOut = r.loadEntriesTimedOut;
    } catch (e, st) {
      debugPrint('TelegramAnalysisScreen._reload local: $e\n$st');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _updateRowsAndCache(
        buildMemeFeedLoad(
          localList: localList,
          cloudList: const [],
          loadEntriesTimedOut: loadTimedOut,
          supabaseFailed: false,
        ).rows,
        loadTimeout: loadTimedOut,
        supabaseFailed: false,
      );
      _feedRefreshing = true;
    });

    var cloud = const <SupabaseMemeAssetEntry>[];
    var supabaseFailed = false;
    try {
      cloud = await _cloudRepo.listAccountAssets();
    } catch (e, st) {
      debugPrint('TelegramAnalysisScreen._reload cloud: $e\n$st');
      supabaseFailed = true;
    }

    try {
      final r2 = await _repo.loadEntries();
      localList = r2.entries;
      loadTimedOut = r2.loadEntriesTimedOut;
    } catch (e, st) {
      debugPrint('TelegramAnalysisScreen._reload local refresh: $e\n$st');
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _updateRowsAndCache(
        buildMemeFeedLoad(
          localList: localList,
          cloudList: cloud,
          loadEntriesTimedOut: loadTimedOut,
          supabaseFailed: supabaseFailed,
        ).rows,
        loadTimeout: loadTimedOut,
        supabaseFailed: supabaseFailed,
      );
      _feedRefreshing = false;
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _shortDate(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)} · ${_two(d.hour)}:${_two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        _repo.onChanged,
        TelegramPublishedLogRepository.instance.onChanged,
      ]),
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_feedRefreshing)
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                color: MemeopsColors.iosBlue,
              ),
            if (_loadTimeout || _supabaseFailed)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
                child: Text(
                  _loadTimeout
                      ? l10n.archiveListLoadError
                      : l10n.archiveSupabaseLoadError,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    fontSize: 11,
                    color: MemeopsColors.iosBlueBright.withValues(alpha: 0.9),
                  ),
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _reload,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: MemeopsGlassSurface(
                          padding: EdgeInsets.zero,
                          borderRadius: MemeopsRadii.md,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 4,
                            ),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const MyPublicationsAnalyticsFullScreen(),
                                ),
                              );
                            },
                            leading: Icon(
                              Icons.insights_rounded,
                              color: MemeopsColors.iosBlueBright
                                  .withValues(alpha: 0.95),
                            ),
                            title: Text(
                              l10n.myPubOpenFullAnalytics,
                              style: MemeopsTextStyles.subtitle(context)
                                  .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Text(
                              l10n.myPubOpenFullAnalyticsSubtitle,
                              style: MemeopsTextStyles.caption(context).copyWith(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.5),
                                height: 1.3,
                              ),
                            ),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white.withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_rows.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: Text(
                              l10n.archiveEmpty,
                              textAlign: TextAlign.center,
                              style: MemeopsTextStyles.caption(context),
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.78,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final row = _rows[i];
                              return _FeedTile(
                                row: row,
                                l10n: l10n,
                                shortDate: row.isSupabase
                                    ? _shortDate(row.supabase!.createdAt)
                                    : _shortDate(row.local!.createdAt),
                                onTap: () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ArchiveItemAnalysisScreen(
                                        local: row.local,
                                        cloud: row.supabase,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                            childCount: _rows.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeedTile extends StatelessWidget {
  const _FeedTile({
    required this.row,
    required this.l10n,
    required this.shortDate,
    required this.onTap,
  });

  final MemeFeedRow row;
  final AppLocalizations l10n;
  final String shortDate;
  final VoidCallback onTap;

  String? _line() {
    if (row.isSupabase) {
      final t = (row.supabase!.briefLine ?? '').trim();
      return t.isNotEmpty ? t : null;
    }
    final c = (row.local!.caption ?? '').trim();
    return c.isNotEmpty ? c : null;
  }

  @override
  Widget build(BuildContext context) {
    final line = _line();
    return MemeopsGlassSurface(
      padding: EdgeInsets.zero,
      borderRadius: MemeopsRadii.sm,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MemeopsRadii.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(MemeopsRadii.sm - 1),
                  ),
                  child: row.isSupabase
                      ? _CloudThumb(s: row.supabase!)
                      : _AnalysisLocalThumb(e: row.local!),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortDate,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: MemeopsColors.iosBlueBright
                            .withValues(alpha: 0.95),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (line != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        line,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.5,
                          height: 1.1,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnalysisLocalThumb extends StatefulWidget {
  const _AnalysisLocalThumb({required this.e});

  final MemeArchiveEntry e;

  @override
  State<_AnalysisLocalThumb> createState() => _AnalysisLocalThumbState();
}

class _AnalysisLocalThumbState extends State<_AnalysisLocalThumb> {
  static final _repo = MemeLocalArchiveRepository.instance;
  late Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = _repo.fileFor(widget.e);
  }

  @override
  void didUpdateWidget(covariant _AnalysisLocalThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.e.id != widget.e.id) {
      _fileFuture = _repo.fileFor(widget.e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.sizeOf(context).width - 24) / 2;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (w * dpr).round();

    if (widget.e.kind == MemeArchiveKind.video) {
      return const ColoredBox(
        color: Color(0xFF1a2235),
        child: Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
      );
    }
    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ColoredBox(color: Color(0xFF1a2235));
        }
        final f = snap.data;
        if (f == null || !f.existsSync()) {
          return const ColoredBox(
            color: Color(0xFF1a2235),
            child: Icon(Icons.broken_image_outlined, color: Colors.white38),
          );
        }
        return Image.file(
          f,
          fit: BoxFit.cover,
          cacheWidth: cacheW,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}

class _CloudThumb extends StatelessWidget {
  const _CloudThumb({required this.s});

  final SupabaseMemeAssetEntry s;

  @override
  Widget build(BuildContext context) {
    if (s.isVideo) {
      return const ColoredBox(
        color: Color(0xFF1a2235),
        child: Center(
          child: Icon(
            Icons.play_circle_fill_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
      );
    }
    final w = (MediaQuery.sizeOf(context).width - 24) / 2;
    final cacheW = (w * MediaQuery.devicePixelRatioOf(context)).round();
    return Image.network(
      s.fileUrl,
      fit: BoxFit.cover,
      cacheWidth: cacheW,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (c, e, st) => const ColoredBox(
        color: Color(0xFF1a2235),
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white38),
      ),
    );
  }
}
