import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart'
    show MemeArchiveEntry, MemeArchiveKind, MemeLocalArchiveRepository;
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/presentation/feed/meme_unified_feed.dart';
import 'package:hakaton_moskova_app/presentation/screens/archive_item_analysis_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';

/// Arşiv ile aynı medya seti; tıklanınca paylaşım metrik analizi.
class TelegramAnalysisScreen extends StatefulWidget {
  const TelegramAnalysisScreen({super.key});

  @override
  State<TelegramAnalysisScreen> createState() => _TelegramAnalysisScreenState();
}

class _TelegramAnalysisScreenState extends State<TelegramAnalysisScreen> {
  final _repo = MemeLocalArchiveRepository.instance;

  List<MemeFeedRow> _rows = const [];
  bool _loading = true;
  bool _loadTimeout = false;
  bool _supabaseFailed = false;

  @override
  void initState() {
    super.initState();
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

  Future<void> _reload() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _loadTimeout = false;
      _supabaseFailed = false;
    });
    MemeFeedLoad? load;
    try {
      load = await loadMemeUnifiedFeed();
    } catch (e, st) {
      debugPrint('TelegramAnalysisScreen._reload: $e\n$st');
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _rows = load?.rows ?? const [];
      _loading = false;
      _loadTimeout = load?.loadEntriesTimedOut ?? false;
      _supabaseFailed = load?.supabaseFailed ?? true;
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
        if (_loading) {
          return const Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              child: _rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.archiveEmpty,
                          textAlign: TextAlign.center,
                          style: MemeopsTextStyles.caption(context),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _reload,
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.78,
                        ),
                        itemCount: _rows.length,
                        itemBuilder: (context, i) {
                          final row = _rows[i];
                          return _FeedTile(
                            row: row,
                            repo: _repo,
                            l10n: l10n,
                            shortDate: row.isSupabase
                                ? _shortDate(row.supabase!.createdAt)
                                : _shortDate(row.local!.createdAt),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => ArchiveItemAnalysisScreen(
                                    local: row.local,
                                    cloud: row.supabase,
                                  ),
                                ),
                              );
                            },
                          );
                        },
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
    required this.repo,
    required this.l10n,
    required this.shortDate,
    required this.onTap,
  });

  final MemeFeedRow row;
  final MemeLocalArchiveRepository repo;
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
                      : _LocalThumb(
                          e: row.local!,
                          repo: repo,
                        ),
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

class _LocalThumb extends StatelessWidget {
  const _LocalThumb({
    required this.e,
    required this.repo,
  });

  final MemeArchiveEntry e;
  final MemeLocalArchiveRepository repo;

  @override
  Widget build(BuildContext context) {
    if (e.kind == MemeArchiveKind.video) {
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
      future: repo.fileFor(e),
      builder: (context, snap) {
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
    return Image.network(
      s.fileUrl,
      fit: BoxFit.cover,
      errorBuilder: (c, e, st) => const ColoredBox(
        color: Color(0xFF1a2235),
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white38),
      ),
    );
  }
}
