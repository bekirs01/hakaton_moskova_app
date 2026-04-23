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
    return MemeBriefListItem(
      id: m['id'] as String,
      briefTitle: m['brief_title'] as String?,
      suggestedCaption: m['suggested_caption_ru'] as String?,
      memotypeIdea: m['memotype_idea'] as String?,
    );
  }
}
