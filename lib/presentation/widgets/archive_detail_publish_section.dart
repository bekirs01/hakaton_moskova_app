import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_channel_router.dart';
import 'package:hakaton_moskova_app/data/local/archive_publish_scheduler.dart';
import 'package:hakaton_moskova_app/data/local/meme_local_archive_repository.dart';
import 'package:hakaton_moskova_app/data/repository/meme_supabase_assets_repository.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/utils/archive_share.dart';
import 'package:hakaton_moskova_app/presentation/utils/share_target.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Arşiv detayında: metin + çoklu kanal (Telegram/VK) + zamanlama + gönder.
class ArchiveDetailPublishSection extends StatefulWidget {
  ArchiveDetailPublishSection({
    super.key,
    required this.sourceLabel,
    this.initialCaption,
    required this.mediaKind,
    this.localFile,
    this.networkUrl,
    this.localArchiveId,
    this.supabaseVersionId,
    this.sourceMemeBriefId,
  }) : assert(
          localFile != null ||
              (networkUrl != null && networkUrl.trim().isNotEmpty),
          'Yerel dosya veya networkUrl gerekli',
        );

  final String sourceLabel;
  final String? initialCaption;
  final MemeArchiveKind mediaKind;
  final File? localFile;
  final String? networkUrl;
  final String? localArchiveId;
  final String? supabaseVersionId;
  final String? sourceMemeBriefId;

  @override
  State<ArchiveDetailPublishSection> createState() =>
      ArchiveDetailPublishSectionState();
}

class ArchiveDetailPublishSectionState extends State<ArchiveDetailPublishSection> {
  late final TextEditingController _caption;
  /// Çoklu Telegram hedefi: her yuva için işaret; null = tek «Telegram» kutusu ([_postTelegram]).
  List<bool>? _tgSlotSelected;
  bool _postTelegram = false;
  bool _postVk = false;
  bool _postDzen = false;
  bool _scheduleLater = false;
  DateTime? _scheduledAt;
  bool _busy = false;

  String _contentBlob() {
    return '${_caption.text} ${widget.sourceLabel}';
  }

  @override
  void initState() {
    super.initState();
    _caption = TextEditingController(text: widget.initialCaption ?? '');
    _caption.addListener(_onCaptionChanged);
    final vk = AppEnv.isVkPublishConfigured;
    _postVk = vk;
    final tgDest = AppEnv.telegramPublishDestinations;
    if (AppEnv.isTelegramPublishConfigured && tgDest.length > 1) {
      _tgSlotSelected = List.filled(tgDest.length, false);
      final rec = TelegramChannelRouter.recommendIndex(tgDest, _contentBlob());
      _tgSlotSelected![rec] = true;
    } else {
      _tgSlotSelected = null;
      _postTelegram = AppEnv.isTelegramPublishConfigured;
    }
  }

