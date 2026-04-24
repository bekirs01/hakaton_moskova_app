import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/utils/archive_share.dart';
import 'package:video_player/video_player.dart';

/// Yerel arşivden gelen .mp4 dosyasını tam ekran oynatır.
class ArchiveVideoPlayerScreen extends StatefulWidget {
  const ArchiveVideoPlayerScreen({
    super.key,
    required this.file,
    required this.title,
    this.caption,
  });

  final File file;
  final String title;
  final String? caption;

  @override
  State<ArchiveVideoPlayerScreen> createState() =>
      _ArchiveVideoPlayerScreenState();
}

class _ArchiveVideoPlayerScreenState extends State<ArchiveVideoPlayerScreen> {
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
      final c = VideoPlayerController.file(widget.file);
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
    await shareArchiveFile(
      context,
      file: widget.file,
      sourceLabel: widget.title,
      kind: MemeArchiveKind.video,
      caption: widget.caption,
    );
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
          if (widget.caption != null && widget.caption!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              widget.caption!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
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
