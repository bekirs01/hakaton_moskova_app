import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

Future<void> showMemeopsLanguageSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final current = AppLocaleController.instance.locale;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: MemeopsColors.surfaceCharcoal,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(MemeopsRadii.lg)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.languageTitle,
                  style: MemeopsTextStyles.sectionTitle(ctx).copyWith(fontSize: 20),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  l10n.languagePickHint,
                  style: MemeopsTextStyles.caption(ctx),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(l10n.languageTurkish, style: const TextStyle(color: Colors.white)),
                trailing: current.languageCode == 'tr'
                    ? const Icon(Icons.check_rounded, color: MemeopsColors.iosBlueBright)
                    : null,
                onTap: () async {
                  await AppLocaleController.instance.setLocale(const Locale('tr'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text(l10n.languageRussian, style: const TextStyle(color: Colors.white)),
                trailing: current.languageCode == 'ru'
                    ? const Icon(Icons.check_rounded, color: MemeopsColors.iosBlueBright)
                    : null,
                onTap: () async {
                  await AppLocaleController.instance.setLocale(const Locale('ru'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