  void _onCaptionChanged() {
    if (_tgSlotSelected == null || !mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _caption.removeListener(_onCaptionChanged);
    _caption.dispose();
    super.dispose();
  }

  Future<void> submitPublish() => _submit();

  bool _hasAnyPublishSelection() {
    if (_postDzen) {
      return true;
    }
    if (AppEnv.isVkPublishConfigured && _postVk) {
      return true;
    }
    if (!AppEnv.isTelegramPublishConfigured) {
      return false;
    }
    final slots = _tgSlotSelected;
    if (slots != null) {
      return slots.any((e) => e);
    }
    return _postTelegram;
  }

  int _telegramRecommendIndex() {
    final d = AppEnv.telegramPublishDestinations;
    if (d.length <= 1) {
      return 0;
    }
    return TelegramChannelRouter.recommendIndex(d, _contentBlob());
  }

  Future<void> _runScheduledJobs({
    required String shareText,
    required String sourceLabel,
    required String? net,
    required DateTime at,
  }) async {
    if (AppEnv.isVkPublishConfigured && _postVk) {
      await ArchivePublishScheduler.instance.enqueue(
        target: MemeopsShareTarget.vk,
        kind: widget.mediaKind,
        shareText: shareText,
        sourceLabel: sourceLabel,
        scheduledFor: at,
        localFilePath: widget.localFile?.path,
        networkUrl: net,
        localArchiveId: widget.localArchiveId,
        supabaseVersionId: widget.supabaseVersionId,
      );
    }
    if (_postDzen) {
      await ArchivePublishScheduler.instance.enqueue(
        target: MemeopsShareTarget.dzen,
        kind: widget.mediaKind,
        shareText: shareText,
        sourceLabel: sourceLabel,
        scheduledFor: at,
        localFilePath: widget.localFile?.path,
        networkUrl: net,
        localArchiveId: widget.localArchiveId,
        supabaseVersionId: widget.supabaseVersionId,
      );
    }
    if (AppEnv.isTelegramPublishConfigured) {
      final d = AppEnv.telegramPublishDestinations;
      final slots = _tgSlotSelected;
      if (slots != null) {
        for (var i = 0; i < d.length; i++) {
          if (slots[i]) {
            await ArchivePublishScheduler.instance.enqueue(
              target: MemeopsShareTarget.telegram,
              kind: widget.mediaKind,
              shareText: shareText,
              sourceLabel: sourceLabel,
              scheduledFor: at,
              localFilePath: widget.localFile?.path,
              networkUrl: net,
              localArchiveId: widget.localArchiveId,
              supabaseVersionId: widget.supabaseVersionId,
              telegramChatId: d[i].chatId,
            );
          }
        }
      } else if (_postTelegram) {
        await ArchivePublishScheduler.instance.enqueue(
          target: MemeopsShareTarget.telegram,
          kind: widget.mediaKind,
          shareText: shareText,
          sourceLabel: sourceLabel,
          scheduledFor: at,
          localFilePath: widget.localFile?.path,
          networkUrl: net,
          localArchiveId: widget.localArchiveId,
          supabaseVersionId: widget.supabaseVersionId,
          telegramChatId: d.first.chatId,
        );
      }
    }
  }

  Future<void> _runImmediatePublishes({
    required BuildContext context,
    required String shareText,
    required String sourceLabel,
    required String? net,
  }) async {
    if (AppEnv.isVkPublishConfigured && _postVk) {
      await executeArchivePublish(
        context,
        target: MemeopsShareTarget.vk,
        kind: widget.mediaKind,
        shareText: shareText,
        sourceLabel: sourceLabel,
        localFile: widget.localFile,
        networkUrl: net,
        localArchiveId: widget.localArchiveId,
        supabaseVersionId: widget.supabaseVersionId,
      );
    }
    if (!context.mounted) {
      return;
    }
    if (_postDzen) {
      await executeArchivePublish(
        context,
        target: MemeopsShareTarget.dzen,
        kind: widget.mediaKind,
        shareText: shareText,
        sourceLabel: sourceLabel,
        localFile: widget.localFile,
        networkUrl: net,
        localArchiveId: widget.localArchiveId,
        supabaseVersionId: widget.supabaseVersionId,
      );
    }
    if (!context.mounted) {
      return;
    }
    if (AppEnv.isTelegramPublishConfigured) {
      final d = AppEnv.telegramPublishDestinations;
      final slots = _tgSlotSelected;
      if (slots != null) {
        for (var i = 0; i < d.length; i++) {
          if (!slots[i]) {
            continue;
          }
          if (!context.mounted) {
            return;
          }
          await executeArchivePublish(
            context,
            target: MemeopsShareTarget.telegram,
            kind: widget.mediaKind,
            shareText: shareText,
            sourceLabel: sourceLabel,
            localFile: widget.localFile,
            networkUrl: net,
            localArchiveId: widget.localArchiveId,
            supabaseVersionId: widget.supabaseVersionId,
            telegramChatId: d[i].chatId,
          );
        }
      } else if (_postTelegram) {
        if (!context.mounted) {
          return;
        }
        await executeArchivePublish(
          context,
          target: MemeopsShareTarget.telegram,
          kind: widget.mediaKind,
          shareText: shareText,
          sourceLabel: sourceLabel,
          localFile: widget.localFile,
          networkUrl: net,
          localArchiveId: widget.localArchiveId,
          supabaseVersionId: widget.supabaseVersionId,
          telegramChatId: d.first.chatId,
        );
      }
    }
  }

  Future<void> _saveCaptionOnly() async {
    final l10n = AppLocalizations.of(context);
    final text = _caption.text.trim();
    setState(() => _busy = true);
    try {
      if (widget.localArchiveId != null) {
        await MemeLocalArchiveRepository.instance.updateEntryCaption(
          widget.localArchiveId!,
          text.isEmpty ? null : text,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archiveCaptionSaved)),
          );
        }
        return;
      }
      final bid = widget.sourceMemeBriefId;
      if (bid != null && bid.isNotEmpty) {
        final repo = MemeSupabaseAssetsRepository(Supabase.instance.client);
        await repo.updateBriefSuggestedCaption(bid, text);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archiveCaptionSaved)),
          );
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.archiveCaptionCloudNeedsBrief)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.archiveShareFailedWithError('$e'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _pickSchedule() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _scheduledAt ?? now.add(const Duration(hours: 1)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
    );
    if (d == null || !mounted) {
      return;
    }
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _scheduledAt ?? now.add(const Duration(hours: 1)),
      ),
    );
    if (t == null || !mounted) {
      return;
    }
    setState(() {
      _scheduledAt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_hasAnyPublishSelection()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.archivePublishSelectAtLeastOneChannel)),
      );
      return;
    }

    await ArchivePublishScheduler.instance.ensureStarted();
    if (!mounted) {
      return;
    }

    final shareText = _caption.text.trim().isEmpty
        ? widget.sourceLabel
        : _caption.text.trim();

    final net = widget.networkUrl?.trim().isNotEmpty == true
        ? widget.networkUrl!.trim()
        : null;

    setState(() => _busy = true);
    try {
      if (_scheduleLater) {
        final at = _scheduledAt;
        if (at == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archivePublishChooseSchedule)),
          );
          return;
        }
        if (!at.isAfter(DateTime.now().add(const Duration(seconds: 15)))) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.archivePublishSchedulePast)),
          );
          return;
        }
        await _runScheduledJobs(
          shareText: shareText,
          sourceLabel: widget.sourceLabel,
          net: net,
          at: at,
        );
        if (mounted) {
          final fmt = DateFormat.yMMMd().add_Hm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.archivePublishScheduledAck(fmt.format(at))}\n'
                '${l10n.archivePublishScheduleNeedOpenApp}',
              ),
            ),
          );
        }
        return;
      }

      await _runImmediatePublishes(
        context: context,
        shareText: shareText,
        sourceLabel: widget.sourceLabel,
        net: net,
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tg = AppEnv.isTelegramPublishConfigured;
    final vk = AppEnv.isVkPublishConfigured;
    final tgDest = AppEnv.telegramPublishDestinations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.archiveCaptionLabel,
          style: MemeopsTextStyles.caption(context).copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        _MemeopsInsetCard(
          child: TextField(
            controller: _caption,
            minLines: 3,
            maxLines: 8,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.4,
            ),
            decoration: const InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: '',
            ),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: _busy ? null : _saveCaptionOnly,
          icon: const Icon(Icons.save_rounded, size: 20),
          label: Text(l10n.archiveCaptionSave),
          style: FilledButton.styleFrom(
            foregroundColor: MemeopsColors.iosBlueBright,
            backgroundColor: MemeopsColors.iosBlue.withValues(alpha: 0.22),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MemeopsRadii.md),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          l10n.archivePublishTitle,
          style: MemeopsTextStyles.sectionTitle(context).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.archivePublishChannelsSubtitle,
          style: MemeopsTextStyles.caption(context).copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            height: 1.3,
          ),
        ),
        if (tg && tgDest.length > 1) ...[
          const SizedBox(height: 10),
          _MemeopsInsetCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.tips_and_updates_rounded,
                  color: MemeopsColors.iosBlueBright.withValues(alpha: 0.95),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.archiveTelegramSmartRoutingTitle,
                        style: MemeopsTextStyles.caption(context).copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.archiveTelegramSmartRoutingHint(
                          tgDest[_telegramRecommendIndex()].label,
                        ),
                        style: MemeopsTextStyles.caption(context).copyWith(
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        if (!tg && !vk)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.archivePublishNoTgVkDzenOnly,
              style: MemeopsTextStyles.caption(context).copyWith(
                color: Colors.white.withValues(alpha: 0.5),
                height: 1.3,
              ),
            ),
          ),
        _MemeopsInsetCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              if (tg) ...[
                if (_tgSlotSelected != null)
                  for (var i = 0; i < tgDest.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 52,
                        endIndent: 14,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    _ChannelCheckTile(
                      busy: _busy,
                      value: _tgSlotSelected![i],
                      onChanged: (v) =>
                          setState(() => _tgSlotSelected![i] = v),
                      icon: Icons.send_rounded,
                      iconColor: const Color(0xFF2AABEE),
                      label: tgDest[i].label,
                      subtitle: tgDest[i].chatId,
                      badgeText: i == _telegramRecommendIndex()
                          ? l10n.archiveTelegramSuggestedBadge
                          : null,
                    ),
                  ]
                else
                  _ChannelCheckTile(
                    busy: _busy,
                    value: _postTelegram,
                    onChanged: (v) => setState(() => _postTelegram = v),
                    icon: Icons.send_rounded,
                    iconColor: const Color(0xFF2AABEE),
                    label: l10n.shareTargetTelegram,
                  ),
              ],
              if (tg && vk)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  endIndent: 14,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              if (vk)
                _ChannelCheckTile(
                  busy: _busy,
                  value: _postVk,
                  onChanged: (v) => setState(() => _postVk = v),
                  icon: Icons.video_library_outlined,
                  iconColor: const Color(0xFF0077FF),
                  label: l10n.shareTargetVk,
                ),
              if ((tg || vk))
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 52,
                  endIndent: 14,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              _ChannelCheckTile(
                busy: _busy,
                value: _postDzen,
                onChanged: (v) => setState(() => _postDzen = v),
                icon: Icons.auto_awesome,
                iconColor: const Color(0xFFCCCCCC),
                label: l10n.shareTargetDzen,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          l10n.archivePublishWhenHeading,
          style: MemeopsTextStyles.caption(context).copyWith(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _TimingOptionCard(
                selected: !_scheduleLater,
                icon: Icons.bolt_rounded,
                label: l10n.archivePublishWhenNow,
                onTap: _busy
                    ? null
                    : () => setState(() {
                          _scheduleLater = false;
                        }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _TimingOptionCard(
                selected: _scheduleLater,
                icon: Icons.event_available_rounded,
                label: l10n.archivePublishWhenSchedule,
                onTap: _busy
                    ? null
                    : () => setState(() {
                          _scheduleLater = true;
                        }),
              ),
            ),
          ],
        ),
        if (_scheduleLater) ...[
          const SizedBox(height: 12),
          _MemeopsInsetCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Icon(
                Icons.calendar_month_rounded,
                color: MemeopsColors.iosBlueBright.withValues(alpha: 0.95),
              ),
              title: Text(
                _scheduledAt == null
                    ? l10n.archivePublishPickDateTime
                    : DateFormat.yMMMd().add_Hm().format(_scheduledAt!),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: _scheduledAt == null
                  ? Text(
                      l10n.archivePublishChooseSchedule,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 12,
                      ),
                    )
                  : null,
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.35),
              ),
              onTap: _busy ? null : _pickSchedule,
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: MemeopsColors.iosBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MemeopsRadii.md),
            ),
            elevation: 0,
          ),
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  l10n.archivePublishSubmit,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
        ),
      ],
    );
  }
}

