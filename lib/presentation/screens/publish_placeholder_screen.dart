import 'package:flutter/material.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';

/// Agent 3 shell — no outbound publishing yet; keeps a clear integration seam.
class PublishPlaceholderScreen extends StatelessWidget {
  const PublishPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final port = StubPublicationPort();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.rocket_launch, size: 48),
          const SizedBox(height: 12),
          Text('Publication', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
            'Future: take saved `meme_brief` + `asset` rows and post to connected Telegram / VK / etc. per `publish_jobs` on the web backend. Not implemented in the mobile app yet.',
          ),
          const SizedBox(height: 20),
          FilledButton.tonal(
            onPressed: () async {
              final r = await port.publishMeme(imageUrl: null, brief: null);
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(r.message ?? 'Coming soon')));
              }
            },
            child: const Text('Call PublicationPort (stub)'),
          ),
        ],
      ),
    );
  }
}
