import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';

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

  static const Duration _anim = Duration(milliseconds: 320);
  static const Curve _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final n = items.length.clamp(1, 8);
    final maxW = math.min(64.0 * n + 44, math.min(440.0, width * 0.96));

    return RepaintBoundary(
      child: Row(
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
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
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
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF21283B).withValues(alpha: 0.78),
                          const Color(0xFF171E30).withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final cellWidth = constraints.maxWidth / items.length;
                        return SizedBox(
                          height: 72,
                          child: Stack(
                            children: [
                              AnimatedPositioned(
                                duration: _anim,
                                curve: _curve,
                                left: cellWidth * selectedIndex + 3,
                                top: 5,
                                width: cellWidth - 6,
                                height: 62,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    color: Colors.white.withValues(alpha: 0.11),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.14,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
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
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        borderRadius: BorderRadius.circular(22),
        splashColor: Colors.white.withValues(alpha: 0.08),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              AnimatedScale(
                duration: animDuration,
                curve: animCurve,
                scale: selected ? 1.0 : 0.95,
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  size: selected ? 25 : 22,
                  color: selected ? Colors.white : muted,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: animDuration,
                curve: animCurve,
                style: TextStyle(
                  fontSize: selected ? 11.0 : 10.5,
                  height: 1.1,
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
