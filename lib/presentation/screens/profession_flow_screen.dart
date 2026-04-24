import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/repository/meme_briefs_repository.dart';
import 'package:hakaton_moskova_app/domain/pipeline_stage.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/state/profession_hint_store.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/widgets/error_retry_card.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_step_section.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_variant_pick_tile.dart';
import 'package:hakaton_moskova_app/presentation/widgets/pipeline_progress_bar.dart';
import 'package:hakaton_moskova_app/presentation/widgets/video_generate_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfessionFlowScreen extends StatefulWidget {
  const ProfessionFlowScreen({super.key});

  @override
  State<ProfessionFlowScreen> createState() => _ProfessionFlowScreenState();
}

class _ProfessionFlowScreenState extends State<ProfessionFlowScreen> {
  final _professionCtrl = TextEditingController();
  final _api = MemeopsApiClient(Supabase.instance.client);
  final _briefs = MemeBriefsRepository(Supabase.instance.client);
  late final PublicationPort _publish = createPublicationPort();

  ProfessionPipelineStage _stage = ProfessionPipelineStage.idle;
  String? _err;
  List<MemeBriefListItem> _variants = const [];
  MemeBriefListItem? _selected;
  String? _fileUrl;
  String? _lastJobInfo;

  double _t(ProfessionPipelineStage s) {
    const steps = 6;
    switch (s) {
      case ProfessionPipelineStage.idle:
        return 0;
      case ProfessionPipelineStage.inputReady:
        return 1 / steps;
      case ProfessionPipelineStage.creatingProfession:
        return 2 / steps;
      case ProfessionPipelineStage.generatingSituations:
        return 3 / steps;
      case ProfessionPipelineStage.choosingSituation:
        return 4 / steps;
      case ProfessionPipelineStage.generatingImage:
        return 5 / steps;
      case ProfessionPipelineStage.savingResult:
        return 5.5 / steps;
      case ProfessionPipelineStage.done:
        return 1;
      case ProfessionPipelineStage.error:
        return 0.3;
    }
  }

  String? _message(AppLocalizations l10n, ProfessionPipelineStage s) {
    switch (s) {
      case ProfessionPipelineStage.creatingProfession:
        return l10n.profProgressCreating;
      case ProfessionPipelineStage.generatingSituations:
        return l10n.profProgressSituations;
      case ProfessionPipelineStage.generatingImage:
        return l10n.profProgressImage;
      case ProfessionPipelineStage.savingResult:
        return l10n.profProgressSaving;
      default:
        return null;
    }
  }

  bool get _busy {
    return _stage == ProfessionPipelineStage.creatingProfession ||
        _stage == ProfessionPipelineStage.generatingSituations ||
        _stage == ProfessionPipelineStage.generatingImage ||
        _stage == ProfessionPipelineStage.savingResult;
  }

