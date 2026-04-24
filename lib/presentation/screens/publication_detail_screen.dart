import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/api/memeops_api_client.dart'
    show MemeopsApiClient, MemeopsApiException, memeopsUnexpectedErrorMessage;
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/models/telegram_channel_post_stats.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_bot_chat_info.dart';
import 'package:hakaton_moskova_app/data/publication/vk_wall_client.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({super.key, required this.entry});

  final TelegramPublishedEntry entry;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

enum _PlatformTab { all, telegram, vk, dzen }

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  _PlatformTab _tab = _PlatformTab.all;
  bool _refreshing = false;
  late final Future<String?> _telegramChannelTitle =
      fetchTelegramChannelTitleForCurrentPublish();
  final _api = MemeopsApiClient(Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await TelegramPublishedLogRepository.instance.ensureLoaded();
      if (!mounted) {
        return;
      }
      setState(_syncInitialTab);
      for (final e in _siblingEntries) {
        if (e.isTelegram && e.messageId != null && AppEnv.isApiConfigured) {
          if (e.views == null || e.telegramReactionsJson == null) {
            unawaited(_refreshTelegramFor(e, showProgress: false));
          }
        } else if (e.isVk && e.vkPostId != null && e.views == null) {
          unawaited(_refreshVkFor(e, showProgress: false));
        }
      }
    });
  }

  void _syncInitialTab() {
    final s = _siblingEntries;
    if (s.length > 1) {
      if (widget.entry.isTelegram && _hasTelegramSib) {
        _tab = _PlatformTab.telegram;
      } else if (widget.entry.isVk && _hasVkSib) {
        _tab = _PlatformTab.vk;
      } else if (widget.entry.isDzen && _hasDzenSib) {
        _tab = _PlatformTab.dzen;
      } else {
        _tab = _PlatformTab.all;
      }
    } else if (s.isNotEmpty) {
      final a = s.first;
      if (a.isTelegram) {
        _tab = _PlatformTab.telegram;
      } else if (a.isVk) {
        _tab = _PlatformTab.vk;
      } else {
        _tab = _PlatformTab.dzen;
      }
    }
  }

  /// Aynı arşiv sürümüne giden tüm (Telegram / VK / Dzen) satırları.
  List<TelegramPublishedEntry> get _siblingEntries {
    final a = _currentEntry;
    final k1 = a.localArchiveId;
    final k2 = a.supabaseVersionId;
    if (k1 == null && k2 == null) {
      return <TelegramPublishedEntry>[a];
    }
    final map = <String, TelegramPublishedEntry>{};
    for (final e in TelegramPublishedLogRepository.instance.items) {
      if (k1 != null && e.localArchiveId == k1) {
        map[e.id] = e;
      } else if (k2 != null && e.supabaseVersionId == k2) {
        map[e.id] = e;
      }
    }
    map[a.id] = a;
    final list = map.values.toList();
    int rank(String p) {
      if (p == 'telegram') {
        return 0;
      }
      if (p == 'vk') {
        return 1;
      }
      if (p == 'dzen') {
        return 2;
      }
      return 9;
    }
    list.sort((a, b) {
      final c = rank(a.platform).compareTo(rank(b.platform));
      if (c != 0) {
        return c;
      }
      return b.publishedAt.compareTo(a.publishedAt);
    });
    return list;
  }

  bool get _hasTelegramSib =>
      _siblingEntries.any((e) => e.isTelegram);
  bool get _hasVkSib => _siblingEntries.any((e) => e.isVk);
  bool get _hasDzenSib => _siblingEntries.any((e) => e.isDzen);

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateTimeLine(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} · '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  String? _formatIsoTime(String? iso) {
    if (iso == null || iso.isEmpty) {
      return null;
    }
    final d = DateTime.tryParse(iso);
    if (d == null) {
      return null;
    }
    return DateFormat('dd.MM.yyyy · HH:mm').format(d.toLocal());
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

  Future<void> _refreshAll() async {
    if (!mounted) {
      return;
    }
    if (_siblingEntries.length == 1 && _siblingEntries.first.isDzen) {
      return;
    }
    setState(() => _refreshing = true);
    try {
      for (final e in _siblingEntries) {
        if (e.isTelegram && e.messageId != null) {
          await _refreshTelegramFor(e, showProgress: false);
        } else if (e.isVk && e.vkGroupId != null && e.vkPostId != null) {
          await _refreshVkFor(e, showProgress: false);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _refreshTelegramFor(
    TelegramPublishedEntry e, {
    bool showProgress = true,
  }) async {
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
    if (showProgress) {
      setState(() => _refreshing = true);
    }
    try {
      final s = await _api.fetchTelegramChannelPostStats(
        channel: ch,
        messageId: e.messageId!,
        chatId: e.chatId,
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
        telegramChannelMemberCount: s.channelMemberCount,
        telegramRepliesCount: s.replies,
        telegramMessageDate: s.messageDate,
      );
    } catch (err, st) {
      debugPrint('PublicationDetail _refreshTelegram: $err\n$st');
      if (!mounted) {
        return;
      }
      final l10n = AppLocalizations.of(context);
      if (err is MemeopsApiException && err.code == 'not_found') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.publicationDetailStatsNotFound)),
        );
      } else {
        final msg = memeopsUnexpectedErrorMessage(err);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (showProgress && mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _refreshVkFor(
    TelegramPublishedEntry e, {
    bool showProgress = true,
  }) async {
    if (!e.isVk || e.vkGroupId == null || e.vkPostId == null) {
      return;
    }
    if (!AppEnv.isVkPublishConfigured) {
      return;
    }
    if (!mounted) {
      return;
    }
    if (showProgress) {
      setState(() => _refreshing = true);
    }
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
      final mem =
          await VkWallClient.instance.fetchGroupMembersCount(e.vkGroupId!);
      await TelegramPublishedLogRepository.instance.updateEntry(
        e.id,
        views: s.views,
        likesCount: s.likes,
        repostsCount: s.reposts,
        vkGroupMemberCount: mem,
        vkCommentsCount: s.comments,
      );
    } catch (err, st) {
      debugPrint('PublicationDetail _refreshVk: $err\n$st');
    } finally {
      if (showProgress && mounted) {
        setState(() => _refreshing = false);
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

  /// Sekmeye göre birincil gösterilen kayıt (Tümü hariç).
  TelegramPublishedEntry? get _activeSingleEntry {
    return switch (_tab) {
      _PlatformTab.all => null,
      _PlatformTab.telegram =>
        _siblingEntries.firstWhere(
          (e) => e.isTelegram,
          orElse: () => _siblingEntries.first,
        ),
      _PlatformTab.vk => _siblingEntries.firstWhere(
          (e) => e.isVk,
          orElse: () => _siblingEntries.first,
        ),
      _PlatformTab.dzen => _siblingEntries.firstWhere(
          (e) => e.isDzen,
          orElse: () => _siblingEntries.first,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: TelegramPublishedLogRepository.instance.onChanged,
      builder: (context, _) {
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
              if (_siblingEntries.any(
                    (e) =>
                        (e.isTelegram && e.messageId != null) ||
                        (e.isVk && e.vkPostId != null),
                  ))
                IconButton(
                  tooltip: l10n.publicationDetailRefreshAll,
                  onPressed: _refreshing ? null : _refreshAll,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (_siblingEntries.length > 1) ...[
                _platformSegmented(context, l10n),
                const SizedBox(height: 10),
              ] else if (_siblingEntries.length == 1) ...[
                _sectionLabel(
                  context,
                  l10n,
                  _onePlatformTitle(l10n, _siblingEntries.first),
                ),
                const SizedBox(height: 6),
              ],
              if (_tab == _PlatformTab.all) ..._allPlatformsBody(context, l10n)
              else
                ..._singlePlatformBody(
                  context,
                  l10n,
                  _activeSingleEntry ?? _siblingEntries.first,
                ),
            ],
          ),
        );
      },
    );
  }

  String _onePlatformTitle(
    AppLocalizations l10n,
    TelegramPublishedEntry e,
  ) {
    if (e.isTelegram) {
      return l10n.analysisPlatformTelegram;
    }
    if (e.isVk) {
      return l10n.analysisPlatformVk;
    }
    return l10n.publicationDetailTabDzen;
  }

  List<Widget> _allPlatformsBody(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final out = <Widget>[];
    for (final e in _siblingEntries) {
      if (e.isTelegram) {
        out.add(
          _sectionLabel(
            context,
            l10n,
            l10n.analysisPlatformTelegram,
          ),
        );
        out.add(const SizedBox(height: 6));
        out.addAll(
          _detailSectionForEntry(context, l10n, e, isInAll: true),
        );
        out.add(const SizedBox(height: 18));
      } else if (e.isVk) {
        out.add(
          _sectionLabel(
            context,
            l10n,
            l10n.analysisPlatformVk,
          ),
        );
        out.add(const SizedBox(height: 6));
        out.addAll(
          _detailSectionForEntry(context, l10n, e, isInAll: true),
        );
        out.add(const SizedBox(height: 18));
      } else if (e.isDzen) {
        out.add(
          _sectionLabel(
            context,
            l10n,
            l10n.publicationDetailTabDzen,
          ),
        );
        out.add(const SizedBox(height: 6));
        out.addAll(
          _detailSectionForEntry(context, l10n, e, isInAll: true),
        );
        out.add(const SizedBox(height: 18));
      }
    }
    if (out.isNotEmpty) {
      out.removeLast();
    }
    return out;
  }

  List<Widget> _singlePlatformBody(
    BuildContext context,
    AppLocalizations l10n,
    TelegramPublishedEntry e,
  ) {
    return _detailSectionForEntry(context, l10n, e, isInAll: false);
  }

  List<Widget> _detailSectionForEntry(
    BuildContext context,
    AppLocalizations l10n,
    TelegramPublishedEntry e, {
    required bool isInAll,
  }) {
    return [
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
        children: _buildInfoRows(
          context,
          l10n,
          e,
        ),
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
    ];
  }

  List<Widget> _buildInfoRows(
    BuildContext context,
    AppLocalizations l10n,
    TelegramPublishedEntry e,
  ) {
    if (e.isDzen) {
      return [
        _metricRow(
          context,
          l10n.publicationDetailKind,
          e.isVideo
              ? l10n.analysisPostKindVideo
              : l10n.analysisPostKindImage,
          isFirst: true,
        ),
        _metricRow(
          context,
          l10n.publicationDetailDzen,
          l10n.publicationDetailDzenBody,
        ),
      ];
    }
    if (e.isTelegram) {
      return [
        _metricRow(
          context,
          l10n.publicationDetailKind,
          e.isVideo
              ? l10n.analysisPostKindVideo
              : l10n.analysisPostKindImage,
          isFirst: true,
        ),
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
        if (e.telegramChannelMemberCount != null)
          _metricRow(
            context,
            l10n.publicationDetailMembers,
            '${e.telegramChannelMemberCount}',
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
        if (e.telegramMessageDate != null)
          _metricRow(
            context,
            l10n.publicationDetailTgMessageTime,
            _formatIsoTime(e.telegramMessageDate) ?? '—',
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
        if (e.telegramRepliesCount != null)
          _metricRow(
            context,
            l10n.publicationDetailTgReplies,
            '${e.telegramRepliesCount}',
          ),
        ..._buildTelegramReactions(
          context,
          l10n,
          e,
        ),
      ];
    }
    if (e.isVk) {
      return [
        _metricRow(
          context,
          l10n.publicationDetailKind,
          e.isVideo
              ? l10n.analysisPostKindVideo
              : l10n.analysisPostKindImage,
          isFirst: true,
        ),
        if (e.vkGroupId != null)
          _metricRow(
            context,
            l10n.publicationDetailVkGroup,
            '${e.vkGroupId}',
          ),
        if (e.vkGroupMemberCount != null)
          _metricRow(
            context,
            l10n.publicationDetailMembers,
            '${e.vkGroupMemberCount}',
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
        if (e.vkCommentsCount != null)
          _metricRow(
            context,
            l10n.publicationDetailComments,
            '${e.vkCommentsCount}',
          ),
      ];
    }
    return [];
  }

  Widget _platformSegmented(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final segs = <_PlatformTab, String>{
      if (_siblingEntries.length > 1) _PlatformTab.all: l10n.publicationDetailTabAll,
      if (_hasTelegramSib) _PlatformTab.telegram: l10n.analysisPlatformTelegram,
      if (_hasVkSib) _PlatformTab.vk: l10n.analysisPlatformVk,
      if (_hasDzenSib) _PlatformTab.dzen: l10n.publicationDetailTabDzen,
    };
    final order = segs.keys.toList();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < order.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _tabChip(
              context,
              label: segs[order[i]]!,
              selected: _tab == order[i],
              onTap: () => setState(() => _tab = order[i]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tabChip(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? MemeopsColors.iosBlue.withValues(alpha: 0.28)
                : MemeopsColors.surfaceCharcoal,
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            border: Border.all(
              color: selected
                  ? MemeopsColors.iosBlue
                  : Colors.white.withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: MemeopsTextStyles.subtitle(context).copyWith(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: Colors.white.withValues(
                alpha: selected ? 0.98 : 0.7,
              ),
            ),
          ),
        ),
      ),
    );
  }

}

extension _DetailWidgets on _PublicationDetailScreenState {
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
