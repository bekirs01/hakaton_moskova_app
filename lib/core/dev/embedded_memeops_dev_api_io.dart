import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/core/dev/memeops_workspace_bootstrap.dart';
import 'package:hakaton_moskova_app/core/locale/app_locale_controller.dart';
import 'package:hakaton_moskova_app/l10n/app_localizations.dart';
import 'package:hakaton_moskova_app/data/dev/channel_insights_stub_json.dart';
import 'package:http/http.dart' as http;

/// Debug + iOS: if nothing is listening on the configured localhost MemeOps port,
/// bind an in-process stub so IDE / Simulator runs work without a separate terminal.
///
/// If port is already in use (e.g. `./run_telegram_api.sh`), this is a no-op.
abstract final class EmbeddedMemeopsDevApi {
  static HttpServer? _server;

  static Future<void> tryStart() async {
    if (!kDebugMode || kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    if (_server != null) return;

    final raw = AppEnv.rawMemeopsApiBase;
    if (raw.isEmpty) return;

    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    final host = uri.host.toLowerCase();
    if (host != '127.0.0.1' && host != 'localhost') return;

    final port = uri.hasPort
        ? uri.port
        : (uri.scheme == 'https' ? 443 : 80);

    HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      return;
    }

    _server = server;
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        'embedded_memeops_dev: http://127.0.0.1:$port\n'
        '  stub Telegram: POST /api/v1/telegram/channel-insights\n'
        '  Profession: POST /api/v1/professions, /api/v1/ai/briefs/generate (uses app Supabase env)',
      );
    }

    server.listen(_onRequest);
  }

  static Future<void> _onRequest(HttpRequest request) async {
    try {
      await _handleRequest(request);
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {}
    }
  }

  static Map<String, String> _sbHeaders(String jwt, String anon) {
    return {
      'apikey': anon,
      'Authorization': 'Bearer $jwt',
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };
  }

  static List<String> _fiveIdeas(String title) {
    final l10n = lookupAppLocalizations(AppLocaleController.instance.locale);
    final t = title.trim().isEmpty ? l10n.stubDefaultTopic : title.trim();
    return [
      l10n.stubProfessionIdea1(t),
      l10n.stubProfessionIdea2(t),
      l10n.stubProfessionIdea3(t),
      l10n.stubProfessionIdea4(t),
      l10n.stubProfessionIdea5(t),
    ];
  }

  static Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;
    request.response.headers.contentType = ContentType.json;

    final supaUrl = AppEnv.supabaseUrl.trim();
    final anon = AppEnv.supabaseAnonKey.trim();
    final hasSb = supaUrl.isNotEmpty && anon.isNotEmpty;

    if (request.method == 'GET' && path == '/health') {
      request.response.statusCode = HttpStatus.ok;
      request.response.write(
        jsonEncode({
          'ok': true,
          'stub': true,
          'telegram': false,
          'professions_via_supabase': hasSb,
        }),
      );
      await request.response.close();
      return;
    }

    if (path == '/api/v1/professions' && request.method == 'POST') {
      await _writeProfessions(request, supaUrl, anon);
      return;
    }
    if (path == '/api/v1/ai/briefs/generate' && request.method == 'POST') {
      await _writeBriefsGenerate(request, supaUrl, anon);
      return;
    }
    if (path == '/api/v1/ai/jobs/image' && request.method == 'POST') {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode({
          'error': {
            'code': 'needs_python_api',
            'message':
                'Meme images need ./run_telegram_api.sh with OPENAI_API_KEY in API .env.',
          },
        }),
      );
      await request.response.close();
      return;
    }
    if (path == '/api/v1/telegram/persist-variants' && request.method == 'POST') {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode({
          'error': {
            'code': 'needs_python_api',
            'message':
                'Saving Telegram ideas needs ./run_telegram_api.sh (Telethon + OpenAI).',
          },
        }),
      );
      await request.response.close();
      return;
    }

    if (path == '/api/v1/telegram/channel-post-stats' && request.method == 'POST') {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode({
          'error': {
            'code': 'needs_python_api',
            'message':
                'Post stats (views/reactions) need ./run_telegram_api.sh with Telethon session.',
          },
        }),
      );
      await request.response.close();
      return;
    }

    final isInsights =
        path == '/api/v1/telegram/channel-insights' && request.method == 'POST';

    if (!isInsights) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(
        stubNotFoundBody('Unknown route: $path'),
      );
      await request.response.close();
      return;
    }

    final rawBody = await utf8.decoder.bind(request).join();
    String channelUrl;
    try {
      final map = rawBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rawBody) as Map<String, dynamic>;
      channelUrl = map['channelUrl'] as String? ?? '';
    } catch (_) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(stubBadJsonBody());
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      stubChannelInsightsSuccessBody(
        channelUrl,
        AppLocaleController.instance.locale.languageCode,
      ),
    );
    await request.response.close();
  }

  static Future<void> _writeProfessions(
    HttpRequest request,
    String supaUrl,
    String anon,
  ) async {
    if (supaUrl.isEmpty || anon.isEmpty) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode({
          'error': {
            'message':
                'SUPABASE_URL / SUPABASE_ANON_KEY missing in app .env or dart-define.',
          },
        }),
      );
      await request.response.close();
      return;
    }
    final auth = request.headers.value('Authorization') ??
        request.headers.value('authorization');
    if (auth == null || !auth.toLowerCase().startsWith('bearer ')) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(
        jsonEncode({'error': {'message': 'Sign in in the app first.'}}),
      );
      await request.response.close();
      return;
    }
    final jwt = auth.substring(7).trim();
    final rawBody = await utf8.decoder.bind(request).join();
    final body = jsonDecode(rawBody) as Map<String, dynamic>;
    final base = supaUrl.replaceAll(RegExp(r'/$'), '');
    final h = _sbHeaders(jwt, anon);

    final workspaceId = await ensureDefaultWorkspaceId(
      jwt: jwt,
      supabaseUrl: supaUrl,
      anonKey: anon,
    );
    if (workspaceId == null) {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write(
        jsonEncode({
          'error': {
            'code': 'no_workspace',
            'message':
                'Could not create workspace. Check sign-in and Supabase policies.',
          },
        }),
      );
      await request.response.close();
      return;
    }
    final payload = jsonEncode({
      'workspace_id': workspaceId,
      'title': body['title'],
      'description': body['description'],
      'future_context': body['futureContext'],
    });
    final pr = await http.post(
      Uri.parse('$base/rest/v1/professions'),
      headers: h,
      body: payload,
    );
    if (pr.statusCode >= 400) {
      request.response.statusCode = pr.statusCode;
      request.response.write(pr.body);
      await request.response.close();
      return;
    }
    final decoded = jsonDecode(pr.body);
    final row = decoded is List
        ? decoded[0] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    request.response.statusCode = HttpStatus.ok;
    request.response.write(jsonEncode({'data': {'id': row['id']}}));
    await request.response.close();
  }

  static Future<void> _writeBriefsGenerate(
    HttpRequest request,
    String supaUrl,
    String anon,
  ) async {
    if (supaUrl.isEmpty || anon.isEmpty) {
      request.response.statusCode = HttpStatus.serviceUnavailable;
      request.response.write(
        jsonEncode({
          'error': {
            'message':
                'SUPABASE_URL / SUPABASE_ANON_KEY missing in app .env or dart-define.',
          },
        }),
      );
      await request.response.close();
      return;
    }
    final auth = request.headers.value('Authorization') ??
        request.headers.value('authorization');
    if (auth == null || !auth.toLowerCase().startsWith('bearer ')) {
      request.response.statusCode = HttpStatus.unauthorized;
      request.response.write(
        jsonEncode({'error': {'message': 'Sign in in the app first.'}}),
      );
      await request.response.close();
      return;
    }
    final jwt = auth.substring(7).trim();
    final rawBody = await utf8.decoder.bind(request).join();
    final body = jsonDecode(rawBody) as Map<String, dynamic>;
    final professionId = body['professionId'] as String?;
    if (professionId == null || professionId.isEmpty) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write(
        jsonEncode({'error': {'message': 'professionId required'}}),
      );
      await request.response.close();
      return;
    }
    final base = supaUrl.replaceAll(RegExp(r'/$'), '');
    final h = _sbHeaders(jwt, anon);

    final gr = await http.get(
      Uri.parse(
        '$base/rest/v1/professions?id=eq.$professionId&select=workspace_id,title',
      ),
      headers: h,
    );
    if (gr.statusCode >= 400) {
      request.response.statusCode = gr.statusCode;
      request.response.write(gr.body);
      await request.response.close();
      return;
    }
    final grows = jsonDecode(gr.body) as List<dynamic>;
    if (grows.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      request.response.write(
        jsonEncode({'error': {'message': 'Profession not found'}}),
      );
      await request.response.close();
      return;
    }
    final g0 = grows[0] as Map<String, dynamic>;
    final wid = g0['workspace_id'];
    final title = g0['title'] as String? ?? '';
    final ideas = _fiveIdeas(title);
    final briefIds = <String>[];
    for (var i = 0; i < ideas.length; i++) {
      final idea = ideas[i];
      final br = await http.post(
        Uri.parse('$base/rest/v1/meme_briefs'),
        headers: h,
        body: jsonEncode({
          'workspace_id': wid,
          'profession_id': professionId,
          'brief_title': idea.length > 200 ? idea.substring(0, 200) : idea,
          'memotype_idea': idea,
          'suggested_caption_ru':
              idea.length > 900 ? idea.substring(0, 900) : idea,
          'internal_rank': i + 1,
          'is_mock': true,
        }),
      );
      if (br.statusCode >= 400) {
        request.response.statusCode = br.statusCode;
        request.response.write(br.body);
        await request.response.close();
        return;
      }
      final row = jsonDecode(br.body);
      final m = row is List
          ? row[0] as Map<String, dynamic>
          : row as Map<String, dynamic>;
      briefIds.add(m['id'] as String);
    }
    request.response.statusCode = HttpStatus.ok;
    request.response.write(
      jsonEncode({
        'data': {'jobId': 'local-brief-batch', 'briefIds': briefIds},
      }),
    );
    await request.response.close();
  }
}
