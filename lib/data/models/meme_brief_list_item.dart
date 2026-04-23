/// Matches server `meme_briefs` list projection used in the app.
class MemeBriefListItem {
  const MemeBriefListItem({
    required this.id,
    this.briefTitle,
    this.suggestedCaption,
    this.memotypeIdea,
  });

  final String id;
  final String? briefTitle;
  final String? suggestedCaption;
  final String? memotypeIdea;

  String get displayLine =>
      (briefTitle?.trim().isNotEmpty == true
          ? briefTitle
          : suggestedCaption) ??
      memotypeIdea ??
      id;

  factory MemeBriefListItem.fromMap(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    return MemeBriefListItem(
      id: id,
      briefTitle: (m['brief_title'] ?? m['briefTitle']) as String?,
      suggestedCaption: (m['suggested_caption_ru'] ?? m['suggestedCaption']) as String?,
      memotypeIdea: (m['memotype_idea'] ?? m['memotypeIdea']) as String?,
    );
  }

  /// Local Python API variants cannot drive hosted image jobs.
  bool get isLocalPythonVariant => id.startsWith('local-mv-');
}
