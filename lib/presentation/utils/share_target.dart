import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

/// Arşiv paylaşımı hedefi.
enum MemeopsShareTarget {
  telegram,
  vk,
}

/// Telegram veya VK; iptal = null.
Future<MemeopsShareTarget?> showMemeopsShareTargetSheet(
  BuildContext context,
) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<MemeopsShareTarget>(
    context: context,
    backgroundColor: MemeopsColors.bgMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.shareTargetTitle,
                  style: MemeopsTextStyles.sectionTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  l10n.shareTargetSubtitle,
                  style: MemeopsTextStyles.caption(context),
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          ),
        ),
      );
    },
  );
}

/// Tek hedef açıkken seçim yok: doğrudan o hedef, ikisi açıkken alttan [sheet].
Future<MemeopsShareTarget?> pickShareTarget(
  BuildContext context, {
  required bool hasTelegram,
  required bool hasVk,
}) async {
  if (hasTelegram && !hasVk) {
    return MemeopsShareTarget.telegram;
  }
  if (hasVk && !hasTelegram) {
    return MemeopsShareTarget.vk;
  }
  if (hasTelegram && hasVk) {
    if (!context.mounted) {
      return null;
    }
    return showMemeopsShareTargetSheet(context);
  }
  return null;
}
