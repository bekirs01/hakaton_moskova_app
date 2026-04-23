import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/widgets/language_picker_sheet.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_night_backdrop.dart';

class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: MemeopsNightBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(22),
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: l10n.languageTitle,
                  onPressed: () => showMemeopsLanguageSheet(context),
                  icon: Icon(
                    Icons.language_rounded,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
              MemeopsGlassSurface(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.configTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.configBody,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _bullet(context, l10n.configBullet1),
                    _bullet(context, l10n.configBullet2),
                    const SizedBox(height: 14),
                    Text(
                      l10n.configApiNote,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
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

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFF409CFF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
