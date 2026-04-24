import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/state/telegram_analysis_store.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/screens/publication_detail_screen.dart';

class TelegramAnalysisScreen extends StatefulWidget {
  const TelegramAnalysisScreen({super.key});

  @override
  State<TelegramAnalysisScreen> createState() => _TelegramAnalysisScreenState();
}

class _TelegramAnalysisScreenState extends State<TelegramAnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        TelegramPublishedLogRepository.instance
            .ensureLoaded()
            .catchError(
              (Object e, StackTrace s) {
                debugPrint('ensureLoaded: $e\n$s');
              },
            ),
      );
    });
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _dateTimeLine(DateTime d) {
    return '${_two(d.day)}.${_two(d.month)}.${d.year} · '
        '${_two(d.hour)}:${_two(d.minute)}';
  }

  String _pubLine(AppLocalizations l10n, TelegramPublishedEntry e) {
    final kind = e.isVideo ? l10n.analysisPostKindVideo : l10n.analysisPostKindImage;
    final views = e.views != null ? l10n.analysisViewCount(e.views!) : l10n.analysisViewUnknown;
    var cap = (e.caption ?? '').trim();
    if (cap.length > 90) {
      cap = '${cap.substring(0, 90)}…';
    }
    if (cap.isEmpty) {
      cap = '—';
    }
    final platform =
        e.isVk ? l10n.analysisPlatformVk : l10n.analysisPlatformTelegram;
    final idPart = e.isVk
        ? (e.vkPostId != null ? 'VK #${e.vkPostId}' : 'VK')
        : (e.messageId != null ? 'TG #${e.messageId}' : 'Telegram');
    return '$platform · ${_dateTimeLine(e.publishedAt)} · $kind · $views\n$idPart · $cap';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: Listenable.merge([
        TelegramAnalysisStore.instance.current,
        TelegramPublishedLogRepository.instance.onChanged,
      ]),
      builder: (context, _) {
        final insights = TelegramAnalysisStore.instance.current.value;
        final myPubs = TelegramPublishedLogRepository.instance.items;
        return ListView(
          padding: homeTabScrollPadding(),
          children: [
            MemeopsGlassSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analysisTitle,
                    style: MemeopsTextStyles.sectionTitle(context),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.analysisSubtitle,
                    style: MemeopsTextStyles.caption(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MemeopsGlassSurface(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.analysisMyPublications,
                    style: MemeopsTextStyles.sectionTitle(
                      context,
                    ).copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.analysisMyPublicationsBody,
                    style: MemeopsTextStyles.caption(context),
                  ),
                  if (myPubs.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      l10n.analysisNoMyPublications,
                      style: MemeopsTextStyles.caption(context),
                    ),
                  ] else
                    for (var i = 0; i < myPubs.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => PublicationDetailScreen(
                                  entry: myPubs[i],
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  Icons.north_east_rounded,
                                  size: 14,
                                  color: MemeopsColors.iosBlueBright.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _pubLine(l10n, myPubs[i]),
                                  style: MemeopsTextStyles.caption(context)
                                      .copyWith(height: 1.4),
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (insights == null)
              MemeopsGlassSurface(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.analysisEmpty,
                  style: MemeopsTextStyles.caption(context),
                ),
              )
            else ...[
              _SectionCard(
                title: l10n.analysisOverview,
                lines: [
                  insights.channelTitle?.isNotEmpty == true
                      ? insights.channelTitle!
                      : insights.channelUrl,
                  insights.mainTopic,
                  '${l10n.analysisSampleSize}: ${insights.sampleSize}',
                  '${l10n.analysisSource}: ${insights.isTelethonLive ? l10n.analysisSourceLive : l10n.analysisSourceStub}',
                ],
              ),
              _SectionCard(
                title: l10n.analysisActivity,
                lines: insights.activityWindows.isNotEmpty
                    ? insights.activityWindows
                    : [l10n.analysisNoActivity],
              ),
              _SectionCard(
                title: l10n.analysisTopPosts,
                lines: insights.topPosts.isNotEmpty
                    ? insights.topPosts
                    : [l10n.analysisNoTopPosts],
              ),
              _SectionCard(
                title: l10n.analysisAudience,
                lines: insights.engagementInsights.isNotEmpty
                    ? insights.engagementInsights
                    : [l10n.analysisNoAudience],
              ),
              _SectionCard(
                title: l10n.analysisOpportunities,
                lines: [
                  ...insights.mediaInsights,
                  ...insights.memeableAngles,
                ].isNotEmpty
                    ? [
                        ...insights.mediaInsights,
                        ...insights.memeableAngles,
                      ]
                    : [l10n.analysisNoOpportunities],
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MemeopsGlassSurface(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: MemeopsTextStyles.sectionTitle(context).copyWith(
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < lines.length; i++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.auto_awesome_rounded, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lines[i],
                      style: MemeopsTextStyles.caption(context),
                    ),
                  ),
                ],
              ),
              if (i != lines.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}
