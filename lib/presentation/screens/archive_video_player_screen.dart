import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/archive_detail_publish_section.dart';
import 'package:video_player/video_player.dart';

/// Arşivden yerel .mp4 veya Supabase’deki public video URL’ini tam ekran oynatır.
class ArchiveVideoPlayerScreen extends StatefulWidget {
  const ArchiveVideoPlayerScreen({
    super.key,
    this.file,
    this.networkUri,
    required this.title,
    this.caption,
    this.localArchiveId,
    this.supabaseVersionId,
    this.sourceMemeBriefId,
  }) : assert(
          (file != null) ^ (networkUri != null),
          'Yerel dosya veya ağ URL’sinden yalnızca biri verilmelidir',
        );

  final File? file;
  final Uri? networkUri;
  final String title;
  final String? caption;
  final String? localArchiveId;
  final String? supabaseVersionId;
  final String? sourceMemeBriefId;

  @override
  State<ArchiveVideoPlayerScreen> createState() =>
      _ArchiveVideoPlayerScreenState();
}

class _ArchiveVideoPlayerScreenState extends State<ArchiveVideoPlayerScreen> {
  final _publishKey = GlobalKey<ArchiveDetailPublishSectionState>();
  VideoPlayerController? _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final VideoPlayerController c;
      if (widget.file != null) {
        c = VideoPlayerController.file(widget.file!);
      } else {
        c = VideoPlayerController.networkUrl(widget.networkUri!);
      }
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      c.setLooping(true);
      c.play();
      setState(() {
        _controller = c;
        _ready = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    await _publishKey.currentState?.submitPublish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: MemeopsColors.bgMid,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.25),
        foregroundColor: Colors.white,
        title: Text(widget.title, style: const TextStyle(fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: l10n.archiveShare,
            onPressed: _share,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            child: AspectRatio(
              aspectRatio: _controller?.value.isInitialized == true
                  ? _controller!.value.aspectRatio
                  : 9 / 16,
              child: _error != null
                  ? Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Video oynatılamadı: $_error',
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : !_ready || _controller == null
                      ? Container(
                          color: Colors.black,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            VideoPlayer(_controller!),
                            _PlayOverlay(controller: _controller!),
                          ],
                        ),
            ),
          ),
          if (_controller != null && _ready) ...[
            const SizedBox(height: 10),
            VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: MemeopsColors.iosBlueBright,
                bufferedColor: Colors.white.withValues(alpha: 0.25),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
              ),
            ),
          ],
          const SizedBox(height: 20),
          ArchiveDetailPublishSection(
            key: _publishKey,
            sourceLabel: widget.title,
            initialCaption: widget.caption,
            mediaKind: MemeArchiveKind.video,
            localFile: widget.file,
            networkUrl: widget.networkUri?.toString(),
            localArchiveId: widget.localArchiveId,
            supabaseVersionId: widget.supabaseVersionId,
            sourceMemeBriefId: widget.sourceMemeBriefId,
          ),
        ],
      ),
    );
  }
}

class _PlayOverlay extends StatefulWidget {
  const _PlayOverlay({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_PlayOverlay> createState() => _PlayOverlayState();
}

class _PlayOverlayState extends State<_PlayOverlay> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final playing = widget.controller.value.isPlaying;
    return GestureDetector(
      onTap: () {
        playing ? widget.controller.pause() : widget.controller.play();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: playing ? 0 : 1,
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 44,
          ),
        ),
      ),
    );
  }
}
