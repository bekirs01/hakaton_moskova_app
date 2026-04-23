import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

class MemeopsFloatingTabItem {
  const MemeopsFloatingTabItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

/// Dar, yüzen cam sekme çubuğu — NavigationBar’dan daha kompakt.
class MemeopsFloatingTabBar extends StatelessWidget {
  const MemeopsFloatingTabBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<MemeopsFloatingTabItem> items;

  static const Duration _anim = Duration(milliseconds: 240);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final n = items.length.clamp(1, 8);
    final maxW = math.min(48.0 * n + 52, math.min(380.0, width * 0.94));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxW),
          child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MemeopsRadii.pill),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: MemeopsColors.iosBlue.withValues(alpha: 0.07),
                blurRadius: 18,
                spreadRadius: -6,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(MemeopsRadii.pill),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MemeopsRadii.pill),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.lerp(
                            const Color(0xFF1E2538),
                            Colors.white,
                            0.06,
                          )!
                          .withValues(alpha: 0.58),
                      const Color(0xFF151A28).withValues(alpha: 0.55),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      for (var i = 0; i < items.length; i++)
                        Expanded(
                          child: _TabCell(
                            item: items[i],
                            selected: i == selectedIndex,
                            onTap: () => onSelected(i),
                            animDuration: _anim,
                            animCurve: _curve,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ],
    );
  }
}

class _TabCell extends StatelessWidget {
  const _TabCell({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.animDuration,
    required this.animCurve,
  });

  final MemeopsFloatingTabItem item;
  final bool selected;
  final VoidCallback onTap;
  final Duration animDuration;
  final Curve animCurve;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.42);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: MemeopsColors.iosBlue.withValues(alpha: 0.12),
        highlightColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: animDuration,
                curve: animCurve,
                padding: EdgeInsets.symmetric(
                  horizontal: selected ? 9 : 7,
                  vertical: selected ? 6 : 5,
                ),
                decoration: BoxDecoration(
                  color: selected ? MemeopsColors.iosBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(MemeopsRadii.pill),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: MemeopsColors.iosBlue.withValues(alpha: 0.32),
                            blurRadius: 10,
                            spreadRadius: -2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: 20,
                  color: selected ? Colors.white : muted,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                curve: animCurve,
                style: TextStyle(
                  fontSize: 9,
                  height: 1.05,
                  letterSpacing: -0.15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? Colors.white : muted,
                ),
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
