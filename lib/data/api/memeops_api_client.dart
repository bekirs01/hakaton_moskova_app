import 'dart:convert';

import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/models/channel_insights.dart';
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

class MemeopsApiClient {
  MemeopsApiClient(this._supabase);

  final SupabaseClient _supabase;

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
    final res = await http.post(
      _u('/api/v1/professions'),
      headers: _headers(t),
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
    final res = await http.post(
      _u('/api/v1/ai/briefs/generate'),
      headers: _headers(t),
      body: jsonEncode({'professionId': professionId}),
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
    final res = await http.post(
      _u('/api/v1/ai/jobs/image'),
      headers: _headers(t),
      body: jsonEncode({'memeBriefId': memeBriefId}),
    );
    final m = _jsonOrThrow(res, 'image');
    final data = m['data'] as Map<String, dynamic>? ?? m;
    return (
      fileUrl: data['fileUrl'] as String?,
      assetVersionId: data['assetVersionId'] as String?,
      jobId: data['jobId'] as String?,
    );
  }

  /// POST `/api/v1/telegram/channel-insights` — placeholder; replace with real parser on server.
  Future<ChannelInsights> channelInsights(String channelUrl) async {
    final t = await _token();
    final res = await http.post(
      _u('/api/v1/telegram/channel-insights'),
      headers: _headers(t),
      body: jsonEncode({'channelUrl': channelUrl}),
    );
    final data =
        _jsonOrThrow(res, 'channel insights')['data'] as Map<String, dynamic>;
    return ChannelInsights.fromMap(data);
  }
}
