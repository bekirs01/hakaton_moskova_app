import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/presentation/feed/meme_unified_feed.dart'
    show MemeFeedLoad, loadMemeUnifiedFeed;
import 'package:hakaton_moskova_app/presentation/screens/publication_detail_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/telegram_published_analytics_overview.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Cihaz paylaşım günlüğü: özet, grafikler, gönderi önizlemesi + [PublicationDetailScreen].
class MyPublicationsAnalyticsFullScreen extends StatefulWidget {
  const MyPublicationsAnalyticsFullScreen({super.key});

  @override
  State<MyPublicationsAnalyticsFullScreen> createState() =>
      _MyPublicationsAnalyticsFullScreenState();
}

class _MyPublicationsAnalyticsFullScreenState
    extends State<MyPublicationsAnalyticsFullScreen> {
  final _repo = MemeLocalArchiveRepository.instance;
  Map<String, MemeArchiveEntry> _localById = {};
  Map<String, SupabaseMemeAssetEntry> _cloudById = {};
  bool _loading = true;
  String? _loadErr;

  @override
  void initState() {
    super.initState();
    unawaited(_loadThumbnails());
  }

  Future<void> _loadThumbnails() async {
    setState(() {
      _loading = true;
      _loadErr = null;
    });
    try {
      final le = await _repo.loadEntries();
      MemeFeedLoad? feed;
      try {
        feed = await loadMemeUnifiedFeed();
      } catch (e, st) {
        debugPrint('my_publications full feed: $e\n$st');
      }
      final cloud = <String, SupabaseMemeAssetEntry>{};
      if (feed != null) {
        for (final r in feed.rows) {
          if (r.isSupabase && r.supabase != null) {
            cloud[r.supabase!.id] = r.supabase!;
          }
        }
      }
      final loc = {for (final e in le.entries) e.id: e};
      if (mounted) {
        setState(() {
          _localById = loc;
          _cloudById = cloud;
          _loading = false;
        });
      }
    } catch (e, st) {
      debugPrint('my_publications full: $e\n$st');
      if (mounted) {
        setState(() {
          _loadErr = '$e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: TelegramPublishedLogRepository.instance.onChanged,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: MemeopsColors.bgMid,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            title: Text(
              l10n.myPubFullPageTitle,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: _loading
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadThumbnails,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      if (_loadErr != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _loadErr!,
                              style: MemeopsTextStyles.caption(context)
                                  .copyWith(color: Colors.orangeAccent),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: TelegramPublishedAnalyticsOverview(
                            entries: TelegramPublishedLogRepository.instance
                                .items,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            l10n.myPubPerPostListTitle,
                            style: MemeopsTextStyles.sectionTitle(context)
                                .copyWith(
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, i) {
                            final list = _sortedEntries();
                            if (i >= list.length) {
                              return null;
                            }
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                10,
                                0,
                                10,
                                8,
                              ),
                              child: _entryCard(
                                context,
                                l10n,
                                list[i],
                              ),
                            );
                          },
                          childCount: _sortedEntries().length,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
        );
      },
    );
  }

  List<TelegramPublishedEntry> _sortedEntries() {
    final list = List<TelegramPublishedEntry>.from(
      TelegramPublishedLogRepository.instance.items,
    );
    list.sort((a, b) {
      final av = a.views;
      final bv = b.views;
      if (av == null && bv == null) {
        return b.publishedAt.compareTo(a.publishedAt);
      }
      if (av == null) {
        return 1;
      }
      if (bv == null) {
        return -1;
      }
      if (bv != av) {
        return bv.compareTo(av);
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return list;
  }

  Widget _entryCard(
    BuildContext context,
    AppLocalizations l10n,
    TelegramPublishedEntry e,
  ) {
    final df = DateFormat('dd.MM.yyyy · HH:mm');
    return MemeopsGlassSurface(
      padding: EdgeInsets.zero,
      borderRadius: MemeopsRadii.md,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => PublicationDetailScreen(entry: e),
              ),
            );
          },
          borderRadius: BorderRadius.circular(MemeopsRadii.md),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _thumb(l10n, e),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        e.views != null
                            ? l10n.analysisViewCount(e.views!)
                            : l10n.myPubViewUnknown,
                        style: MemeopsTextStyles.subtitle(context).copyWith(
                          color: MemeopsColors.iosBlueBright,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _platformLine(l10n, e),
                        style: MemeopsTextStyles.caption(context).copyWith(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        df.format(e.publishedAt),
                        style: MemeopsTextStyles.caption(context).copyWith(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      if ((e.caption ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _clip((e.caption ?? '').trim(), 90),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: MemeopsTextStyles.caption(context).copyWith(
                            fontSize: 12.5,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _platformLine(AppLocalizations l10n, TelegramPublishedEntry e) {
    if (e.isTelegram) {
      return l10n.analysisPlatformTelegram;
    }
    if (e.isVk) {
      return l10n.myPubPlatformVkTr;
    }
    return l10n.myPubSummaryDzenLabel;
  }

  String _clip(String s, int m) {
    if (s.length <= m) {
      return s;
    }
    return '${s.substring(0, m)}…';
  }

  Widget _thumb(AppLocalizations l10n, TelegramPublishedEntry e) {
    const size = 80.0;
    final r = BorderRadius.circular(MemeopsRadii.sm);
    final lid = e.localArchiveId;
    if (lid != null) {
      final m = _localById[lid];
      if (m != null) {
        if (m.kind == MemeArchiveKind.video) {
          return _videoBox(size, r);
        }
        return ClipRRect(
          borderRadius: r,
          child: SizedBox(
            width: size,
            height: size,
            child: FutureBuilder<File>(
              future: _repo.fileFor(m),
              builder: (context, snap) {
                final f = snap.data;
                if (f == null || !f.existsSync()) {
                  return _placeholder(r, l10n);
                }
                return Image.file(
                  f,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  errorBuilder: (context, error, stackTrace) =>
                      _placeholder(r, l10n),
                );
              },
            ),
          ),
        );
      }
    }
    final sid = e.supabaseVersionId;
    if (sid != null) {
      final c = _cloudById[sid];
      if (c != null) {
        if (c.isVideo) {
          return _videoBox(size, r);
        }
        return ClipRRect(
          borderRadius: r,
          child: SizedBox(
            width: size,
            height: size,
            child: Image.network(
              c.fileUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _placeholder(r, l10n),
            ),
          ),
        );
      }
    }
    return _placeholder(r, l10n);
  }

  Widget _videoBox(double s, BorderRadius r) {
    return ClipRRect(
      borderRadius: r,
      child: ColoredBox(
        color: const Color(0xFF1a2235),
        child: SizedBox(
          width: s,
          height: s,
          child: const Center(
            child: Icon(
              Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(BorderRadius r, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        width: 80,
        height: 80,
        child: ColoredBox(
          color: const Color(0xFF1a2235),
          child: Center(
            child: Text(
              l10n.myPubPerPostNoThumb,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
