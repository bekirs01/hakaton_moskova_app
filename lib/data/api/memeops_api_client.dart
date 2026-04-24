import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:hakaton_moskova_app/data/models/telegram_channel_post_stats.dart';
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
  final L = lookupAppLocalizations(AppLocaleController.instance.locale);
  final t = error.toString().toLowerCase();
  if (t.contains('connection refused') ||
      t.contains('socketexception') ||
      t.contains('failed host lookup')) {
    return kDebugMode ? L.errNetworkDebug : L.errNetworkUser;
  }
  return L.errUnexpected;
}

class MemeopsApiClient {
  MemeopsApiClient(this._supabase);

  final SupabaseClient _supabase;

  static const _requestTimeout = Duration(seconds: 45);
  /// Görsel: OpenAI (uzun okuma) + Supabase; Python tarafı ~15 dk + pay.
  static const _imageJobTimeout = Duration(seconds: 1200);
  static const _briefBatchTimeout = Duration(seconds: 180);
  static const _videoTokenMinValidity = Duration(minutes: 5);

  Uri _u(String path) {
    final base = AppEnv.memeopsApiBase.replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$base$path');
  }

  Future<String?> _token({Duration? minValidity, bool forceRefresh = false}) async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return null;
    }
    final min = minValidity ?? Duration.zero;
    if (forceRefresh) {
      final refreshed = await _supabase.auth.refreshSession();
      return refreshed.session?.accessToken ?? _supabase.auth.currentSession?.accessToken;
    }
    final expiresAt = session.expiresAt;
    if (expiresAt != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(
        expiresAt * 1000,
        isUtc: true,
      );
      if (expiry.difference(DateTime.now().toUtc()) <= min) {
        final refreshed = await _supabase.auth.refreshSession();
        return refreshed.session?.accessToken ?? _supabase.auth.currentSession?.accessToken;
      }
    }
    return session.accessToken;
  }

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
      final L = lookupAppLocalizations(AppLocaleController.instance.locale);
      throw MemeopsApiException(
        kDebugMode ? L.errApiTimeoutDebug(uri.origin, secs) : L.errApiTimeoutUser,
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
      final L = lookupAppLocalizations(AppLocaleController.instance.locale);
      if (kDebugMode) {
        return L.errApiUnreachableDebug(uri.origin, uri.port);
      }
      return L.errApiUnreachableUser;
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

  bool _isExpiredJwtResponse(http.Response r) {
    final body = r.body.toLowerCase();
    return (r.statusCode == 401 || r.statusCode == 403) &&
        body.contains('exp') &&
        body.contains('claim timestamp check failed');
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

  /// POST `/api/v1/ai/jobs/video` — Sora 2 video (image → animated mp4).
  /// `seconds` yalnızca "4", "8" veya "12" olabilir (Sora kısıtı).
  Future<({String? fileUrl, String? assetVersionId, String? jobId, String? seconds})>
      generateVideo(String memeBriefId, {String seconds = '4'}) async {
    var t = await _token(
      minValidity: _videoTokenMinValidity,
      forceRefresh: true,
    );
    var res = await _post(
      '/api/v1/ai/jobs/video',
      token: t,
      body: jsonEncode({'memeBriefId': memeBriefId, 'seconds': seconds}),
      timeout: _imageJobTimeout,
    );
    if (_isExpiredJwtResponse(res)) {
      t = await _token(
        minValidity: _videoTokenMinValidity,
        forceRefresh: true,
      );
      res = await _post(
        '/api/v1/ai/jobs/video',
        token: t,
        body: jsonEncode({'memeBriefId': memeBriefId, 'seconds': seconds}),
        timeout: _imageJobTimeout,
      );
    }
    final m = _jsonOrThrow(res, 'video');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return (
      fileUrl: data['fileUrl'] as String?,
      assetVersionId: data['assetVersionId'] as String?,
      jobId: data['jobId'] as String?,
      seconds: data['seconds'] as String?,
    );
  }

  /// POST `/api/v1/telegram/channel-post-stats` — Telethon ile izlenme + reaksiyon (Bot API sınırlı).
  Future<TelegramChannelPostStats> fetchTelegramChannelPostStats({
    required String channel,
    required int messageId,
  }) async {
    final t = await _token();
    final res = await _post(
      '/api/v1/telegram/channel-post-stats',
      token: t,
      body: jsonEncode({
        'channel': channel,
        'messageId': messageId,
      }),
      timeout: const Duration(seconds: 35),
    );
    final m = _jsonOrThrow(res, 'channel post stats');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return TelegramChannelPostStats.fromMap(data);
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
