import 'dart:convert';

import 'package:http/http.dart' as http;

/// Reads JWT `sub` (Supabase user id). No signature verification — same process as the client.
String? memeopsJwtAccessSub(String jwt) {
  final parts = jwt.split('.');
  if (parts.length != 3) return null;
  try {
    var segment = parts[1];
    switch (segment.length % 4) {
      case 1:
        segment += '===';
      case 2:
        segment += '==';
      case 3:
        segment += '=';
    }
    final map = jsonDecode(utf8.decode(base64Url.decode(segment)))
        as Map<String, dynamic>;
    return map['sub'] as String?;
  } catch (_) {
    return null;
  }
}

Map<String, String> _sbHeaders(String jwt, String anon) {
  return {
    'apikey': anon,
    'Authorization': 'Bearer $jwt',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };
}

/// Ensures [workspace_members] has at least one row for this user (MVP: no separate onboarding UI).
Future<String?> ensureDefaultWorkspaceId({
  required String jwt,
  required String supabaseUrl,
  required String anonKey,
}) async {
  final base = supabaseUrl.trim().replaceAll(RegExp(r'/$'), '');
  final h = _sbHeaders(jwt, anonKey);

  var wr = await http.get(
    Uri.parse('$base/rest/v1/workspace_members?select=workspace_id&limit=1'),
    headers: h,
  );
  if (wr.statusCode >= 400) return null;
  final existing = jsonDecode(wr.body) as List<dynamic>;
  if (existing.isNotEmpty) {
    return (existing.first as Map<String, dynamic>)['workspace_id'] as String?;
  }

  final sub = memeopsJwtAccessSub(jwt);
  if (sub == null) return null;

  for (var attempt = 0; attempt < 8; attempt++) {
    final slug =
        'w-${DateTime.now().microsecondsSinceEpoch}-$attempt-${sub.substring(0, 8)}';
    final ws = await http.post(
      Uri.parse('$base/rest/v1/workspaces'),
      headers: h,
      body: jsonEncode({
        'name': 'Workspace',
        'slug': slug,
        'created_by': sub,
      }),
    );
    if (ws.statusCode == 409) continue;
    if (ws.statusCode >= 400) return null;

    final decoded = jsonDecode(ws.body);
    final row = decoded is List
        ? decoded[0] as Map<String, dynamic>
        : decoded as Map<String, dynamic>;
    final wid = row['id'] as String;

    final mb = await http.post(
      Uri.parse('$base/rest/v1/workspace_members'),
      headers: h,
      body: jsonEncode({
        'workspace_id': wid,
        'user_id': sub,
        'role': 'admin',
      }),
    );
    if (mb.statusCode >= 400) return null;
    return wid;
  }
  return null;
}