  Future<void> _runIdeas() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _err = null;
      _fileUrl = null;
      _selected = null;
      _variants = const [];
    });
    final title = _professionCtrl.text.trim();
    if (title.length < 3) {
      setState(() {
        _err = l10n.professionErrShortName;
        _stage = ProfessionPipelineStage.error;
      });
      return;
    }
    setState(() => _stage = ProfessionPipelineStage.creatingProfession);
    try {
      final pid = await _api.createProfession(title: title);
      setState(() {
        _stage = ProfessionPipelineStage.generatingSituations;
      });
      await _api.generateMemeBriefs(pid);
      final list = await _briefs.listForProfession(pid);
      if (list.isEmpty) {
        setState(() {
          _err = l10n.professionErrNoVariants;
          _stage = ProfessionPipelineStage.error;
        });
        return;
      }
      setState(() {
        _variants = list;
        _stage = ProfessionPipelineStage.choosingSituation;
      });
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = ProfessionPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = memeopsUnexpectedErrorMessage(e);
        _stage = ProfessionPipelineStage.error;
      });
    }
  }

  Future<void> _runImage() async {
    final l10n = AppLocalizations.of(context);
    if (_selected == null) {
      return;
    }
    setState(() {
      _err = null;
      _stage = ProfessionPipelineStage.generatingImage;
    });
    try {
      final r = await _api.generateImage(_selected!.id);
      setState(() {
        _fileUrl = r.fileUrl;
        _lastJobInfo = r.jobId != null
            ? 'job ${r.jobId} · version ${r.assetVersionId ?? "—"}'
            : null;
        _stage = ProfessionPipelineStage.savingResult;
      });
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (!mounted) {
        return;
      }
      setState(() {
        _stage = ProfessionPipelineStage.done;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.professionSnackSaved,
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
              sourceLabel: loc.professionSourceLabel,
            )
            .catchError((Object e, StackTrace st) {
              debugPrint(loc.archiveDebugSkip(e.toString()));
            }),
      );
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = ProfessionPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = memeopsUnexpectedErrorMessage(e);
        _stage = ProfessionPipelineStage.error;
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
                sourceLabel: loc.professionSourceLabel,
              )
              .catchError((Object e, StackTrace st) {
                debugPrint(loc.archiveDebugSkip(e.toString()));
              }),
        );
      }
    });
  }

  void _syncProfessionHint() {
    ProfessionHintStore.instance.setText(_professionCtrl.text);
  }

  @override
  void initState() {
    super.initState();
    _professionCtrl.addListener(_syncProfessionHint);
  }

  @override
  void dispose() {
    _professionCtrl.removeListener(_syncProfessionHint);
    _professionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: homeTabScrollPadding(),
      children: [
        MemeopsGlassSurface(
          padding: const EdgeInsets.all(20),
          child: MemeopsStepSection(
            step: 1,
            title: l10n.professionStep1Title,
            subtitle: l10n.professionStep1Subtitle,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _professionCtrl,
                  onChanged: (_) {
                    if (_stage == ProfessionPipelineStage.idle) {
                      setState(
                        () => _stage = ProfessionPipelineStage.inputReady,
                      );
                    }
                  },
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: l10n.professionNameLabel,
                    hintText: l10n.professionNameHint,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : () {
                          if (_fileUrl != null) {
                            setState(() {
                              _fileUrl = null;
                              _selected = null;
                              _variants = const [];
                              _stage = ProfessionPipelineStage.idle;
                            });
                          } else {
                            _runIdeas();
                          }
                        },
                  child: Text(
                    _fileUrl != null
                        ? l10n.professionStartOver
                        : l10n.professionGenerateIdeas,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_err != null) ...[
          const SizedBox(height: 12),
          ErrorRetryCard(
            message: _err!,
            onRetry: _stage == ProfessionPipelineStage.error ? _runIdeas : null,
          ),
        ],
        if (_stage != ProfessionPipelineStage.idle &&
            _stage != ProfessionPipelineStage.error) ...[
          const SizedBox(height: 16),
          PipelineProgressBar(
            value: _t(_stage),
            message: _message(l10n, _stage),
          ),
        ],
        if (_variants.isNotEmpty && _fileUrl == null) ...[
          const SizedBox(height: 16),
          MemeopsGlassSurface(
            padding: const EdgeInsets.all(20),
            child: MemeopsStepSection(
              step: 2,
              title: l10n.professionStep2Title,
              subtitle: l10n.professionStep2Subtitle,
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
                    onPressed: _busy || _selected == null ? null : _runImage,
                    child: _stage == ProfessionPipelineStage.generatingImage
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
                              Text(l10n.professionGeneratingMeme),
                            ],
                          )
                        : Text(l10n.professionGenerateImage),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_fileUrl != null) ...[
          const SizedBox(height: 16),
          if (_lastJobInfo != null) Text(l10n.professionSavedLine(_lastJobInfo!)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                _fileUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) => Center(
                  child: Text(l10n.imageOfflineError),
                ),
              ),
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
              sourceLabel: l10n.professionSourceLabel,
              stepNumber: 3,
            ),
          ],
        ],
      ],
    );
  }
}
