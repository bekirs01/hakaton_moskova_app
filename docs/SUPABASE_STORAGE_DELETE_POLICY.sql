-- Arşivden dosya silerken: `storage.from('meme-assets').remove([path])` için DELETE izni.
-- (Yalnızca SELECT/INSERT/UPDATE varsa remove 403 verir.)
-- Supabase → SQL Editor’da bir kez çalıştır.

drop policy if exists "meme assets delete" on storage.objects;

create policy "meme assets delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'meme-assets');

-- `meme_asset_versions` satırı için: mevcut `mav w` (FOR ALL) policy DELETE’i de kapsar;
-- ilave tablo policy’si gerekmez.
