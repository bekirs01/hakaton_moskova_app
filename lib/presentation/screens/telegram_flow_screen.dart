import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/repository/meme_briefs_repository.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/domain/pipeline_stage.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/state/telegram_analysis_store.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/widgets/error_retry_card.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_step_section.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_variant_pick_tile.dart';
import 'package:hakaton_moskova_app/presentation/widgets/pipeline_progress_bar.dart';
import 'package:hakaton_moskova_app/presentation/widgets/video_generate_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelegramFlowScreen extends StatefulWidget {
  const TelegramFlowScreen({super.key});

  @override
  State<TelegramFlowScreen> createState() => _TelegramFlowScreenState();
}

String _titleFromChannelUrl(AppLocalizations l10n, String raw) {
  final u = () {
    try {
      return Uri.parse(raw.contains('://') ? raw : 'https://$raw');
    } catch (_) {
      return null;
    }
  }();
  if (u == null) {
    return l10n.telegramChannelDefault;
  }
  final last = u.pathSegments.isNotEmpty
      ? u.pathSegments.last.replaceAll('@', '')
      : u.host;
  var t = 'TG $last';
  if (t.length < 3) {
    t = l10n.telegramChannelDefault;
  }
  return t.length > 200 ? t.substring(0, 200) : t;
}

class _TelegramFlowScreenState extends State<TelegramFlowScreen> {
  final _link = TextEditingController();
  final _api = MemeopsApiClient(Supabase.instance.client);
  final _briefs = MemeBriefsRepository(Supabase.instance.client);
  late final PublicationPort _publish = createPublicationPort();

  TelegramPipelineStage _stage = TelegramPipelineStage.idle;
  String? _err;
  ChannelInsights? _insights;
  List<MemeBriefListItem> _variants = const [];
  MemeBriefListItem? _selected;
  String? _fileUrl;
  String? _lastInfo;

  double _t(TelegramPipelineStage s) {
    const n = 6.0;
    switch (s) {
      case TelegramPipelineStage.idle:
        return 0;
      case TelegramPipelineStage.inputReady:
        return 1 / n;
      case TelegramPipelineStage.fetchingInsights:
        return 2 / n;
      case TelegramPipelineStage.creatingProfession:
        return 3 / n;
      case TelegramPipelineStage.generatingSituations:
        return 4 / n;
      case TelegramPipelineStage.generatingImage:
        return 5 / n;
      case TelegramPipelineStage.savingResult:
        return 5.5 / n;
      case TelegramPipelineStage.done:
        return 1;
      case TelegramPipelineStage.error:
        return 0.25;
    }
  }

  String? _msg(AppLocalizations l10n, TelegramPipelineStage s) {
    switch (s) {
      case TelegramPipelineStage.fetchingInsights:
        return l10n.tgProgressFetching;
      case TelegramPipelineStage.creatingProfession:
        return l10n.tgProgressPreparing;
      case TelegramPipelineStage.generatingSituations:
        return l10n.tgProgressIdeas;
      case TelegramPipelineStage.generatingImage:
        return l10n.tgProgressImage;
      case TelegramPipelineStage.savingResult:
        return l10n.tgProgressSaving;
      default:
        return null;
    }
  }

  bool get _busy => {
    TelegramPipelineStage.fetchingInsights,
    TelegramPipelineStage.creatingProfession,
    TelegramPipelineStage.generatingSituations,
    TelegramPipelineStage.generatingImage,
    TelegramPipelineStage.savingResult,
  }.contains(_stage);

