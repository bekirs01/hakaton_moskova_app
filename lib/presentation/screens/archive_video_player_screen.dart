import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/archive_detail_publish_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

/// Arşivden yerel .mp4 veya Supabase’deki public video URL’ini tam ekran oynatır.
class ArchiveVideoPlayerScreen extends StatefulWidget {
  const ArchiveVideoPlayerScreen({
    super.key,
    this.file,
    this.networkUri,
    this.storagePath,
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

  /// Ağ oynatma başarısız olursa (veya public URL bozuksa) imzalı URL denemesi için.
  final String? storagePath;
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
  Object? _playError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.file != null) {
        final c = VideoPlayerController.file(widget.file!);
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
        return;
      }
      await _playNetworkUri(widget.networkUri!);
    } catch (e, st) {
      debugPrint('ArchiveVideoPlayerScreen init: $e\n$st');
      if (!mounted) {
        return;
      }
      setState(() => _playError = e);
    }
  }

  Future<void> _playNetworkUri(Uri uri) async {
    try {
      final c = VideoPlayerController.networkUrl(uri);
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
      final sp = widget.storagePath?.trim();
      if (sp != null && sp.isNotEmpty && Supabase.instance.client.auth.currentSession != null) {
        try {
          final signed = await Supabase.instance.client.storage
              .from('meme-assets')
              .createSignedUrl(sp, 60 * 30);
          final c2 = VideoPlayerController.networkUrl(Uri.parse(signed));
          await c2.initialize();
          if (!mounted) {
            await c2.dispose();
            return;
          }
          c2.setLooping(true);
          c2.play();
          setState(() {
            _controller = c2;
            _ready = true;
          });
          return;
        } catch (e2, st2) {
          debugPrint('ArchiveVideoPlayer signed URL fallback: $e2\n$st2');
        }
      }
      rethrow;
    }
  }

  String _userFacingError(AppLocalizations l10n) {
    final e = _playError;
    if (e is PlatformException) {
      final m = '${e.message ?? ''} ${e.details ?? ''}'.toLowerCase();
      if (m.contains('hostname') ||
          m.contains('could not be found') ||
          m.contains('network') ||
          m.contains('-1003')) {
        return l10n.errNetworkUser;
      }
    }
    return l10n.errNetworkUser;
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
              child: _playError != null
                  ? Container(
                      color: Colors.black,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.archiveVideoErrorTitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _userFacingError(l10n),
                            style: const TextStyle(
                              color: Colors.white70,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (kDebugMode) ...[
                            const SizedBox(height: 12),
                            Text(
                              _playError.toString(),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
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
