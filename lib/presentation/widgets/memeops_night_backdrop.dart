import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';
import 'package:hakaton_moskova_app/presentation/widgets/snow_background.dart';

/// Gece gradyanı + hafif derinlik + kar. İçerik üstte.
class MemeopsNightBackdrop extends StatelessWidget {
  const MemeopsNightBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                MemeopsColors.bgTop,
                MemeopsColors.bgMid,
                MemeopsColors.bgBottom,
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.5),
              radius: 1.15,
              colors: [
                MemeopsColors.iosBlue.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        const Positioned.fill(child: SnowBackground()),
        Positioned.fill(child: child),
      ],
    );
  }
}
