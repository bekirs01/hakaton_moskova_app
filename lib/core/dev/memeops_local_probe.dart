import 'dart:convert';

import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:http/http.dart' as http;

/// True if something responds on [GET /health] (Python API or Dart stub).
Future<bool> memeopsLocalHealthOk() async {
  try {
    final base = AppEnv.memeopsApiBase.replaceAll(RegExp(r'/$'), '');
    final r = await http
        .get(Uri.parse('$base/health'))
        .timeout(const Duration(seconds: 3));
    if (r.statusCode != 200) return false;
    final m = jsonDecode(r.body);
    if (m is! Map<String, dynamic>) return false;
    return m['ok'] == true;
  } catch (_) {
    return false;
  }
}
