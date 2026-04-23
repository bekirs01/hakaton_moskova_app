import 'dart:convert';

/// `languageCode`: `tr` veya `ru` — CLI aracı Flutter içe aktarmadan kullanabilir.
Map<String, dynamic> stubChannelInsightsData(
  String channelUrl, [
  String languageCode = 'tr',
]) {
  var label = channelUrl.trim();
  if (label.isEmpty) {
    label = 'unknown';
  } else {
    try {
      final u = Uri.parse(
        channelUrl.contains('://') ? channelUrl : 'https://$channelUrl',
      );
      if (u.pathSegments.isNotEmpty) {
        label = u.pathSegments.last.replaceAll('@', '');
      } else if (u.host.isNotEmpty) {
        label = u.host;
      }
    } catch (_) {}
  }

  final ru = languageCode == 'ru';
  return {
    'channelUrl': channelUrl,
    'channelTitle': label,
    'mainTopic': ru
        ? 'ОФЛАЙН STUB — не из Telegram. Запустите ./run_telegram_api.sh с действующей сессией TELEGRAM_*.'
        : 'ÇEVRİMDIŞI STUB — Telegram’dan değil. Geçerli TELEGRAM_* oturumu ile ./run_telegram_api.sh çalıştırın.',
    'recurringThemes': [
      '(stub)',
      ru ? 'Не загружено из канала' : 'Kanaldan yüklenmedi',
    ],
    'tone': ru ? 'offline_stub' : 'çevrimdışı_stub',
    'toneProfile': ru ? 'offline_stub' : 'stub_önizleme',
    'mediaTypes': ['stub'],
    'mediaInsights': [
      ru
          ? 'В режиме заглушки нет выборки Telegram.'
          : 'Stub modunda Telegram çekimi yok.',
    ],
    'postTypes': [
      ru ? 'stub / не подключено' : 'stub / bağlı değil',
    ],
    'recentHighlights': <String>[],
    'memeableAngles': [
      ru
          ? 'Подключите локальный Python API для реальных углов мемов.'
          : 'Gerçek meme açıları için yerel Python API’yi bağlayın.',
    ],
    'analysisSource': 'offline_stub',
  };
}

String stubChannelInsightsSuccessBody(
  String channelUrl, [
  String languageCode = 'tr',
]) {
  return jsonEncode({
    'data': stubChannelInsightsData(channelUrl, languageCode),
  });
}

String stubNotFoundBody(String message) {
  return jsonEncode({
    'error': {
      'code': 'not_found',
      'message': message,
    },
  });
}

String stubBadJsonBody() {
  return jsonEncode({
    'error': {'code': 'invalid_json', 'message': 'Invalid JSON body'},
  });
}