class _MemeopsInsetCard extends StatelessWidget {
  const _MemeopsInsetCard({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: MemeopsColors.surfaceCharcoal,
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChannelCheckTile extends StatelessWidget {
  const _ChannelCheckTile({
    required this.busy,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.iconColor,
    required this.label,
    this.subtitle,
    this.badgeText,
  });

  final bool busy;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String? badgeText;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: busy ? null : () => onChanged(!value),
        borderRadius: BorderRadius.circular(MemeopsRadii.sm),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Checkbox(
                  value: value,
                  onChanged: busy
                      ? null
                      : (v) => onChanged(v ?? false),
                  activeColor: MemeopsColors.iosBlueBright,
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 6),
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MemeopsColors.iosBlue.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MemeopsColors.iosBlueBright
                                    .withValues(alpha: 0.35),
                              ),
                            ),
                            child: Text(
                              badgeText!,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: MemeopsColors.iosBlueBright
                                    .withValues(alpha: 0.98),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.white.withValues(alpha: 0.42),
                          height: 1.15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimingOptionCard extends StatelessWidget {
  const _TimingOptionCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? MemeopsColors.iosBlueBright.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.14);
    final fill = selected
        ? MemeopsColors.iosBlue.withValues(alpha: 0.2)
        : MemeopsColors.surfaceCharcoal.withValues(alpha: 0.65);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? MemeopsColors.iosBlueBright
                        : Colors.white54,
                  ),
                  const SizedBox(width: 8),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: MemeopsColors.iosBlueBright.withValues(alpha: 0.95),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white70,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
