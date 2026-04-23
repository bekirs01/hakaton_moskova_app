import 'package:flutter/material.dart';

class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: const [
            Text(
              'Public Supabase URL + anon key and MemeOps API base are missing. '
              'Add them in either order (no service-role or OpenAI secrets in the app):',
            ),
            SizedBox(height: 12),
            Text(
              '1) Project root `.env` (copy from env.sample) so IDE / simulator runs pick up values, or',
            ),
            SizedBox(height: 8),
            Text(
              r'2) flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=MEMEOPS_API_BASE=https://your-host',
            ),
            SizedBox(height: 12),
            Text(
              'Local Next.js: MEMEOPS_API_BASE=http://127.0.0.1:3000 (OK on iOS Simulator; use ./run_dev.sh to load `.env`).',
            ),
          ],
        ),
      ),
    );
  }
}
