import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/supabase_meme_asset_entry.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/screens/archive_video_player_screen.dart';
import 'package:hakaton_moskova_app/presentation/screens/publication_detail_screen.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

/// Arşiv satırı → kanal metrikleri varsa [PublicationDetailScreen], yoksa önizleme.
class ArchiveItemAnalysisScreen extends StatefulWidget {
  const ArchiveItemAnalysisScreen({
    super.key,
    this.local,
    this.cloud,
  }) : assert(
          (local == null) != (cloud == null),
          'Yerel veya buluttan yalnızca biri dolu olmalı',
        );

  final MemeArchiveEntry? local;
  final SupabaseMemeAssetEntry? cloud;

  @override
  State<ArchiveItemAnalysisScreen> createState() =>
      _ArchiveItemAnalysisScreenState();
}

class _ArchiveItemAnalysisScreenState extends State<ArchiveItemAnalysisScreen> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await TelegramPublishedLogRepository.instance.ensureLoaded();
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final log = TelegramPublishedLogRepository.instance;
    final pub = log.findFuzzyForArchiveItem(
      local: widget.local,
      cloud: widget.cloud,
    );
    if (pub != null) {
      return PublicationDetailScreen(entry: pub);
    }
    return _UnsharedBody(local: widget.local, cloud: widget.cloud);
  }
}

class _UnsharedBody extends StatelessWidget {
  const _UnsharedBody({this.local, this.cloud});

  final MemeArchiveEntry? local;
  final SupabaseMemeAssetEntry? cloud;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isVid = local != null
        ? local!.kind == MemeArchiveKind.video
        : cloud!.isVideo;
    return Scaffold(
      backgroundColor: MemeopsColors.bgMid,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.3),
        foregroundColor: Colors.white,
        title: Text(
          l10n.tabAnalysis,
          style: const TextStyle(fontSize: 17),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            l10n.analysisNotSharedTitle,
            style: MemeopsTextStyles.sectionTitle(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.analysisNotSharedBody,
            style: MemeopsTextStyles.caption(context).copyWith(height: 1.4),
          ),
          const SizedBox(height: 20),
          if (local != null)
            _LocalPreview(
              e: local!,
            )
          else
            _CloudPreview(c: cloud!, isVideo: isVid),
        ],
      ),
    );
  }
}

class _LocalPreview extends StatelessWidget {
  const _LocalPreview({required this.e});

  final MemeArchiveEntry e;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: MemeLocalArchiveRepository.instance.fileFor(e),
      builder: (context, snap) {
        final f = snap.data;
        if (f == null || !f.existsSync()) {
          return Text(AppLocalizations.of(context).archiveFileMissing);
        }
        if (e.kind == MemeArchiveKind.video) {
          return _OpenPlayerButton(
            onPressed: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ArchiveVideoPlayerScreen(
                    file: f,
                    title: e.sourceLabel,
                    caption: e.caption,
                    localArchiveId: e.id,
                  ),
                ),
              );
            },
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(MemeopsRadii.md),
          child: Image.file(
            f,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

class _CloudPreview extends StatelessWidget {
  const _CloudPreview({required this.c, required this.isVideo});

  final SupabaseMemeAssetEntry c;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    if (isVideo) {
      return _OpenPlayerButton(
        onPressed: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => ArchiveVideoPlayerScreen(
                networkUri: Uri.parse(c.fileUrl),
                title: AppLocalizations.of(context).tabArchive,
                caption: c.briefLine,
                supabaseVersionId: c.id,
              ),
            ),
          );
        },
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(MemeopsRadii.md),
      child: Image.network(
        c.fileUrl,
        fit: BoxFit.contain,
        loadingBuilder: (c, w, p) {
          if (p == null) {
            return w;
          }
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class _OpenPlayerButton extends StatelessWidget {
  const _OpenPlayerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        child: Container(
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MemeopsColors.iosBlue.withValues(alpha: 0.4),
                Colors.black.withValues(alpha: 0.5),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.analysisOpenPreview,
                style: MemeopsTextStyles.caption(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