  Future<void> _analyze() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _err = null;
      _insights = null;
      _fileUrl = null;
      _selected = null;
      _variants = const [];
    });
    TelegramAnalysisStore.instance.set(null);
    final u = _link.text.trim();
    if (u.length < 8) {
      setState(() {
        _err = l10n.telegramErrShortLink;
        _stage = TelegramPipelineStage.error;
      });
      return;
    }
    setState(() => _stage = TelegramPipelineStage.fetchingInsights);
    try {
      final ins = await _api.channelInsights(u);
      setState(() {
        _insights = ins;
        _stage = TelegramPipelineStage.inputReady;
      });
      TelegramAnalysisStore.instance.set(ins);
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = TelegramPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = memeopsUnexpectedErrorMessage(e);
        _stage = TelegramPipelineStage.error;
      });
    }
  }

  Future<void> _runBriefBatch() async {
    final l10n = AppLocalizations.of(context);
    final i = _insights;
    if (i == null) {
      return;
    }
    if (i.isOfflineStub) {
      setState(() {
        _err = l10n.telegramErrStubOffline;
        _stage = TelegramPipelineStage.error;
      });
      return;
    }

    setState(() {
      _err = null;
      _stage = TelegramPipelineStage.creatingProfession;
    });

    try {
      if (i.isTelethonLive) {
        setState(() => _stage = TelegramPipelineStage.generatingSituations);
        final list = await _api.persistTelegramVariants(i);
        if (list.length < 5) {
          setState(() {
            _err = l10n.telegramErrTooFewIdeas(list.length);
            _stage = TelegramPipelineStage.error;
          });
          return;
        }
        setState(() {
          _variants = list;
          _stage = TelegramPipelineStage.inputReady;
        });
        return;
      }

      final ctx = i.toProfessionContext();
      final pid = await _api.createProfession(
        title: _titleFromChannelUrl(l10n, i.channelUrl),
        description: ctx,
        futureContext: l10n.telegramFutureContext,
      );
      setState(() {
        _stage = TelegramPipelineStage.generatingSituations;
      });
      await _api.generateMemeBriefs(pid);
      final list = await _briefs.listForProfession(pid);
      if (list.isEmpty) {
        setState(() {
          _err = l10n.telegramErrNoIdeas;
          _stage = TelegramPipelineStage.error;
        });
        return;
      }
      setState(() {
        _variants = list;
        _stage = TelegramPipelineStage.inputReady;
      });
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = TelegramPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = memeopsUnexpectedErrorMessage(e);
        _stage = TelegramPipelineStage.error;
      });
    }
  }

  Future<void> _image() async {
    final l10n = AppLocalizations.of(context);
    if (_selected == null) {
      return;
    }
    setState(() => _stage = TelegramPipelineStage.generatingImage);
    try {
      final r = await _api.generateImage(_selected!.id);
      setState(() {
        _fileUrl = r.fileUrl;
        _lastInfo = r.assetVersionId;
        _stage = TelegramPipelineStage.savingResult;
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) {
        setState(() => _stage = TelegramPipelineStage.done);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.telegramSnackSaved,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 4),
          ),
        );
        final archiveUrl = r.fileUrl!;
        final archiveCaption = _selected?.displayLine;
        final loc = lookupAppLocalizations(AppLocaleController.instance.locale);
        unawaited(
          MemeLocalArchiveRepository.instance
              .addFromNetworkUrl(
                imageUrl: archiveUrl,
                caption: archiveCaption,
                sourceLabel: loc.telegramSourceLabel,
              )
              .catchError((Object e, StackTrace st) {
                debugPrint(loc.archiveDebugSkip(e.toString()));
              }),
        );
      }
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = TelegramPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = memeopsUnexpectedErrorMessage(e);
        _stage = TelegramPipelineStage.error;
      });
    }
  }

  void _openPublish() {
    final l10n = AppLocalizations.of(context);
    final f = _publish.publishMeme(imageUrl: _fileUrl, brief: _selected);
    f.then((r) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.comingSoon
                ? l10n.publicationComingSoon
                : (r.message?.isNotEmpty == true ? r.message! : l10n.publicationDone),
          ),
        ),
      );
      unawaited(
        TelegramPublishedLogRepository.instance
            .recordIfPublished(
              r,
              caption: _selected?.displayLine,
              isVideo: false,
            )
            .catchError((Object e, StackTrace s) {
              debugPrint('recordIfPublished: $e\n$s');
            }),
      );
      if (_fileUrl != null) {
        final loc = lookupAppLocalizations(AppLocaleController.instance.locale);
        unawaited(
          MemeLocalArchiveRepository.instance
              .addFromNetworkUrl(
                imageUrl: _fileUrl!,
                caption: _selected?.displayLine,
                sourceLabel: loc.telegramSourceLabel,
              )
              .catchError((Object e, StackTrace st) {
                debugPrint(loc.archiveDebugSkip(e.toString()));
              }),
        );
      }
    });
  }

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final stub = _insights?.isOfflineStub == true;
    final live = _insights?.isTelethonLive == true;

    return ListView(
      padding: homeTabScrollPadding(),
      children: [
        MemeopsGlassSurface(
          padding: const EdgeInsets.all(20),
          child: MemeopsStepSection(
            step: 1,
            title: l10n.telegramStep1Title,
            subtitle: live
                ? l10n.telegramStep1SubtitleLive
                : l10n.telegramStep1SubtitleStub,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _link,
                  onChanged: (_) {
                    if (_stage == TelegramPipelineStage.idle) {
                      setState(() => _stage = TelegramPipelineStage.inputReady);
                    }
                  },
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.telegramLinkLabel,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _busy ? null : _analyze,
                  child: _stage == TelegramPipelineStage.fetchingInsights
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(l10n.telegramAnalyzing),
                          ],
                        )
                      : Text(l10n.telegramAnalyseButton),
                ),
              ],
            ),
          ),
        ),
        if (stub) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2D2419),
              borderRadius: BorderRadius.circular(MemeopsRadii.md),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.orange.shade200,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.telegramStubBanner,
                    style: TextStyle(
                      color: Colors.orange.shade50,
                      height: 1.35,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (_err != null) ...[
          const SizedBox(height: 12),
          ErrorRetryCard(message: _err!, onRetry: _analyze),
        ],
        if (_stage != TelegramPipelineStage.idle &&
            _stage != TelegramPipelineStage.error) ...[
          const SizedBox(height: 12),
          PipelineProgressBar(
            value: _t(_stage),
            message: _msg(l10n, _stage),
          ),
        ],
        if (_insights != null) ...[
          const SizedBox(height: 16),
          MemeopsGlassSurface(
            padding: const EdgeInsets.all(18),
            child: MemeopsStepSection(
              step: 2,
              title: l10n.telegramStep2Title,
              subtitle: l10n.telegramStep2Subtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      if (live)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B3D2F),
                            borderRadius: BorderRadius.circular(
                              MemeopsRadii.sm,
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFF2EE59D,
                              ).withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            l10n.telegramBadgeLive,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8EEDC5),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      if (stub)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2419),
                            borderRadius: BorderRadius.circular(
                              MemeopsRadii.sm,
                            ),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            l10n.telegramBadgeStub,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade100,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_insights!.channelTitle != null &&
                      _insights!.channelTitle!.isNotEmpty)
                    Text(
                      l10n.telegramInsightChannel(_insights!.channelTitle!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  Text(
                    l10n.telegramInsightTopic(_insights!.mainTopic),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.35,
                    ),
                  ),
                  if (_insights!.toneProfile != null &&
                      _insights!.toneProfile!.isNotEmpty)
                    Text(
                      l10n.telegramInsightStyle(_insights!.toneProfile!),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.35,
                      ),
                    ),
                  Text(
                    l10n.telegramInsightTone(_insights!.tone),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      height: 1.35,
                    ),
                  ),
                  Text(
                    l10n.telegramInsightThemes(
                      _insights!.recurringThemes.join(', '),
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  if (_insights!.postTypes.isNotEmpty)
                    Text(
                      l10n.telegramInsightPostMix(
                        _insights!.postTypes.join('; '),
                      ),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.35,
                      ),
                    ),
                  Text(
                    l10n.telegramInsightMediaTypes(
                      _insights!.mediaTypes.join(', '),
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      height: 1.35,
                    ),
                  ),
                  if (_insights!.mediaInsights.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.telegramMediaSection,
                      style: MemeopsTextStyles.caption(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ..._insights!.mediaInsights.map(
                      (e) => Text(
                        '· $e',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  if (_insights!.recentHighlights.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      l10n.telegramRecentSection,
                      style: MemeopsTextStyles.caption(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    ..._insights!.recentHighlights.map(
                      (e) => Text(
                        '· $e',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    l10n.telegramMemeAngles(
                      _insights!.memeableAngles.join(' · '),
                    ),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: (stub || _busy) ? null : _runBriefBatch,
                    child: Text(
                      live
                          ? l10n.telegramGenerateLive
                          : l10n.telegramGenerateHosted,
                    ),
                  ),
                  if (live)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.telegramLiveHint,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (_variants.isNotEmpty && _fileUrl == null) ...[
          const SizedBox(height: 16),
          MemeopsGlassSurface(
            padding: const EdgeInsets.all(20),
            child: MemeopsStepSection(
              step: 3,
              title: l10n.telegramStep3Title,
              subtitle: l10n.telegramStep3Subtitle,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ..._variants.asMap().entries.map(
                    (e) => MemeopsVariantPickTile(
                      index: e.key + 1,
                      line: e.value.displayLine,
                      selected: _selected?.id == e.value.id,
                      enabled: !_busy,
                      onTap: () {
                        setState(() {
                          _selected = e.value;
                        });
                      },
                    ),
                  ),
                  FilledButton(
                    onPressed: _busy || _selected == null ? null : _image,
                    child: _stage == TelegramPipelineStage.generatingImage
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.telegramGeneratingMeme),
                            ],
                          )
                        : Text(l10n.telegramGenerateMemeButton),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_fileUrl != null) ...[
          const SizedBox(height: 12),
          if (_lastInfo != null) Text(l10n.telegramAssetVersion(_lastInfo!)),
          ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            child: Image.network(
              _fileUrl!,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stack) =>
                  Center(child: Text(l10n.imageLoadError)),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _openPublish,
            child: Text(l10n.publishTitle),
          ),
          if (_selected != null) ...[
            const SizedBox(height: 16),
            VideoGenerateSection(
              memeBriefId: _selected!.id,
              caption: _selected?.displayLine,
              sourceLabel: l10n.telegramSourceLabel,
              stepNumber: 4,
            ),
          ],
        ],
      ],
    );
  }
}
