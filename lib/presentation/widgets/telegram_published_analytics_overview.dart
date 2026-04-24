import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/local/telegram_published_log.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:intl/intl.dart';

/// [TelegramPublishedLogRepository] girdilerinden cihaz paylaşım özet + basit 7 gün grafiği.
class TelegramPublishedAnalyticsOverview extends StatelessWidget {
  const TelegramPublishedAnalyticsOverview({
    super.key,
    required this.entries,
  });

  final List<TelegramPublishedEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final a = _MyPublicationAggregate(entries);
    if (a.total == 0) {
      return MemeopsGlassSurface(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        borderRadius: MemeopsRadii.md,
        child: Text(
          l10n.myPubSummaryEmpty,
          style: MemeopsTextStyles.caption(context).copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            height: 1.35,
          ),
        ),
      );
    }

    final locale = Localizations.localeOf(context);
    final dayFmt = DateFormat('d MMM', locale.toString());
    final last7 = a.last7DayPostCounts;
    final maxBar = last7.isEmpty
        ? 0
        : last7.reduce((p, c) => p > c ? p : c);
    final nMax = maxBar < 1 ? 1.0 : maxBar.toDouble();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start7 = today.subtract(const Duration(days: 6));

    final best = a.bestViewed;
    final (tw, pw) = a.rolling7vsPrior7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.myPubSummaryTitle,
          style: MemeopsTextStyles.sectionTitle(context).copyWith(
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.myPubSummaryRolling(tw, pw),
          style: MemeopsTextStyles.caption(context).copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        MemeopsGlassSurface(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          borderRadius: MemeopsRadii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _kv(
                context,
                l10n.myPubSummaryTotalLabel,
                '${a.total}',
              ),
              const SizedBox(height: 6),
              _kv(
                context,
                l10n.myPubSummaryViewsLabel,
                a.totalViewsKnown > 0
                    ? l10n.analysisViewCount(a.totalViewsSum)
                    : '—',
              ),
              const SizedBox(height: 10),
              _kv(
                context,
                l10n.myPubSummaryByType,
                '${l10n.myPubImageShort} ${a.imageCount} · ${l10n.myPubVideoShort} ${a.videoCount}',
              ),
              const SizedBox(height: 6),
              _kv(
                context,
                l10n.myPubSummaryByPlatform,
                '${l10n.analysisPlatformTelegram} ${a.tgCount} · '
                '${l10n.analysisPlatformVk} ${a.vkCount} · '
                '${l10n.myPubSummaryDzenLabel} ${a.dzenCount}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        MemeopsGlassSurface(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          borderRadius: MemeopsRadii.md,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.myPubSummaryChartTitle,
                style: MemeopsTextStyles.caption(context).copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 118,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (i) {
                    final d = start7.add(Duration(days: i));
                    final c = last7[i];
                    final h = 6.0 + (c / nMax) * 56.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$c',
                              style: TextStyle(
                                fontSize: 9,
                                color: MemeopsColors.iosBlueBright
                                    .withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: h,
                              decoration: BoxDecoration(
                                color: MemeopsColors.iosBlue
                                    .withValues(alpha: 0.55),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dayFmt.format(d),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 8,
                                height: 1.0,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        if (a.totalViewsSum > 0) ...[
          const SizedBox(height: 10),
          MemeopsGlassSurface(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            borderRadius: MemeopsRadii.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.myPubSummaryTypeViews,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _splitBar(
                  context,
                  leftLabel: l10n.myPubImageShort,
                  rightLabel: l10n.myPubVideoShort,
                  left: a.imageViews,
                  right: a.videoViews,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.myPubSummaryPlatformViews,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                _splitBar(
                  context,
                  leftLabel: l10n.analysisPlatformTelegram,
                  rightLabel: l10n.analysisPlatformVk,
                  left: a.tgTotalViews,
                  right: a.vkTotalViews,
                ),
                if (a.dzenCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    l10n.myPubSummaryDzenNoViews,
                    style: MemeopsTextStyles.caption(context).copyWith(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        if (best != null && best.views != null && best.views! > 0) ...[
          const SizedBox(height: 10),
          MemeopsGlassSurface(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            borderRadius: MemeopsRadii.md,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.myPubSummaryBest,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.analysisViewCount(best.views!),
                  style: MemeopsTextStyles.subtitle(context).copyWith(
                    color: MemeopsColors.iosBlueBright,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if ((best.caption ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _clip(best.caption!.trim(), 100),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: MemeopsTextStyles.caption(context).copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  best.isTelegram
                      ? l10n.analysisPlatformTelegram
                      : best.isVk
                          ? l10n.analysisPlatformVk
                          : l10n.myPubSummaryDzenLabel,
                  style: MemeopsTextStyles.caption(context).copyWith(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }

  String _clip(String s, int max) {
    if (s.length <= max) {
      return s;
    }
    return '${s.substring(0, max)}…';
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(
            k,
            style: MemeopsTextStyles.caption(context).copyWith(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.end,
            style: MemeopsTextStyles.subtitle(context).copyWith(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _splitBar(
    BuildContext context, {
    required String leftLabel,
    required String rightLabel,
    required int left,
    required int right,
  }) {
    final t = (left + right);
    if (t <= 0) {
      return Text(
        '—',
        textAlign: TextAlign.end,
        style: MemeopsTextStyles.caption(context),
      );
    }
    final lp = left / t;
    final rp = right / t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              flex: (lp * 1000).round().clamp(1, 1000),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF2AABEE).withValues(alpha: 0.65),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(4),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: (rp * 1000).round().clamp(1, 1000),
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF0077FF).withValues(alpha: 0.65),
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$leftLabel · $left',
              style: MemeopsTextStyles.caption(context).copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            Text(
              '$rightLabel · $right',
              style: MemeopsTextStyles.caption(context).copyWith(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MyPublicationAggregate {
  _MyPublicationAggregate(this.entries) {
    for (final e in entries) {
      total++;
      if (e.isVideo) {
        videoCount++;
        videoViews += e.views ?? 0;
      } else {
        imageCount++;
        imageViews += e.views ?? 0;
      }
      if (e.isTelegram) {
        tgCount++;
        tgTotalViews += e.views ?? 0;
      } else if (e.isVk) {
        vkCount++;
        vkTotalViews += e.views ?? 0;
      } else if (e.isDzen) {
        dzenCount++;
      }
      final v = e.views;
      if (v == null) {
        continue;
      }
      totalViewsSum += v;
      totalViewsKnown++;
      if (bestViewed == null) {
        bestViewed = e;
        continue;
      }
      final bv = bestViewed!.views ?? 0;
      if (v > bv) {
        bestViewed = e;
      } else if (v == bv && e.publishedAt.isAfter(bestViewed!.publishedAt)) {
        bestViewed = e;
      }
    }
  }

  final List<TelegramPublishedEntry> entries;
  int total = 0;
  int imageCount = 0;
  int videoCount = 0;
  int tgCount = 0;
  int vkCount = 0;
  int dzenCount = 0;
  int imageViews = 0;
  int videoViews = 0;
  int tgTotalViews = 0;
  int vkTotalViews = 0;
  int totalViewsSum = 0;
  int totalViewsKnown = 0;
  TelegramPublishedEntry? bestViewed;

  /// Son 6 gün + bugün, yerel gün sınırları.
  List<int> get last7DayPostCounts {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = today.subtract(const Duration(days: 6));
    final out = List<int>.filled(7, 0);
    for (final e in entries) {
      final d = DateTime(
        e.publishedAt.year,
        e.publishedAt.month,
        e.publishedAt.day,
      );
      if (d.isBefore(start) || d.isAfter(today)) {
        continue;
      }
      final i = d.difference(start).inDays;
      if (i >= 0 && i < 7) {
        out[i]++;
      }
    }
    return out;
  }

  /// Son 7 gün (bugün hariç değil, kayan pencere) vs önceki 7 gün.
  (int, int) get rolling7vsPrior7 {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var cur = 0;
    var prev = 0;
    for (final e in entries) {
      final d = DateTime(
        e.publishedAt.year,
        e.publishedAt.month,
        e.publishedAt.day,
      );
      if (d.isAfter(today)) {
        continue;
      }
      final daysAgo = today.difference(d).inDays;
      if (daysAgo < 0) {
        continue;
      }
      if (daysAgo < 7) {
        cur++;
      } else if (daysAgo < 14) {
        prev++;
      }
    }
    return (cur, prev);
  }
}
