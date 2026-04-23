import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';

/// Future: push saved memes to connected channels. Stub only.
abstract class PublicationPort {
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
  });
}

class PublicationResult {
  const PublicationResult({required this.comingSoon, this.message});
  final bool comingSoon;
  final String? message;
}

class StubPublicationPort implements PublicationPort {
  @override
  Future<PublicationResult> publishMeme({
    required String? imageUrl,
    required MemeBriefListItem? brief,
  }) async {
    return const PublicationResult(
      comingSoon: true,
      message: 'Publication pipeline not wired yet.',
    );
  }
}
