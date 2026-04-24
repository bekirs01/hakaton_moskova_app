# Arşiv / Analiz — yapılan ve sınırlar

## Tarih: 2026-04-24

### 1) Analizde boş ekran (Telegram’da aslında paylaşıldı)
- **Hedef:** Paylaşım kaydı ile arşiv satırı `localArchiveId` / `supabaseVersionId` ile eşleşmeli; eşleşemezse eski hareketler için **açık + tarih** ile `caption`+`tür` üzerinden bulunabilir.
- **Telegram metrik:** Bot cevabındaki `views` (ve varsa `forwards`) kaydedilir; bölge/kitle kırılımı standart **Bot API’de yok** — gösterilmez, dipnot var.
- **Güncel izlenme:** Kanal postu için çoğu senaryoda sadece **gönderim anındaki** `views` gelir; periyodik çekmek ayrı backend veya Kullanıcı API’si ister.

### 2) “Paylaşma menüsü açılamadı”
- Ayrıntılı hata / `showModalBottomSheet` kök navigatör / `try-catch` sarımı; mesaj `archiveShareFailed` anlamsız olabilir, metin güncellenecek.
- Hedef: Önce **platform + zaman** alt sayfası, sonra ağ çağrısı; tek hata noktası.

### 3) Zamanlama
- **Şimdi:** Uygulama anında `sendPhoto` / `sendVideo` / VK.
- **İleri tarih:** Bu repo’da arka planda kuyruğa alıp uygulama kapalıyken tetikleme yok; ileri tarih seçilince açık bilgilendirme (ileride backend ile).

### 4) Arşiv üst bar
- İstenirse Analiz gibi sadece dil: `home_shell` içinde sekmeye göre ayrı (şu an arşivde hâlâ geri olabilir — son kullanıcı isteğine göre ayrı PR).
