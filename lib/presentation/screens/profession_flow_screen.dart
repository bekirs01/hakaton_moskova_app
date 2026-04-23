import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/repository/meme_briefs_repository.dart';
import 'package:hakaton_moskova_app/domain/pipeline_stage.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';
import 'package:hakaton_moskova_app/presentation/widgets/error_retry_card.dart';
import 'package:hakaton_moskova_app/presentation/widgets/pipeline_progress_bar.dart';
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
  final _publish = StubPublicationPort();

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

  String? _message(ProfessionPipelineStage s) {
    switch (s) {
      case ProfessionPipelineStage.creatingProfession:
        return 'Creating profession…';
      case ProfessionPipelineStage.generatingSituations:
        return 'Generating 7–10 situation ideas (OpenAI on API server)…';
      case ProfessionPipelineStage.generatingImage:
        return 'Generating meme image…';
      case ProfessionPipelineStage.savingResult:
        return 'Persisting result…';
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
    setState(() {
      _err = null;
      _fileUrl = null;
      _selected = null;
      _variants = const [];
    });
    final title = _professionCtrl.text.trim();
    if (title.length < 3) {
      setState(() {
        _err = 'Enter a profession name (at least 3 characters).';
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
          _err = 'No variants were returned. Check backend logs / mock mode.';
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
        _lastJobInfo =
            r.jobId != null ? 'job ${r.jobId} · version ${r.assetVersionId ?? "—"}' : null;
        _stage = ProfessionPipelineStage.savingResult;
      });
      // Short beat so the bar shows "save" before "done" (persistence is server-side).
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
            'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets, tablolar: meme_assets / meme_asset_versions).',
            style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
          ),
          backgroundColor: Theme.of(context).colorScheme.inverseSurface,
          duration: const Duration(seconds: 4),
        ),
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
    final f = _publish.publishMeme(
      imageUrl: _fileUrl,
      brief: _selected,
    );
    f.then(
      (r) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(r.comingSoon ? (r.message ?? 'Coming soon') : 'Done'),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _professionCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Profession flow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Agent 1: profession → funny situations (GPT) · Agent 2: meme image (gpt-image-1) · Agent 3: publish (stub)',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _professionCtrl,
            onChanged: (_) {
              if (_stage == ProfessionPipelineStage.idle) {
                setState(() => _stage = ProfessionPipelineStage.inputReady);
              }
            },
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Profession name',
              hintText: 'e.g. architect, nurse, wizard',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
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
            child: Text(_fileUrl != null ? 'Start over' : 'Generate situation ideas'),
          ),
          if (_err != null) ...[
            const SizedBox(height: 12),
            ErrorRetryCard(
              message: _err!,
              onRetry: _stage == ProfessionPipelineStage.error ? _runIdeas : null,
            ),
          ],
          if (_stage != ProfessionPipelineStage.idle && _stage != ProfessionPipelineStage.error) ...[
            const SizedBox(height: 16),
            PipelineProgressBar(
              value: _t(_stage),
              message: _message(_stage),
            ),
          ],
          if (_variants.isNotEmpty && _fileUrl == null) ...[
            const SizedBox(height: 16),
            const Text(
              'Pick one line (7–10 AI situations):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ..._variants.map(
              (b) => ListTile(
                title: Text(b.displayLine, maxLines: 3, overflow: TextOverflow.ellipsis),
                selected: _selected?.id == b.id,
                onTap: _busy
                    ? null
                    : () {
                        setState(() {
                          _selected = b;
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
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Генерация мема…'),
                      ],
                    )
                  : const Text('Generate meme image'),
            ),
          ],
          if (_fileUrl != null) ...[
            const SizedBox(height: 16),
            if (_lastJobInfo != null) Text('Saved: $_lastJobInfo'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  _fileUrl!,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const Center(
                    child: Text('Image URL present but could not be displayed offline.'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _openPublish,
              child: const Text('Publication (coming soon)'),
            ),
          ],
        ],
      ),
    );
  }
}
