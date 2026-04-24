// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'MemeOps';

  @override
  String get defaultDisplayName => 'üretici';

  @override
  String greeting(String name) {
    return 'İyi günler, $name';
  }

  @override
  String get backToLogin => 'Giriş ekranına dön';

  @override
  String get homeSubtitle => 'Meme akışına devam et — aşağıdan sekme seç.';

  @override
  String get tabProfession => 'Meslek';

  @override
  String get tabTelegram => 'Telegram';

  @override
  String get tabAnalysis => 'Analiz';

  @override
  String get tabPublish => 'Yayın';

  @override
  String get tabArchive => 'Arşiv';

  @override
  String get languageTitle => 'Dil';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languagePickHint =>
      'Uygulama dilini seçin. Tüm metinler buna göre değişir.';

  @override
  String get authTagline => 'Mizah fikirleri ve görseller — tek akışta';

  @override
  String get authSignInTitle => 'Giriş yap';

  @override
  String get authUsername => 'Kullanıcı adı';

  @override
  String get authUsernameHint => 'admin';

  @override
  String get authPassword => 'Şifre';

  @override
  String get authPasswordHint => '12345678';

  @override
  String get authSignIn => 'Giriş yap';

  @override
  String get authSignUp => 'İlk kurulum: kayıt oluştur (admin + şifre)';

  @override
  String get authErrEmptyUser => 'Kullanıcı adını girin.';

  @override
  String get authErrNoAt => 'Sadece kullanıcı adı yazın (@ ve e-posta yok).';

  @override
  String get authErrPasswordShort =>
      'Şifre en az 6 karakter olsun (örn. 12345678).';

  @override
  String get authErrInvalidLogin =>
      'Bu kullanıcı Supabase’te yok veya şifre uyuşmuyor. Alttaki «İlk kurulum: kayıt oluştur» ile dene, ya da Dashboard’da Authentication → Users ile kullanıcı ekle.';

  @override
  String get authErrAlreadyRegistered =>
      'Bu kullanıcı zaten var. Doğrudan «Giriş yap» kullan.';

  @override
  String get authSnackSignUp =>
      'Kayıt oluşturuldu. Giriş olmadıysa: Supabase → Authentication → Providers → «Confirm email» kapatıp tekrar dene, veya e-postadaki linke tıkla.';

  @override
  String get authBenefitTitle => 'Giriş yapınca neler kazanırsın?';

  @override
  String get authBenefitTelegram =>
      'Telegram kanalından canlı özet ve fikirler';

  @override
  String get authBenefitProfession => 'Meslek / konuya göre AI durum mizahı';

  @override
  String get authBenefitImage => 'gpt-image-1 ile kare meme görseli';

  @override
  String get authBenefitSupabase => 'Supabase’de brief ve görsel sürümleri';

  @override
  String get configTitle => 'Yapılandırma';

  @override
  String get configBody =>
      'Public Supabase URL + anon key ve MemeOps API tabanı eksik. Uygulamada servis rolü veya OpenAI anahtarı yok:';

  @override
  String get configBullet1 =>
      '1) Proje kökünde `.env` (env.sample’dan kopyala) — IDE / simülatör bu dosyayı okur.';

  @override
  String get configBullet2 =>
      '2) flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=MEMEOPS_API_BASE=https://...';

  @override
  String get configApiNote =>
      'Yerel API: MEMEOPS_API_BASE=http://127.0.0.1:3000 (iOS Simülatör uyumlu; ./run_dev.sh veya ./run_telegram_api.sh).';

  @override
  String get archiveTitle => 'Arşiv';

  @override
  String get archiveSubtitle =>
      'Yerel üretimler bu cihazda; aynı hesabın Supabase’deki görseller ve videolar aşağıda birleşir. Filtreyle cihaz / bulut ayrılabilir.';

  @override
  String get archiveSourceCloud => 'Supabase';

  @override
  String get archiveSupabaseLoadError =>
      'Hesabındaki sunucu medyaları yüklenemedi. Yerel arşiv gösteriliyor.';

  @override
  String get archiveFilterAll => 'Tümü';

  @override
  String get archiveFilterLocal => 'Bu cihaz';

  @override
  String get archiveFilterCloud => 'Supabase';

  @override
  String get archiveEmpty =>
      'Henüz kayıtlı görsel yok.\nMeslek veya Telegram sekmesinden meme üret.';

  @override
  String get archiveFileMissing => 'Dosya bulunamadı (silinmiş olabilir).';

  @override
  String get archiveShare => 'Paylaş';

  @override
  String get archiveVideoErrorTitle => 'Video açılamadı';

  @override
  String get archiveShareFailed => 'Paylaşma menüsü açılamadı.';

  @override
  String archiveShareFailedWithError(String error) {
    return 'Paylaşma: $error';
  }

  @override
  String get archiveShareSheetSubtitle =>
      'Telegram veya VK. Zamanlama ve metin düzenleme: arşivde öğenin içine girin.';

  @override
  String get archiveCaptionLabel => 'Gönderi metni';

  @override
  String get archiveCaptionSave => 'Metni kaydet';

  @override
  String get archiveCaptionSaved => 'Metin kaydedildi.';

  @override
  String get archiveCaptionCloudNeedsBrief =>
      'Bu bulut kaydında brief bağlantısı yok; metin yalnızca bu gönderim için kullanılır.';

  @override
  String get archivePublishTitle => 'Paylaşım';

  @override
  String get archiveTelegramSmartRoutingTitle =>
      'Telegram: akıllı kanal önerisi';

  @override
  String archiveTelegramSmartRoutingHint(String channel) {
    return 'Metin ve başlığa göre «$channel» öne çıkıyor. Aşağıdan istediğin kanalları işaretle; birden fazlasına aynı gönderi gidebilir.';
  }

  @override
  String get archiveTelegramSuggestedBadge => 'Önerilen';

  @override
  String get archivePlatformNameTelegram => 'Telegram';

  @override
  String get archivePlatformNameVk => 'VK';

  @override
  String get archivePlatformNameDzen => 'Dzen';

  @override
  String get archiveWeRecommendTitle => 'Size şunu öneriyoruz';

  @override
  String get archiveTelegramRecMatchesThisPost => 'Bu gönderiyle en uyumlu';

  @override
  String archiveTelegramRecCategoryName(String category, String name) {
    return '$category → $name';
  }

  @override
  String get archiveTelegramRecFooter =>
      'Metin ve başlıktaki kelimelere göre (kozmetik, okul vb.) uyumlu kanal yıldızla işaretlenir. VK ve Dzen: yalnızca «paylaşıldı» (Telegram dışı gerçek istek yok).';

  @override
  String get archivePublishChannelsSubtitle =>
      'Telegram, VK, Dzen. Alttaki kartlar sadece Telegram hedefi içindir.';

  @override
  String get archivePublishSelectAtLeastOneChannel => 'En az bir kanal seçin.';

  @override
  String get archivePublishWhenHeading => 'Gönderim zamanı';

  @override
  String get archivePublishWhenNow => 'Hemen gönder';

  @override
  String get archivePublishWhenSchedule => 'İleri tarih';

  @override
  String get archivePublishPickDateTime => 'Tarih ve saat seç';

  @override
  String get archivePublishSubmit => 'Gönder';

  @override
  String archivePublishScheduledAck(String when) {
    return 'Zamanlandı: $when';
  }

  @override
  String get archivePublishChooseSchedule => 'Önce tarih ve saat seçin.';

  @override
  String get archivePublishSchedulePast => 'Zaman geçmiş olamaz.';

  @override
  String get archivePublishScheduleNeedOpenApp =>
      'Uygulama açıkken sıraya alınır; tamamen kapalıysa gönderim gecikebilir.';

  @override
  String archiveDownloadFailed(int code) {
    return 'Görsel indirilemedi (HTTP $code).';
  }

  @override
  String get archiveListLoadError =>
      'Liste açılırken beklenmeyen bir gecikme oldu. Aşağı çekerek yenile.';

  @override
  String get archiveEntryDeleteTitle => 'Silinsin mi?';

  @override
  String get archiveEntryDeleteMessage =>
      'Bu kayıt kalıcı olarak silinir. Supabase satırı (ve mümkünse dosya) kaldırılır; yerel dosya da silinir.';

  @override
  String get archiveEntryDelete => 'Sil';

  @override
  String get archiveEntryDeleteCancel => 'Vazgeç';

  @override
  String get publishTitle => 'Yayın';

  @override
  String get publishBody =>
      'İleride: kayıtlı `meme_brief` + `asset` satırlarını bağlı Telegram / VK vb. kanallara `publish_jobs` ile göndermek. Mobil uygulamada henüz yok.';

  @override
  String get publishStubButton => 'PublicationPort’u çağır (stub)';

  @override
  String get publicationComingSoon => 'Yayın hattı henüz bağlı değil.';

  @override
  String get publicationDone => 'Tamam';

  @override
  String get shareTargetTitle => 'Nereye paylaşılsın?';

  @override
  String get shareTargetSubtitle =>
      'Hedefi seç; ağ isteği sadece bu paylaşım için gider.';

  @override
  String get shareTargetTelegram => 'Telegram';

  @override
  String get shareTargetVk => 'ВКонтакте (grup duvarı)';

  @override
  String get shareTargetDzen => 'Дзен';

  @override
  String get shareNoServiceConfigured =>
      'Paylaşım için .env içinde TELEGRAM_PUBLISH_* veya VK_ACCESS_TOKEN + VK_GROUP_ID gerekir; Dzen ayrıca her zaman (simüle) seçilebilir.';

  @override
  String get archivePublishNoTgVkDzenOnly =>
      'Telegram ve VK .env’te tanımlı değil. Aşağıdan Dzen’i (simülasyon) seçebilirsin.';

  @override
  String get dzenPublishSimulated => 'Dzen: paylaşım kaydedildi.';

  @override
  String get vkPostDone => 'VK’da paylaşıldı.';

  @override
  String get vkPostFailed => 'VK paylaşımı başarısız.';

  @override
  String get vkPostNeedUserToken =>
      'VK: topluluk (grup) access token resim/gönderi yükleyemez. .env’e kullanıcı OAuth token ekle: VK_USER_ACCESS_TOKEN= (kapsam: wall, photos, video, groups, offline). Proje kökünde: ./setup_vk_user_token.sh';

  @override
  String get analysisTitle => 'Telegram analizi';

  @override
  String get analysisSubtitle =>
      'Canlı analizden gelen sinyalleri burada topla; hangi saatler, hangi formatlar ve hangi gönderi tipleri daha güçlü görünüyor hızlıca gör.';

  @override
  String get analysisEmpty =>
      'Önce Telegram sekmesinden bir kanal analiz et. Son sonuç burada görünür.';

  @override
  String get analysisOverview => 'Genel görünüm';

  @override
  String get analysisSampleSize => 'İncelenen gönderi';

  @override
  String get analysisSource => 'Kaynak';

  @override
  String get analysisSourceLive => 'Canlı Telethon analizi';

  @override
  String get analysisSourceStub => 'Stub / sınırlı veri';

  @override
  String get analysisActivity => 'Aktif zaman aralıkları';

  @override
  String get analysisNoActivity => 'Henüz aktif zaman aralığı verisi yok.';

  @override
  String get analysisTopPosts => 'Öne çıkan gönderiler';

  @override
  String get analysisNoTopPosts => 'Henüz öne çıkan gönderi verisi yok.';

  @override
  String get analysisAudience => 'Kitle ve etkileşim sinyalleri';

  @override
  String get analysisNoAudience => 'Henüz etkileşim sinyali yok.';

  @override
  String get analysisOpportunities => 'İçerik fırsatları';

  @override
  String get analysisNoOpportunities => 'Henüz içerik fırsatı çıkarılamadı.';

  @override
  String get analysisMyPublications => 'Bu cihazdan kanala paylaştıkların';

  @override
  String get analysisMyPublicationsBody =>
      'Telegram veya VK’ya arşivden paylaştığında burada listelenir: Telegram’da mesaj no ve izlenme; VK’da duvar gönderi no. Detayda metrikleri görebilir, VK’da yenile ile güncelleyebilirsin. Kanal analizi aşağıda devam eder.';

  @override
  String get analysisNoMyPublications =>
      'Bu uygulamadan henüz kanal paylaşımı yok. Meslek / Telegram veya Arşiv’deki paylaş akışını dene.';

  @override
  String get analysisEmptyVideoGrid =>
      'Henüz paylaştığın video yok. Arşivden videoyu Telegram veya VK’ya paylaş; burada ızgarada görünür.';

  @override
  String get analysisNotSharedTitle => 'Henüz bu içerik için metrik yok';

  @override
  String get analysisNotSharedBody =>
      'Bu medya arşivde kayıtlı ancak uygulamadan Telegram / VK’ya eşleşen bir paylaşım yok. Arşivden paylaş; sonraki açılışlarda burada izlenme ve (VK’da) beğeni / paylaşım görebilirsin. Eski paylaşımlar kimlik eşleşmediyse de boş kalabilir.';

  @override
  String get analysisOpenPreview => 'Önizleme aç';

  @override
  String analysisViewCount(int n) {
    return '$n izlenme';
  }

  @override
  String get analysisViewUnknown => 'izlenme: —';

  @override
  String get analysisPostKindImage => 'Görsel';

  @override
  String get analysisPostKindVideo => 'Video';

  @override
  String get analysisPlatformTelegram => 'Telegram';

  @override
  String get analysisPlatformVk => 'VK';

  @override
  String get myPubSummaryTitle => 'Paylaşım özeti';

  @override
  String get myPubSummaryEmpty =>
      'Bu cihazda henüz kayıtlı paylaşım yok. Arşivden paylaş; sayılar yüklenince burada dolar.';

  @override
  String get myPubSummaryTotalLabel => 'Toplam paylaşım';

  @override
  String get myPubSummaryViewsLabel => 'Toplam izlenme (bilinen)';

  @override
  String get myPubSummaryByType => 'İçerik türü (adet)';

  @override
  String get myPubSummaryByPlatform => 'Platform (adet)';

  @override
  String myPubSummaryRolling(int cur, int prev) {
    return 'Son 7 gün: $cur paylaşım · önceki 7 gün: $prev paylaşım';
  }

  @override
  String get myPubSummaryChartTitle => 'Son 7 gün — günlük paylaşım adedi';

  @override
  String get myPubSummaryTypeViews => 'Türe göre toplam izlenme';

  @override
  String get myPubSummaryPlatformViews => 'Platforma göre toplam izlenme';

  @override
  String get myPubSummaryBest => 'En çok izlenen (kayıtlı)';

  @override
  String get myPubSummaryDzenLabel => 'Dzen';

  @override
  String get myPubSummaryDzenNoViews => 'Dzen simüle: izlenme sayılmaz.';

  @override
  String get myPubImageShort => 'Görsel';

  @override
  String get myPubVideoShort => 'Video';

  @override
  String get myPubOpenFullAnalytics => 'Tüm paylaşım analizi';

  @override
  String get myPubOpenFullAnalyticsSubtitle =>
      'Grafikler, özet ve her gönderi için önizleme + izlenme';

  @override
  String get myPubFullPageTitle => 'Detay analiz';

  @override
  String get myPubPerPostListTitle => 'Gönderiler (izlenmeye göre, önizlemeli)';

  @override
  String get myPubPerPostNoThumb => '—';

  @override
  String get myPubViewUnknown => 'İzlenme: bilinmiyor';

  @override
  String get myPubPlatformVkTr => 'VK';

  @override
  String get publicationDetailTitle => 'Paylaşım detayı';

  @override
  String get publicationDetailSectionInfo => 'Bilgiler';

  @override
  String get publicationDetailPublishedAt => 'Yayın';

  @override
  String get publicationDetailRefreshTelegram => 'Telegram metriklerini yenile';

  @override
  String get publicationDetailRefreshVk => 'VK istatistiklerini yenile';

  @override
  String get publicationDetailReactions => 'Reaksiyonlar';

  @override
  String get publicationDetailReactionsEmpty => '—';

  @override
  String publicationDetailEmojiReaction(String emoji, int count) {
    return '$emoji  ×$count';
  }

  @override
  String publicationDetailCustomReaction(int count) {
    return 'Özel  ×$count';
  }

  @override
  String publicationDetailReactionCountOnly(int count) {
    return '×$count';
  }

  @override
  String get publicationDetailKind => 'Tür';

  @override
  String get publicationDetailMessageId => 'Mesaj';

  @override
  String get publicationDetailChat => 'Sohbet';

  @override
  String get publicationDetailChannel => 'Kanal (Telegram)';

  @override
  String get publicationDetailViews => 'İzlenme';

  @override
  String get publicationDetailForwards => 'İletme (Telegram)';

  @override
  String get publicationDetailVkGroup => 'Grup';

  @override
  String get publicationDetailVkPost => 'Gönderi';

  @override
  String get publicationDetailVkHint => 'Yenile ile çekilebilir';

  @override
  String get publicationDetailLikes => 'Beğeni';

  @override
  String get publicationDetailReposts => 'Paylaşım';

  @override
  String get publicationDetailCaption => 'Açıklama';

  @override
  String get publicationDetailTabAll => 'Tümü';

  @override
  String get publicationDetailTabDzen => 'Dzen';

  @override
  String get publicationDetailDzen => 'Durum';

  @override
  String get publicationDetailDzenBody => 'Simülasyon; gerçek metrik yok.';

  @override
  String get publicationDetailMembers => 'Topluluk (abone)';

  @override
  String get publicationDetailTgReplies => 'Yorum (tartışma)';

  @override
  String get publicationDetailTgMessageTime => 'Gönderi saati (Telegram)';

  @override
  String get publicationDetailComments => 'Yorum';

  @override
  String get publicationDetailStatsNotFound =>
      'Gönderi bu oturumda bulunamadı. Kanal ve mesaj no ile eşleşmeyi kontrol edin; API: ./run_telegram_api.sh';

  @override
  String get publicationDetailRefreshAll => 'Yenile';

  @override
  String get professionStep1Title => 'Meslek veya konu';

  @override
  String get professionStep1Subtitle =>
      'AI’dan 7–10 durum fikri almak için kısa bir başlık yaz.';

  @override
  String get professionFlowCaption =>
      'Meslek akışı — GPT fikirler + gpt-image-1';

  @override
  String get professionNameLabel => 'Meslek adı';

  @override
  String get professionNameHint => 'örn. mimar, hemşire, sihirbaz';

  @override
  String get professionGenerateIdeas => 'Durum fikirlerini üret';

  @override
  String get professionStartOver => 'Baştan başla';

  @override
  String get professionStep2Title => 'Metin seç';

  @override
  String get professionStep2Subtitle => 'Bir satıra dokun; sonra görsel üret.';

  @override
  String get professionGeneratingMeme => 'Mem görseli oluşturuluyor…';

  @override
  String get professionGenerateImage => 'Mem görselini üret';

  @override
  String get professionErrShortName =>
      'En az 3 karakterlik bir meslek adı girin.';

  @override
  String get professionErrNoVariants =>
      'Sunucudan varyant gelmedi. Backend / mock modunu kontrol edin.';

  @override
  String get professionSnackSaved =>
      'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets; tablolar: meme_assets / meme_asset_versions).';

  @override
  String get professionSourceLabel => 'Meslek akışı';

  @override
  String professionSavedLine(String info) {
    return 'Kayıt: $info';
  }

  @override
  String get professionPublication => 'Yayın (yakında)';

  @override
  String get profProgressCreating => 'Meslek kaydı oluşturuluyor…';

  @override
  String get profProgressSituations =>
      '7–10 durum fikri üretiliyor (API’de OpenAI)…';

  @override
  String get profProgressImage => 'Mem görseli oluşturuluyor…';

  @override
  String get profProgressSaving => 'Sonuç kaydediliyor…';

  @override
  String get telegramChannelDefault => 'Telegram kanalı';

  @override
  String get telegramStep1Title => 'Kanal bağlantısı';

  @override
  String get telegramStep1SubtitleLive =>
      'Yerel Telethon API ile canlı özet; aynı bağlamdan fikirler.';

  @override
  String get telegramStep1SubtitleStub =>
      'Genel kanal linki · canlı çekim için ./run_telegram_api.sh';

  @override
  String get telegramLinkLabel => 'Telegram kanalı / genel link';

  @override
  String get telegramQuickPickTitle => 'Hızlı seçim (kanal)';

  @override
  String get telegramQuickPickRecommended => 'Önerilen';

  @override
  String get telegramQuickChannelMems => 'memsit52';

  @override
  String get telegramQuickChannelNakida => 'nakidaifuturememes';

  @override
  String get telegramQuickPickHintLearn =>
      'Meslek metninde öğrenme / eğitim geçerse aşağıdaki “öğrenme / gelecek” kanalı öne çıkar.';

  @override
  String get telegramAnalyzing => 'Kanal analiz ediliyor…';

  @override
  String get telegramAnalyseButton => 'Bağlantıyı analiz et';

  @override
  String get telegramStep2Title => 'Özet ve fikir üretimi';

  @override
  String get telegramStep2Subtitle =>
      'Kanal DNA’sını kontrol et; ardından varyantları oluştur.';

  @override
  String get telegramStubBanner =>
      'Stub modu — Telegram okunmuyor. ./run_telegram_api.sh çalıştırın; .env içinde TELEGRAM_* ve geçerli TELEGRAM_SESSION_STRING olsun.';

  @override
  String telegramInsightChannel(String title) {
    return 'Kanal: $title';
  }

  @override
  String telegramInsightTopic(String topic) {
    return 'Konu: $topic';
  }

  @override
  String telegramInsightStyle(String style) {
    return 'Üslup: $style';
  }

  @override
  String telegramInsightTone(String tone) {
    return 'Ton: $tone';
  }

  @override
  String telegramInsightThemes(String themes) {
    return 'Temalar: $themes';
  }

  @override
  String telegramInsightPostMix(String mix) {
    return 'Gönderi dengesi: $mix';
  }

  @override
  String telegramInsightMediaTypes(String types) {
    return 'Medya türleri: $types';
  }

  @override
  String get telegramMediaSection => 'Medya / görseller';

  @override
  String get telegramRecentSection => 'Son örnekler';

  @override
  String telegramMemeAngles(String angles) {
    return 'Mem açıları: $angles';
  }

  @override
  String get telegramBadgeLive => 'Canlı';

  @override
  String get telegramBadgeStub => 'Stub';

  @override
  String get telegramGenerateLive => '7–10 yapay zeka varyantı üret ve kaydet';

  @override
  String get telegramGenerateHosted =>
      '5 fikir varyantı üret (barındırılan API)';

  @override
  String get telegramLiveHint =>
      'Varyantlar meme_briefs olarak kaydedilir; görseller Python API’de OPENAI_API_KEY kullanır.';

  @override
  String get telegramStep3Title => 'Metin ve görsel';

  @override
  String get telegramStep3Subtitle =>
      'Bir varyanta dokun; meme görselini üret.';

  @override
  String get telegramGeneratingMeme => 'Mem görseli oluşturuluyor…';

  @override
  String get telegramGenerateMemeButton => 'Seçimden meme üret';

  @override
  String get telegramSnackSaved =>
      'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets).';

  @override
  String get telegramSourceLabel => 'Telegram akışı';

  @override
  String telegramAssetVersion(String id) {
    return 'Varlık sürümü: $id';
  }

  @override
  String get telegramErrShortLink =>
      'Tam kanal bağlantısı yapıştırın (en az 8 karakter).';

  @override
  String get telegramErrStubOffline =>
      'Bu çevrimdışı stub verisi, gerçek kanalınız değil. .env içinde TELEGRAM_* + oturum ile ./run_telegram_api.sh başlatın ve tekrar deneyin.';

  @override
  String telegramErrTooFewIdeas(int count) {
    return 'Sunucudan çok az fikir geldi ($count). API .env içinde OPENAI_API_KEY kontrol edin.';
  }

  @override
  String get telegramErrNoIdeas => 'Sunucudan fikir gelmedi.';

  @override
  String get telegramFutureContext =>
      'Telegram içe aktarma — kanal DNA’sı olarak meme ajanlarına verin.';

  @override
  String get tgProgressFetching =>
      'Kanal mesajları alınıyor ve özet oluşturuluyor…';

  @override
  String get tgProgressPreparing => 'Bağlam hazırlanıyor…';

  @override
  String get tgProgressIdeas =>
      '7–10 meme fikri (AI) üretiliyor ve çalışma alanınıza kaydediliyor…';

  @override
  String get tgProgressImage =>
      'Seçilen varyanttaki meme görseli oluşturuluyor…';

  @override
  String get tgProgressSaving => 'Kaydediliyor…';

  @override
  String get retry => 'Yeniden dene';

  @override
  String get imageLoadError => 'Görsel yüklenemedi';

  @override
  String get imageOfflineError =>
      'Görsel URL’si var ancak çevrimdışı görüntülenemedi.';

  @override
  String get errUnexpected => 'Bir şeyler ters gitti. Lütfen tekrar deneyin.';

  @override
  String get errNetworkUser =>
      'Sunucuya ulaşılamıyor. Bağlantınızı kontrol edin.';

  @override
  String get errNetworkDebug =>
      'MemeOps API’ye ulaşılamıyor. Proje kökünde ./run_telegram_api.sh çalıştırın (veya MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh).';

  @override
  String errApiTimeoutDebug(String origin, int seconds) {
    return 'MemeOps API zaman aşımı ($origin, $seconds sn).';
  }

  @override
  String get errApiTimeoutUser =>
      'Sunucu çok geç yanıt verdi. Daha sonra tekrar deneyin.';

  @override
  String errApiUnreachableDebug(String origin, int port) {
    return 'MemeOps API’ye ($origin) ulaşılamıyor. Proje kökünde: ./run_telegram_api.sh (Python, port $port; .env’de TELEGRAM_* + OPENAI_* gerekir). Veya: MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh — aynı API’yi başlatır. OpenAI/Telegram yoksa Dart stub: dart run tool/memeops_dev_server.dart --port $port.';
  }

  @override
  String get errApiUnreachableUser =>
      'MemeOps sunucusuna ulaşılamıyor. Bağlantınızı kontrol edin.';

  @override
  String debugApiNotRunning(String base) {
    return 'MemeOps: $base yanıt vermiyor. Gömülü stub BAŞLATILMIYOR (MEMEOPS_USE_PYTHON_API=1). Önce ./run_telegram_api.sh çalıştır, sonra uygulamayı yeniden aç.';
  }

  @override
  String archiveDebugSkip(String error) {
    return 'Arşiv kaydı atlandı: $error';
  }

  @override
  String get stubDefaultTopic => 'konu';

  @override
  String stubProfessionIdea1(String topic) {
    return 'Beklenti ve gerçek mizahı: «$topic»';
  }

  @override
  String stubProfessionIdea2(String topic) {
    return '«$topic» gönderisine kitle tepkisi';
  }

  @override
  String stubProfessionIdea3(String topic) {
    return '«$topic» nişindeki tartışmanın ironisi';
  }

  @override
  String stubProfessionIdea4(String topic) {
    return 'Önce/sonra: «$topic» farkındalığı';
  }

  @override
  String stubProfessionIdea5(String topic) {
    return '«$topic» kitlesinin iç şakaları';
  }
}
