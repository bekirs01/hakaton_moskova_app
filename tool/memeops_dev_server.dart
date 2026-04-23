// Local dev server: Telegram stub + Profession flow via Supabase REST (same JWT as the app).
// Run from repo root with .env exported:  dart run tool/memeops_dev_server.dart
//
// Needs env: SUPABASE_URL, SUPABASE_ANON_KEY (and optionally TELEGRAM_* only for messaging).

import 'dart:convert';
import 'dart:io';

import 'package:hakaton_moskova_app/core/dev/memeops_workspace_bootstrap.dart';
import 'package:hakaton_moskova_app/data/dev/channel_insights_stub_json.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

Future<void> main(List<String> args) async {
  var port = 3000;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.tryParse(args[i + 1]) ?? port;
    }
  }

  final server = await io.serve(
    _handler,
    InternetAddress.loopbackIPv4,
    port,
  );

  // ignore: avoid_print
  print(
    'memeops_dev_server: http://127.0.0.1:${server.port}\n'
    '  POST /api/v1/telegram/channel-insights (stub)\n'
    '  POST /api/v1/professions + /api/v1/ai/briefs/generate (needs SUPABASE_* env)',
  );
}

Future<Response> _handler(Request request) async {
  final path = request.requestedUri.path;
  if (path == '/health' && request.method == 'GET') {
    final hasSb = (Platform.environment['SUPABASE_URL'] ?? '').isNotEmpty &&
        (Platform.environment['SUPABASE_ANON_KEY'] ?? '').isNotEmpty;
    return Response.ok(
      jsonEncode({
        'ok': true,
        'stub': true,
        'telegram': false,
        'professions_via_supabase': hasSb,
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  if (path == '/api/v1/professions' && request.method == 'POST') {
    return _handleProfessions(request);
  }
  if (path == '/api/v1/ai/briefs/generate' && request.method == 'POST') {
    return _handleBriefsGenerate(request);
  }
  if (path == '/api/v1/ai/jobs/image' && request.method == 'POST') {
    return Response(
      503,
      body: jsonEncode({
        'error': {
          'code': 'needs_python_api',
          'message':
              'Meme images require ./run_telegram_api.sh with OPENAI_API_KEY.',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  if (path == '/api/v1/telegram/persist-variants' && request.method == 'POST') {
    return Response(
      503,
      body: jsonEncode({
        'error': {
          'code': 'needs_python_api',
          'message':
              'Telegram persistence requires ./run_telegram_api.sh (Telethon + OpenAI).',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  if (path != '/api/v1/telegram/channel-insights') {
    return Response(
      404,
      body: stubNotFoundBody('Unknown route: $path'),
      headers: {'content-type': 'application/json'},
    );
  }

  if (request.method != 'POST') {
    return Response(405, body: 'Method Not Allowed');
  }

  final raw = await request.readAsString();
  Map<String, dynamic> body;
  try {
    body = raw.isEmpty ? {} : jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return Response.badRequest(
      body: stubBadJsonBody(),
      headers: {'content-type': 'application/json'},
    );
  }

  final channelUrl = body['channelUrl'] as String? ?? '';

  return Response.ok(
    stubChannelInsightsSuccessBody(channelUrl),
    headers: {'content-type': 'application/json'},
  );
}

Map<String, String> _sbHeaders(String jwt, String anon) {
  return {
    'apikey': anon,
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}

Future<Response> _handleProfessions(Request request) async {
  final supaUrl = Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final anon = Platform.environment['SUPABASE_ANON_KEY']?.trim() ?? '';
  final auth = request.headers['authorization'] ?? request.headers['Authorization'];
  if (supaUrl.isEmpty || anon.isEmpty) {
    return Response(
      503,
      body: jsonEncode({
        'error': {
          'message':
              'Export SUPABASE_URL and SUPABASE_ANON_KEY (e.g. source .env) before dart run.',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  if (auth == null || !auth.toLowerCase().startsWith('bearer ')) {
    return Response(
      401,
      body: jsonEncode({'error': {'message': 'Sign in in the app first.'}}),
      headers: {'content-type': 'application/json'},
    );
  }
  final jwt = auth.substring(7).trim();
  final raw = await request.readAsString();
  final body = jsonDecode(raw) as Map<String, dynamic>;
  final base = supaUrl.replaceAll(RegExp(r'/$'), '');
  final h = _sbHeaders(jwt, anon);

  final workspaceId = await ensureDefaultWorkspaceId(
    jwt: jwt,
    supabaseUrl: supaUrl,
    anonKey: anon,
  );
  if (workspaceId == null) {
    return Response(
      502,
      body: jsonEncode({
        'error': {
          'code': 'no_workspace',
          'message':
              'Could not create workspace. Check JWT, .env SUPABASE_*, and RLS.',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
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
    return Response(pr.statusCode, body: pr.body, headers: {'content-type': 'application/json'});
  }
  final decoded = jsonDecode(pr.body);
  final row = decoded is List ? decoded[0] as Map<String, dynamic> : decoded as Map<String, dynamic>;
  return Response.ok(
    jsonEncode({'data': {'id': row['id']}}),
    headers: {'content-type': 'application/json'},
  );
}

List<String> _fiveIdeas(String title) {
  final t = title.trim().isEmpty ? 'тема' : title.trim();
  return [
    'Мем-контраст: ожидание vs реальность в «$t»',
    'Реакция аудитории на пост про «$t»',
    'Ирония над спором в нише «$t»',
    'До/после: осознание про «$t»',
    'Внутренний жаргон аудитории «$t»',
  ];
}

Future<Response> _handleBriefsGenerate(Request request) async {
  final supaUrl = Platform.environment['SUPABASE_URL']?.trim() ?? '';
  final anon = Platform.environment['SUPABASE_ANON_KEY']?.trim() ?? '';
  final auth = request.headers['authorization'] ?? request.headers['Authorization'];
  if (supaUrl.isEmpty || anon.isEmpty) {
    return Response(
      503,
      body: jsonEncode({
        'error': {
          'message': 'Export SUPABASE_URL and SUPABASE_ANON_KEY before dart run.',
        },
      }),
      headers: {'content-type': 'application/json'},
    );
  }
  if (auth == null || !auth.toLowerCase().startsWith('bearer ')) {
    return Response(
      401,
      body: jsonEncode({'error': {'message': 'Sign in in the app first.'}}),
      headers: {'content-type': 'application/json'},
    );
  }
  final jwt = auth.substring(7).trim();
  final raw = await request.readAsString();
  final body = jsonDecode(raw) as Map<String, dynamic>;
  final professionId = body['professionId'] as String?;
  if (professionId == null || professionId.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': {'message': 'professionId required'}}),
      headers: {'content-type': 'application/json'},
    );
  }
  final base = supaUrl.replaceAll(RegExp(r'/$'), '');
  final h = _sbHeaders(jwt, anon);

  final gr = await http.get(
    Uri.parse('$base/rest/v1/professions?id=eq.$professionId&select=workspace_id,title'),
    headers: h,
  );
  if (gr.statusCode >= 400) {
    return Response(gr.statusCode, body: gr.body, headers: {'content-type': 'application/json'});
  }
  final grows = jsonDecode(gr.body) as List<dynamic>;
  if (grows.isEmpty) {
    return Response(
      404,
      body: jsonEncode({'error': {'message': 'Profession not found'}}),
      headers: {'content-type': 'application/json'},
    );
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
        'suggested_caption_ru': idea.length > 900 ? idea.substring(0, 900) : idea,
        'internal_rank': i + 1,
        'is_mock': true,
      }),
    );
    if (br.statusCode >= 400) {
      return Response(br.statusCode, body: br.body, headers: {'content-type': 'application/json'});
    }
    final row = jsonDecode(br.body);
    final m = row is List ? row[0] as Map<String, dynamic> : row as Map<String, dynamic>;
    briefIds.add(m['id'] as String);
  }
  return Response.ok(
    jsonEncode({
      'data': {'jobId': 'local-brief-batch', 'briefIds': briefIds},
    }),
    headers: {'content-type': 'application/json'},
  );
}
