import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_step_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Görsel üretildikten sonra aynı memi Sora 2 ile kısa bir video klibe çevirir.
/// Sora yalnızca 4 / 8 / 12 sn destekler (3 / 5 yoktur); bunları sunuyoruz.
class VideoGenerateSection extends StatefulWidget {
  const VideoGenerateSection({
    super.key,
    required this.memeBriefId,
    required this.caption,
    required this.sourceLabel,
    required this.stepNumber,
  });

  final String memeBriefId;
  final String? caption;
  final String sourceLabel;
  final int stepNumber;

  @override
  State<VideoGenerateSection> createState() => _VideoGenerateSectionState();
}

class _VideoGenerateSectionState extends State<VideoGenerateSection> {
  final _api = MemeopsApiClient(Supabase.instance.client);
  bool _busy = false;
  String? _videoUrl;
  String? _err;
  String? _runningSeconds;
  int? _savedSeconds;

  Future<void> _run(String seconds) async {
    setState(() {
      _busy = true;
      _err = null;
      _videoUrl = null;
      _runningSeconds = seconds;
    });
    try {
      final r = await _api.generateVideo(widget.memeBriefId, seconds: seconds);
      final url = r.fileUrl;
      final finalSecs = int.tryParse(r.seconds ?? seconds) ?? int.parse(seconds);
      if (url == null) {
        throw StateError('empty_file_url');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _videoUrl = url;
        _savedSeconds = finalSecs;
      });
      final loc = lookupAppLocalizations(AppLocaleController.instance.locale);
      unawaited(
        MemeLocalArchiveRepository.instance
            .addFromNetworkUrl(
              imageUrl: url,
              caption: widget.caption,
              sourceLabel: '${widget.sourceLabel} · Video ${finalSecs}s',
              kind: MemeArchiveKind.video,
              durationSeconds: finalSecs,
            )
            .catchError((Object e, StackTrace st) {
              debugPrint(loc.archiveDebugSkip(e.toString()));
            }),
      );
    } on MemeopsApiException catch (e) {
      if (!mounted) return;
      setState(() => _err = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = memeopsUnexpectedErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _runningSeconds = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MemeopsGlassSurface(
      padding: const EdgeInsets.all(20),
      child: MemeopsStepSection(
        step: widget.stepNumber,
        title: 'Memeyi videoya çevir',
        subtitle:
            'Memeyi 4, 8 veya 12 sn’lik kısa bir klibe dönüştür. Üretilen video arşive kaydedilir.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_err != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(MemeopsRadii.sm),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  _err!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(child: _durationBtn('4')),
                const SizedBox(width: 8),
                Expanded(child: _durationBtn('8')),
                const SizedBox(width: 8),
                Expanded(child: _durationBtn('12')),
              ],
            ),
            if (_busy && _runningSeconds != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sora ile $_runningSeconds sn video üretiliyor… '
                      'Bu işlem 1-3 dakika sürebilir.',
                      style: MemeopsTextStyles.caption(context),
                    ),
                  ),
                ],
              ),
            ],
            if (_videoUrl != null && _savedSeconds != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: MemeopsColors.iosBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(MemeopsRadii.sm),
                  border: Border.all(
                    color: MemeopsColors.iosBlue.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$_savedSeconds sn video arşive kaydedildi. Arşiv sekmesinden oynatabilirsin.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _durationBtn(String secs) {
    final disabled = _busy;
    final isRunning = _runningSeconds == secs;
    return FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: isRunning
            ? MemeopsColors.iosBlue
            : Colors.white.withValues(alpha: 0.08),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MemeopsRadii.sm),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ),
      onPressed: disabled ? null : () => _run(secs),
      child: Text('$secs sn'),
    );
  }
}
