import 'package:flutter/foundation.dart';

/// Meslek alanındaki metin; Telegram hızlı kanal önerisinde (öğrenme ↔ kanal) kullanılır.
class ProfessionHintStore {
  ProfessionHintStore._();

  static final instance = ProfessionHintStore._();

  final ValueNotifier<String> lastProfessionText = ValueNotifier('');

  void setText(String s) {
    if (lastProfessionText.value == s) return;
    lastProfessionText.value = s;
  }
}
