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
        return 'Fetching & summarising (server placeholder)…';
      case TelegramPipelineStage.creatingProfession:
        return 'Creating profession from channel context…';
      case TelegramPipelineStage.generatingSituations:
        return 'Running same brief batch as profession flow…';
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
        _err = e.toString();
        _stage = TelegramPipelineStage.error;
      });
    }
  }

  Future<void> _runBriefBatch() async {
    final i = _insights;
    if (i == null) {
      return;
    }
    setState(() {
      _err = null;
      _stage = TelegramPipelineStage.creatingProfession;
    });
    try {
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
        _err = e.toString();
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
      }
    } on MemeopsApiException catch (e) {
      setState(() {
        _err = e.message;
        _stage = TelegramPipelineStage.error;
      });
    } catch (e) {
      setState(() {
        _err = e.toString();
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
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Telegram link flow', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Agent 1: summary · Agent 2: image (shared pipeline) · Agent 3: stub'),
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
            child: const Text('Analyse link'),
          ),
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
                    const Text('Structured summary', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text('Topic: ${_insights!.mainTopic}'),
                    Text('Tone: ${_insights!.tone}'),
                    Text('Themes: ${_insights!.recurringThemes.join(", ")}'),
                    Text('Meme angles: ${_insights!.memeableAngles.join(" · ")}'),
                  ],
                ),
              ),
            ),
            FilledButton(
              onPressed: _busy ? null : _runBriefBatch,
              child: const Text('Generate 5 idea variants (server batch)'),
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
              child: const Text('Generate meme from selection'),
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
