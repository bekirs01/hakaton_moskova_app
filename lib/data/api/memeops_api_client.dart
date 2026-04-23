import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls MemeOps Next.js `/api/v1/*` with the user access token. No secrets in the body.
class MemeopsApiException implements Exception {
  MemeopsApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => 'MemeopsApiException($statusCode, $code): $message';
}

/// Short message for presentation-layer catch blocks (no stack traces).
String memeopsUnexpectedErrorMessage(Object error) {
  if (error is MemeopsApiException) return error.message;
  final t = error.toString().toLowerCase();
  if (t.contains('connection refused') ||
      t.contains('socketexception') ||
      t.contains('failed host lookup')) {
    return kDebugMode
        ? 'Cannot reach the MemeOps API. Run ./run_telegram_api.sh from the project root '
            '(or MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh).'
        : 'Cannot reach the server. Check your connection and try again.';
  }
  return 'Something went wrong. Please try again.';
}

class MemeopsApiClient {
  MemeopsApiClient(this._supabase);

  final SupabaseClient _supabase;

  static const _requestTimeout = Duration(seconds: 45);
  /// Image gen ~10s typical; allow headroom for OpenAI + Supabase upload in one HTTP call.
  static const _imageJobTimeout = Duration(seconds: 120);
  static const _briefBatchTimeout = Duration(seconds: 120);

  Uri _u(String path) {
    final base = AppEnv.memeopsApiBase.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path');
  }

  Future<String?> _token() async => _supabase.auth.currentSession?.accessToken;

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> _post(
    String path, {
    String? token,
    Object? body,
    Duration? timeout,
  }) async {
    final uri = _u(path);
    try {
      return await http
          .post(uri, headers: _headers(token), body: body)
          .timeout(timeout ?? _requestTimeout);
    } on TimeoutException {
      final secs = (timeout ?? _requestTimeout).inSeconds;
      throw MemeopsApiException(
        kDebugMode
            ? 'MemeOps API timed out (${uri.origin}) after ${secs}s.'
            : 'The server took too long to respond. Try again later.',
      );
    } catch (e) {
      final friendly = _connectionFailureMessage(uri, e);
      if (friendly != null) {
        throw MemeopsApiException(friendly);
      }
      rethrow;
    }
  }

  String? _connectionFailureMessage(Uri uri, Object e) {
    final t = e.toString().toLowerCase();
    if (t.contains('connection refused') ||
        t.contains('connection reset') ||
        t.contains('socketexception') ||
        t.contains('failed host lookup') ||
        t.contains('host lookup failed') ||
        t.contains('network is unreachable')) {
      if (kDebugMode) {
        return 'Cannot reach MemeOps API at ${uri.origin}. '
            'In the project root run: ./run_telegram_api.sh '
            '(Python on port ${uri.port}; needs .env with TELEGRAM_* + OPENAI_*). '
            'Or: MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh — it starts the same API then Flutter. '
            'Only without OpenAI/Telegram may you use the Dart stub: dart run tool/memeops_dev_server.dart --port ${uri.port}.';
      }
      return 'Cannot reach the MemeOps server. Check your connection and try again.';
    }
    return null;
  }

  Map<String, dynamic> _jsonOrThrow(http.Response r, String what) {
    final body = r.body;
    if (r.statusCode < 200 || r.statusCode >= 300) {
      String msg = r.reasonPhrase ?? 'HTTP $what';
      String? code;
      try {
        final m = jsonDecode(body) as Map<String, dynamic>?;
        final err = m?['error'] as Map<String, dynamic>?;
        if (err != null) {
          code = err['code'] as String?;
          msg = (err['message'] as String?) ?? msg;
        }
      } catch (_) {}
      throw MemeopsApiException(
        msg,
        statusCode: r.statusCode,
        code: code,
      );
    }
    if (body.isEmpty) {
      return {};
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }

  /// POST `/api/v1/professions` — same as web dashboard (workspace ensured server-side).
  Future<String> createProfession({
    required String title,
    String? description,
    String? futureContext,
  }) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/professions',
      token: t,
      body: jsonEncode({
        'title': title,
        'description': description,
        'futureContext': futureContext,
      }),
    );
    final m = _jsonOrThrow(res, 'create profession');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return data['id'] as String;
  }

  /// POST `/api/v1/ai/briefs/generate` — 5 batch briefs (existing web pipeline).
  Future<({String jobId, List<String> briefIds})> generateMemeBriefs(
    String professionId,
  ) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/ai/briefs/generate',
      token: t,
      body: jsonEncode({'professionId': professionId}),
      timeout: _briefBatchTimeout,
    );
    final m = _jsonOrThrow(res, 'briefs');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    final jobId = data['jobId'] as String;
    final raw = data['briefIds'] as List<dynamic>?;
    final briefIds = (raw ?? []).map((e) => e as String).toList();
    return (jobId: jobId, briefIds: briefIds);
  }

  /// POST `/api/v1/ai/jobs/image` — existing image job.
  Future<({String? fileUrl, String? assetVersionId, String? jobId})> generateImage(
    String memeBriefId,
  ) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/ai/jobs/image',
      token: t,
      body: jsonEncode({'memeBriefId': memeBriefId}),
      timeout: _imageJobTimeout,
    );
    final m = _jsonOrThrow(res, 'image');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return (
      fileUrl: data['fileUrl'] as String?,
      assetVersionId: data['assetVersionId'] as String?,
      jobId: data['jobId'] as String?,
    );
  }

  /// POST `/api/v1/telegram/channel-insights` — server parses / summarizes channel.
  Future<ChannelInsights> channelInsights(String channelUrl) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/telegram/channel-insights',
      token: t,
      body: jsonEncode({'channelUrl': channelUrl}),
      timeout: const Duration(seconds: 120),
    );
    final data =
        _jsonOrThrow(res, 'channel insights')['data'] as Map<String, dynamic>;
    return ChannelInsights.fromMap(data);
  }

  /// POST `/api/v1/telegram/meme-variants` — 5 grounded ideas (local Telethon stack).
  Future<List<MemeBriefListItem>> generateTelegramMemeVariants(
    ChannelInsights insights,
  ) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/telegram/meme-variants',
      token: t,
      body: jsonEncode({'insights': insights.toServerJson()}),
      timeout: const Duration(seconds: 90),
    );
    final m = _jsonOrThrow(res, 'meme variants');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    final raw = data['variants'] as List<dynamic>? ?? [];
    return raw
        .map((e) => MemeBriefListItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Saves channel ideas as real `meme_briefs` rows (local Python API + Telethon live only).
  Future<List<MemeBriefListItem>> persistTelegramVariants(
    ChannelInsights insights,
  ) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/telegram/persist-variants',
      token: t,
      body: jsonEncode({
        'channelUrl': insights.channelUrl,
        'insights': insights.toServerJson(),
      }),
      timeout: const Duration(seconds: 120),
    );
    final m = _jsonOrThrow(res, 'persist variants');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    final raw = data['briefs'] as List<dynamic>? ?? [];
    return raw
        .map((e) => MemeBriefListItem.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
