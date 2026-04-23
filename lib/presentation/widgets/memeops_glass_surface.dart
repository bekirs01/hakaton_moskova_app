import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/presentation/theme/memeops_design_tokens.dart';

/// Premium cam / buzlu panel — giriş kartı ve bölüm sarmalayıcıları için.
class MemeopsGlassSurface extends StatelessWidget {
  const MemeopsGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = MemeopsRadii.lg,
    this.padding,
    this.blurSigma = 22,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
