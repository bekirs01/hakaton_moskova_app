import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/utils/share_target.dart';

/// Arşiv paylaşımı: platform seçimi. [pickShareTarget] yerine, kök navigatör ile açılır.
Future<MemeopsShareTarget?> showMemeopsArchivePublishSheet(
  BuildContext context,
) async {
  final l10n = AppLocalizations.of(context);
  final hasTg = AppEnv.isTelegramPublishConfigured;
  final hasVk = AppEnv.isVkPublishConfigured;
  const hasDzen = true;
  var optionCount = 0;
  if (hasTg) {
    optionCount++;
  }
  if (hasVk) {
    optionCount++;
  }
  if (hasDzen) {
    optionCount++;
  }
  if (optionCount == 0) {
    return null;
  }
  if (optionCount == 1) {
    if (hasTg) {
      return MemeopsShareTarget.telegram;
    }
    if (hasVk) {
      return MemeopsShareTarget.vk;
    }
    return MemeopsShareTarget.dzen;
  }
  if (!context.mounted) {
    return null;
  }
  return showModalBottomSheet<MemeopsShareTarget>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: MemeopsColors.bgMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.paddingOf(ctx).bottom + 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  l10n.shareTargetTitle,
                  style: MemeopsTextStyles.sectionTitle(
                    ctx,
                  ).copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  l10n.archiveShareSheetSubtitle,
                  style: MemeopsTextStyles.caption(ctx).copyWith(height: 1.35),
                ),
              ),
              const SizedBox(height: 8),
              if (hasTg)
                ListTile(
                  leading: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF2AABEE),
                  ),
                  title: Text(
                    l10n.shareTargetTelegram,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(ctx, MemeopsShareTarget.telegram),
                ),
              if (hasVk)
                ListTile(
                  leading: const Icon(
                    Icons.video_library_outlined,
                    color: Color(0xFF0077FF),
                  ),
                  title: Text(
                    l10n.shareTargetVk,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(ctx, MemeopsShareTarget.vk),
                ),
              ListTile(
                leading: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFFCCCCCC),
                ),
                title: Text(
                  l10n.shareTargetDzen,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(ctx, MemeopsShareTarget.dzen),
              ),
            ],
          ),
        ),
      );
    },
  );
}
