import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/data/publication/vk_wall_client.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

class PublicationDetailScreen extends StatefulWidget {
  const PublicationDetailScreen({super.key, required this.entry});

  final TelegramPublishedEntry entry;

  @override
  State<PublicationDetailScreen> createState() =>
      _PublicationDetailScreenState();
}

class _PublicationDetailScreenState extends State<PublicationDetailScreen> {
  bool _refreshing = false;

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateTimeLine(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} · '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  Future<void> _refreshVk() async {
    final e = widget.entry;
    if (!e.isVk || e.vkGroupId == null || e.vkPostId == null) {
      return;
    }
    if (!AppEnv.isVkPublishConfigured) {
      return;
    }
    setState(() => _refreshing = true);
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
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: TelegramPublishedLogRepository.instance.onChanged,
      builder: (context, _) {
        final id = widget.entry.id;
        TelegramPublishedEntry e = widget.entry;
        for (final x in TelegramPublishedLogRepository.instance.items) {
          if (x.id == id) {
            e = x;
            break;
          }
        }
        return Scaffold(
          backgroundColor: MemeopsColors.bgMid,
          appBar: AppBar(
            backgroundColor: Colors.black.withValues(alpha: 0.3),
            foregroundColor: Colors.white,
            title: Text(
              l10n.publicationDetailTitle,
              style: const TextStyle(fontSize: 18),
            ),
            actions: [
              if (e.isVk && e.vkPostId != null)
                IconButton(
                  tooltip: l10n.publicationDetailRefreshVk,
                  onPressed: _refreshing ? null : _refreshVk,
                  icon: _refreshing
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              Text(
                e.isTelegram
                    ? l10n.analysisPlatformTelegram
                    : l10n.analysisPlatformVk,
                style: MemeopsTextStyles.caption(context).copyWith(
                  color: MemeopsColors.iosBlueBright,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _dateTimeLine(e.publishedAt),
                style: MemeopsTextStyles.subtitle(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              _row(
                context,
                l10n.publicationDetailKind,
                e.isVideo ? l10n.analysisPostKindVideo : l10n.analysisPostKindImage,
              ),
              if (e.isTelegram) ...[
                _row(
                  context,
                  l10n.publicationDetailMessageId,
                  e.messageId != null ? '#${e.messageId}' : '—',
                ),
                if (e.chatId != null && e.chatId!.isNotEmpty)
                  _row(context, l10n.publicationDetailChat, e.chatId!),
                _row(
                  context,
                  l10n.publicationDetailViews,
                  e.views != null
                      ? l10n.analysisViewCount(e.views!)
                      : l10n.analysisViewUnknown,
                ),
              ],
              if (e.isVk) ...[
                if (e.vkGroupId != null)
                  _row(
                    context,
                    l10n.publicationDetailVkGroup,
                    '${e.vkGroupId}',
                  ),
                if (e.vkPostId != null)
                  _row(
                    context,
                    l10n.publicationDetailVkPost,
                    '#${e.vkPostId}',
                  ),
                _row(
                  context,
                  l10n.publicationDetailViews,
                  e.views != null
                      ? l10n.analysisViewCount(e.views!)
                      : l10n.publicationDetailVkHint,
                ),
                if (e.likesCount != null)
                  _row(
                    context,
                    l10n.publicationDetailLikes,
                    '${e.likesCount}',
                  ),
                if (e.repostsCount != null)
                  _row(
                    context,
                    l10n.publicationDetailReposts,
                    '${e.repostsCount}',
                  ),
              ],
              if (e.caption != null && e.caption!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.publicationDetailCaption,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    color: MemeopsColors.iosBlueBright,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  e.caption!.trim(),
                  style: MemeopsTextStyles.subtitle(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: MemeopsTextStyles.caption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: MemeopsTextStyles.caption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.95),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
