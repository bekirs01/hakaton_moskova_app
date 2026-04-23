import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/data/publication/publication_port_provider.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/presentation/layout/home_tab_scroll_padding.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/widgets/memeops_glass_surface.dart';

/// Agent 3 shell — no outbound publishing yet; keeps a clear integration seam.
class PublishPlaceholderScreen extends StatelessWidget {
  const PublishPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final port = createPublicationPort();
    return ListView(
      padding: homeTabScrollPadding(),
      children: [
        MemeopsGlassSurface(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.rocket_launch_rounded,
                size: 44,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.95),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.publishTitle,
                style: MemeopsTextStyles.sectionTitle(
                  context,
                ).copyWith(fontSize: 22),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.publishBody,
                style: MemeopsTextStyles.caption(context),
              ),
              const SizedBox(height: 22),
              FilledButton.tonal(
                onPressed: () async {
                  final r = await port.publishMeme(imageUrl: null, brief: null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          r.comingSoon
                              ? l10n.publicationComingSoon
                              : (r.message?.isNotEmpty == true
                                  ? r.message!
                                  : l10n.publicationDone),
                        ),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MemeopsRadii.md),
                  ),
                ),
                child: Text(l10n.publishStubButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
