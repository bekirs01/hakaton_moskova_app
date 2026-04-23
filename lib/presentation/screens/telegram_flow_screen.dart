import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/repository/meme_briefs_repository.dart';
import 'package:hakaton_moskova_app/domain/pipeline_stage.dart';
import 'package:hakaton_moskova_app/presentation/widgets/error_retry_card.dart';
import 'package:hakaton_moskova_app/presentation/widgets/pipeline_progress_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelegramFlowScreen extends StatefulWidget {
  const TelegramFlowScreen({super.key});

  @override
  State<TelegramFlowScreen> createState() => _TelegramFlowScreenState();
}

String _titleFromChannelUrl(String raw) {
  final u = () {
    try {
      return Uri.parse(raw.contains('://') ? raw : 'https://$raw');
    } catch (_) {
      return null;
    }
  }();
  if (u == null) {
    return 'Telegram channel';
  }
  final last = u.pathSegments.isNotEmpty
      ? u.pathSegments.last.replaceAll('@', '')
      : u.host;
  var t = 'TG $last';
  if (t.length < 3) {
    t = 'Telegram channel';
  }
  return t.length > 200 ? t.substring(0, 200) : t;
}

class _TelegramFlowScreenState extends State<TelegramFlowScreen> {
  final _link = TextEditingController();
  final _api = MemeopsApiClient(Supabase.instance.client);
  final _briefs = MemeBriefsRepository(Supabase.instance.client);

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

  String? _msg(TelegramPipelineStage s) {
    switch (s) {
      case TelegramPipelineStage.fetchingInsights:
        return 'Fetching channel messages & building summary…';
      case TelegramPipelineStage.creatingProfession:
        return 'Preparing context…';
      case TelegramPipelineStage.generatingSituations:
        return 'Generating 7–10 meme ideas (AI) and saving to your workspace…';
      case TelegramPipelineStage.generatingImage:
        return 'Generating meme from selected variant…';
      case TelegramPipelineStage.savingResult:
        return 'Saving…';
      default:
        return null;
    }
  }

  bool get _busy =>
      {
        TelegramPipelineStage.fetchingInsights,
        TelegramPipelineStage.creatingProfession,
        TelegramPipelineStage.generatingSituations,
        TelegramPipelineStage.generatingImage,
        TelegramPipelineStage.savingResult,
      }.contains(_stage);

  Future<void> _analyze() async {
    setState(() {
      _err = null;
      _insights = null;
      _fileUrl = null;
      _selected = null;
      _variants = const [];
    });
    final u = _link.text.trim();
    if (u.length < 8) {
      setState(() {
        _err = 'Paste a full channel link (min 8 characters).';
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
    final i = _insights;
    if (i == null) {
      return;
    }
    if (i.isOfflineStub) {
      setState(() {
        _err =
            'This is offline stub data, not your channel. Start ./run_telegram_api.sh '
            'with TELEGRAM_* + session in .env, then try again.';
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
            _err = 'Too few ideas from server (${list.length}). Check OPENAI_API_KEY in API .env.';
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
        title: _titleFromChannelUrl(i.channelUrl),
        description: ctx,
        futureContext: 'Telegram import — feed this to meme agents as channel DNA.',
      );
      setState(() {
        _stage = TelegramPipelineStage.generatingSituations;
      });
      await _api.generateMemeBriefs(pid);
      final list = await _briefs.listForProfession(pid);
      if (list.isEmpty) {
        setState(() {
          _err = 'No ideas returned from server.';
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
              'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets).',
              style: TextStyle(color: Theme.of(context).colorScheme.onInverseSurface),
            ),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            duration: const Duration(seconds: 4),
          ),
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

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stub = _insights?.isOfflineStub == true;
    final live = _insights?.isTelethonLive == true;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Telegram link flow',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            live
                ? 'Live analysis via local Telethon API · ideas from the same summary'
                : 'Paste a public channel link · use ./run_telegram_api.sh for real fetch',
            style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _link,
            onChanged: (_) {
              if (_stage == TelegramPipelineStage.idle) {
                setState(() => _stage = TelegramPipelineStage.inputReady);
              }
            },
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Telegram channel / public link',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
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
                      const Text('Kanal analiz ediliyor…'),
                    ],
                  )
                : const Text('Analyse link'),
          ),
          if (stub) ...[
            const SizedBox(height: 12),
            Card(
              color: Colors.orange.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Stub mode — Telegram is not being read. Run ./run_telegram_api.sh '
                  'with TELEGRAM_* and a valid TELEGRAM_SESSION_STRING in .env.',
                ),
              ),
            ),
          ],
          if (_err != null) ...[
            const SizedBox(height: 12),
            ErrorRetryCard(message: _err!, onRetry: _analyze),
          ],
          if (_stage != TelegramPipelineStage.idle && _stage != TelegramPipelineStage.error) ...[
            const SizedBox(height: 12),
            PipelineProgressBar(value: _t(_stage), message: _msg(_stage)),
          ],
          if (_insights != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Structured summary',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (live)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Live',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (stub)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Stub',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_insights!.channelTitle != null &&
                        _insights!.channelTitle!.isNotEmpty)
                      Text('Channel: ${_insights!.channelTitle}'),
                    Text('Topic: ${_insights!.mainTopic}'),
                    if (_insights!.toneProfile != null &&
                        _insights!.toneProfile!.isNotEmpty)
                      Text('Style: ${_insights!.toneProfile}'),
                    Text('Tone: ${_insights!.tone}'),
                    Text('Themes: ${_insights!.recurringThemes.join(", ")}'),
                    if (_insights!.postTypes.isNotEmpty)
                      Text('Post mix: ${_insights!.postTypes.join("; ")}'),
                    Text('Media types: ${_insights!.mediaTypes.join(", ")}'),
                    if (_insights!.mediaInsights.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text('Media / images', style: TextStyle(fontWeight: FontWeight.w600)),
                      ..._insights!.mediaInsights.map((e) => Text('· $e')),
                    ],
                    if (_insights!.recentHighlights.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      const Text('Recent samples', style: TextStyle(fontWeight: FontWeight.w600)),
                      ..._insights!.recentHighlights.map((e) => Text('· $e')),
                    ],
                    const SizedBox(height: 6),
                    Text('Meme angles: ${_insights!.memeableAngles.join(" · ")}'),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: (stub || _busy) ? null : _runBriefBatch,
              child: Text(
                live ? 'Generate & save 7–10 AI variants' : 'Generate 5 idea variants (hosted API)',
              ),
            ),
            if (live)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Variants are saved as your meme_briefs; images use OPENAI_API_KEY on the Python API.',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
          ],
          if (_variants.isNotEmpty && _fileUrl == null) ...[
            const SizedBox(height: 12),
            const Text('Choose a variant, then build the image:'),
            ..._variants.map(
              (b) => ListTile(
                title: Text(b.displayLine, maxLines: 3),
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
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Генерация мема…'),
                      ],
                    )
                  : const Text('Generate meme from selection'),
            ),
          ],
          if (_fileUrl != null) ...[
            const SizedBox(height: 12),
            if (_lastInfo != null) Text('Asset version: $_lastInfo'),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                _fileUrl!,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    const Center(child: Text('Image load error')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
