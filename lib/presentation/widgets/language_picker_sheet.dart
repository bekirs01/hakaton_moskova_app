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
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MemeopsColors.surfaceCharcoal.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(MemeopsRadii.xl),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.languageTitle,
                    style: MemeopsTextStyles.sectionTitle(
                      ctx,
                    ).copyWith(fontSize: 21),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.languagePickHint,
                    style: MemeopsTextStyles.caption(ctx).copyWith(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _LanguageTile(
                    label: l10n.languageTurkish,
                    preview: 'Arayuz tamamen Turkce olur',
                    selected: current.languageCode == 'tr',
                    onTap: () async {
                      await AppLocaleController.instance.setLocale(
                        const Locale('tr'),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                  const SizedBox(height: 10),
                  _LanguageTile(
                    label: l10n.languageRussian,
                    preview: 'Интерфейс полностью будет на русском',
                    selected: current.languageCode == 'ru',
                    onTap: () async {
                      await AppLocaleController.instance.setLocale(
                        const Locale('ru'),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.preview,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String preview;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MemeopsRadii.md),
            border: Border.all(
              color: selected
                  ? MemeopsColors.iosBlueBright.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.08),
            ),
            gradient: selected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      MemeopsColors.iosBlue.withValues(alpha: 0.24),
                      MemeopsColors.surfaceCharcoal.withValues(alpha: 0.92),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.04),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  selected ? Icons.check_rounded : Icons.language_rounded,
                  color: selected
                      ? MemeopsColors.iosBlueBright
                      : Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: MemeopsTextStyles.sectionTitle(
                        context,
                      ).copyWith(fontSize: 17),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preview,
                      style: MemeopsTextStyles.caption(context),
                    ),
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
