import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';

class TelegramAnalysisStore {
  TelegramAnalysisStore._();

  static final instance = TelegramAnalysisStore._();

  final ValueNotifier<ChannelInsights?> current = ValueNotifier<ChannelInsights?>(
    null,
  );

  void set(ChannelInsights? insights) {
    current.value = insights;
  }
}
