import 'dart:convert';

/// Offline preview when no API is listening (embedded Dart stub). No Telegram calls.
Map<String, dynamic> stubChannelInsightsData(String channelUrl) {
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
    } catch (_) {
      // keep label as raw
    }
  }

  return {
    'channelUrl': channelUrl,
    'channelTitle': label,
    'mainTopic':
        'OFFLINE STUB — not from Telegram. Run ./run_telegram_api.sh with valid TELEGRAM_* session.',
    'recurringThemes': [
      '(stub)',
      'Not loaded from channel',
    ],
    'tone': 'offline_stub',
    'toneProfile': 'offline_stub',
    'mediaTypes': ['stub'],
    'mediaInsights': [
      'No Telegram fetch in stub mode.',
    ],
    'postTypes': ['stub / not connected'],
    'recentHighlights': [],
    'memeableAngles': [
      'Connect the local Python API for real meme angles.',
    ],
    'analysisSource': 'offline_stub',
  };
}

String stubChannelInsightsSuccessBody(String channelUrl) {
  return jsonEncode({'data': stubChannelInsightsData(channelUrl)});
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
