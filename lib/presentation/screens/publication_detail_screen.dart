import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart'
    show MemeopsApiClient, memeopsUnexpectedErrorMessage;
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/telegram_channel_post_stats.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_bot_chat_info.dart';
import 'package:hakaton_moskova_app/data/publication/vk_wall_client.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({super.key, required this.entry});

  final TelegramPublishedEntry entry;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  bool _refreshingTg = false;
  bool _refreshingVk = false;
  late final Future<String?> _telegramChannelTitle =
      fetchTelegramChannelTitleForCurrentPublish();
  final _api = MemeopsApiClient(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final e = widget.entry;
      if (e.isVk && e.vkPostId != null && e.views == null) {
        unawaited(_refreshVk());
      } else if (e.isTelegram &&
          e.messageId != null &&
          AppEnv.isApiConfigured) {
        unawaited(_refreshTelegramStats());
      }
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateTimeLine(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} · '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  List<TelegramPostReactionRow> _reactionsFromEntry(
    TelegramPublishedEntry e,
  ) {
    final raw = e.telegramReactionsJson;
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }
    try {
      final d = jsonDecode(raw) as List<dynamic>?;
      if (d == null) {
        return const [];
      }
      return d
          .map(
            (x) => TelegramPostReactionRow.fromMap(
              Map<String, dynamic>.from(x as Map<dynamic, dynamic>),
            ),
          )
          .where((r) => r.count > 0)
          .toList();
    } catch (err, st) {
      debugPrint('reactions json: $err\n$st');
      return const [];
    }
  }

  String _reactionLine(
    AppLocalizations l10n,
    TelegramPostReactionRow r,
  ) {
    if (r.kind == 'custom_emoji' && r.label.startsWith('custom:')) {
      return l10n.publicationDetailCustomReaction(r.count);
    }
    if (r.label.isNotEmpty) {
      return l10n.publicationDetailEmojiReaction(r.label, r.count);
    }
    return l10n.publicationDetailReactionCountOnly(r.count);
  }

  Future<void> _refreshTelegramStats() async {
    final e = _currentEntry;
    if (!e.isTelegram || e.messageId == null) {
      return;
    }
    if (!AppEnv.isApiConfigured) {
      return;
    }
    final ch = (e.chatId != null && e.chatId!.trim().isNotEmpty)
        ? e.chatId!
        : AppEnv.telegramPublishChannel;
    if (ch.isEmpty) {
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() => _refreshingTg = true);
    try {
      final s = await _api.fetchTelegramChannelPostStats(
        channel: ch,
        messageId: e.messageId!,
      );
      if (!mounted) {
        return;
      }
      final j = jsonEncode(
        s.reactions
            .map(
              (r) => <String, dynamic>{
                'label': r.label,
                'count': r.count,
                'kind': r.kind,
              },
            )
            .toList(),
      );
      await TelegramPublishedLogRepository.instance.updateEntry(
        e.id,
        views: s.views,
        telegramForwards: s.forwards,
        telegramReactionsJson: j,
      );
    } catch (err, st) {
      debugPrint('PublicationDetail _refreshTelegram: $err\n$st');
      if (mounted) {
        final msg = memeopsUnexpectedErrorMessage(err);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _refreshingTg = false);
      }
    }
  }

  Future<void> _refreshVk() async {
    final e = _currentEntry;
    if (!e.isVk || e.vkGroupId == null || e.vkPostId == null) {
      return;
    }
    if (!AppEnv.isVkPublishConfigured) {
      return;
    }
    setState(() => _refreshingVk = true);
    try {
      final s = await VkWallClient.instance.fetchWallPostStats(
        groupId: e.vkGroupId!,
        postId: e.vkPostId!,
      );
      if (s == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      await TelegramPublishedLogRepository.instance.updateEntry(
        e.id,
        views: s.views,
        likesCount: s.likes,
        repostsCount: s.reposts,
      );
    } catch (err, st) {
      debugPrint('PublicationDetail _refreshVk: $err\n$st');
    } finally {
      if (mounted) {
        setState(() => _refreshingVk = false);
      }
    }
  }

  TelegramPublishedEntry get _currentEntry {
    var e = widget.entry;
    for (final x in TelegramPublishedLogRepository.instance.items) {
      if (x.id == e.id) {
        e = x;
        break;
      }
    }
    return e;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: TelegramPublishedLogRepository.instance.onChanged,
      builder: (context, _) {
        final e = _currentEntry;
        return Scaffold(
          backgroundColor: MemeopsColors.bgMid,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            title: Text(
              l10n.publicationDetailTitle,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            actions: [
              if (e.isTelegram && e.messageId != null)
                IconButton(
                  tooltip: l10n.publicationDetailRefreshTelegram,
                  onPressed: _refreshingTg ? null : _refreshTelegramStats,
                  icon: _refreshingTg
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                ),
              if (e.isVk && e.vkPostId != null)
                IconButton(
                  tooltip: l10n.publicationDetailRefreshVk,
                  onPressed: _refreshingVk ? null : _refreshVk,
                  icon: _refreshingVk
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _sectionLabel(context, l10n, e.isTelegram
                  ? l10n.analysisPlatformTelegram
                  : l10n.analysisPlatformVk),
              const SizedBox(height: 6),
              _iosGroup(
                context,
                children: [
                  _metricRow(
                    context,
                    l10n.publicationDetailPublishedAt,
                    _dateTimeLine(e.publishedAt),
                    isFirst: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionLabel(context, l10n, l10n.publicationDetailSectionInfo),
              const SizedBox(height: 6),
              _iosGroup(
                context,
                children: [
                  _metricRow(
                    context,
                    l10n.publicationDetailKind,
                    e.isVideo
                        ? l10n.analysisPostKindVideo
                        : l10n.analysisPostKindImage,
                    isFirst: true,
                  ),
                  if (e.isTelegram) ...[
                    _metricRow(
                      context,
                      l10n.publicationDetailMessageId,
                      e.messageId != null ? '#${e.messageId}' : '—',
                    ),
                    if (e.chatId != null && e.chatId!.isNotEmpty)
                      _metricRow(
                        context,
                        l10n.publicationDetailChat,
                        e.chatId!,
                      ),
                    FutureBuilder<String?>(
                      future: _telegramChannelTitle,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return _metricRow(
                            context,
                            l10n.publicationDetailChannel,
                            '…',
                          );
                        }
                        final t = snap.data;
                        if (t == null || t.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _metricRow(
                          context,
                          l10n.publicationDetailChannel,
                          t,
                        );
                      },
                    ),
                    _metricRow(
                      context,
                      l10n.publicationDetailViews,
                      e.views != null
                          ? l10n.analysisViewCount(e.views!)
                          : l10n.analysisViewUnknown,
                    ),
                    if (e.telegramForwards != null)
                      _metricRow(
                        context,
                        l10n.publicationDetailForwards,
                        '${e.telegramForwards}',
                      ),
                    ..._buildTelegramReactions(
                      context,
                      l10n,
                      e,
                    ),
                  ],
                  if (e.isVk) ...[
                    if (e.vkGroupId != null)
                      _metricRow(
                        context,
                        l10n.publicationDetailVkGroup,
                        '${e.vkGroupId}',
                        isFirst: true,
                      ),
                    if (e.vkPostId != null)
                      _metricRow(
                        context,
                        l10n.publicationDetailVkPost,
                        '#${e.vkPostId}',
                        isFirst: e.vkGroupId == null,
                      ),
                    _metricRow(
                      context,
                      l10n.publicationDetailViews,
                      e.views != null
                          ? l10n.analysisViewCount(e.views!)
                          : l10n.publicationDetailVkHint,
                    ),
                    if (e.likesCount != null)
                      _metricRow(
                        context,
                        l10n.publicationDetailLikes,
                        '${e.likesCount}',
                      ),
                    if (e.repostsCount != null)
                      _metricRow(
                        context,
                        l10n.publicationDetailReposts,
                        '${e.repostsCount}',
                      ),
                  ],
                ],
              ),
              if (e.caption != null && e.caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                _sectionLabel(context, l10n, l10n.publicationDetailCaption),
                const SizedBox(height: 6),
                _iosGroup(
                  context,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      child: Text(
                        e.caption!.trim(),
                        style: MemeopsTextStyles.subtitle(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.95),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTelegramReactions(
    BuildContext context,
    AppLocalizations l10n,
    TelegramPublishedEntry e,
  ) {
    final list = _reactionsFromEntry(e);
    final value = list.isEmpty
        ? l10n.publicationDetailReactionsEmpty
        : list.map((r) => _reactionLine(l10n, r)).join('\n');
    return [
      _metricRow(
        context,
        l10n.publicationDetailReactions,
        value,
      ),
    ];
  }

  Widget _sectionLabel(
    BuildContext context,
    AppLocalizations l10n,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: MemeopsTextStyles.caption(context).copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  Widget _iosGroup(BuildContext context, {required List<Widget> children}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: MemeopsColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(MemeopsRadii.md + 2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _withSeparators(children),
      ),
    );
  }

  List<Widget> _withSeparators(List<Widget> children) {
    if (children.isEmpty) {
      return [];
    }
    final out = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        out.add(
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        );
      }
      out.add(children[i]);
    }
    return out;
  }

  Widget _metricRow(
    BuildContext context,
    String label,
    String value, {
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, isFirst ? 12 : 10, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: MemeopsTextStyles.caption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: MemeopsTextStyles.subtitle(context).copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
