import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

/// Adım numarası + başlık + içerik — akışları sadeleştirmek için.
class MemeopsStepSection extends StatelessWidget {
  const MemeopsStepSection({
    super.key,
    required this.step,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final int step;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: MemeopsColors.iosBlue.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                '$step',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: MemeopsColors.iosBlueBright,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: MemeopsTextStyles.sectionTitle(context).copyWith(fontSize: 17),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: MemeopsTextStyles.caption(context)),
                  ],
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: MemeopsRadii.sm + 2),
        child,
      ],
    );
  }
}
