import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_theme.dart';

class MemeopsVariantPickTile extends StatelessWidget {
  const MemeopsVariantPickTile({
    super.key,
    required this.index,
    required this.line,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final int index;
  final String line;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? MemeopsColors.iosBlue.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(MemeopsRadii.md),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(MemeopsRadii.md),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      color: selected
                          ? MemeopsColors.iosBlueBright
                          : Colors.white.withValues(alpha: 0.45),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      color: selected
                          ? MemeopsColors.iosBlueBright
                          : Colors.white.withValues(alpha: 0.92),
                      height: 1.35,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
