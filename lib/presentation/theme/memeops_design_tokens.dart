import 'package:flutter/material.dart';

/// Paylaşılan görsel sabitler — köşe yarıçapları, tipografi, yüzey renkleri.
abstract final class MemeopsRadii {
  static const double sm = 14;
  static const double md = 20;
  static const double lg = 28;
  static const double xl = 32;
  static const double pill = 999;
}

abstract final class MemeopsTextStyles {
  static TextStyle displayTitle(BuildContext context) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.6,
      height: 1.15,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle sectionTitle(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  static TextStyle subtitle(BuildContext context) {
    return TextStyle(
      fontSize: 15,
      height: 1.35,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: 13,
      height: 1.35,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }
}
