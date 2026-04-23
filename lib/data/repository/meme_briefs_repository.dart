import 'package:hakaton_moskova_app/data/models/meme_brief_list_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MemeBriefsRepository {
  MemeBriefsRepository(this._client);

  final SupabaseClient _client;

  Future<List<MemeBriefListItem>> listForProfession(String professionId) async {
    final r = await _client
        .from('meme_briefs')
        .select('id, brief_title, suggested_caption_ru, memotype_idea')
        .eq('profession_id', professionId)
        .order('created_at', ascending: true);
    final list = r as List<dynamic>;
    return list
        .map((e) => MemeBriefListItem.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}
