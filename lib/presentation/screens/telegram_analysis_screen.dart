import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/state/telegram_analysis_store.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';

class TelegramAnalysisScreen extends StatelessWidget {
  const TelegramAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ValueListenableBuilder<ChannelInsights?>(
      valueListenable: TelegramAnalysisStore.instance.current,
      builder: (context, insights, _) {
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
