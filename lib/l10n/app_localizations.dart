import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ru'),
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps'**
  String get appTitle;

  /// No description provided for @defaultDisplayName.
  ///
  /// In tr, this message translates to:
  /// **'üretici'**
  String get defaultDisplayName;

  /// No description provided for @greeting.
  ///
  /// In tr, this message translates to:
  /// **'İyi günler, {name}'**
  String greeting(String name);

  /// No description provided for @backToLogin.
  ///
  /// In tr, this message translates to:
  /// **'Giriş ekranına dön'**
  String get backToLogin;

  /// No description provided for @homeSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Meme akışına devam et — aşağıdan sekme seç.'**
  String get homeSubtitle;

  /// No description provided for @tabProfession.
  ///
  /// In tr, this message translates to:
  /// **'Meslek'**
  String get tabProfession;

  /// No description provided for @tabTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram'**
  String get tabTelegram;

  /// No description provided for @tabAnalysis.
  ///
  /// In tr, this message translates to:
  /// **'Analiz'**
  String get tabAnalysis;

  /// No description provided for @tabPublish.
  ///
  /// In tr, this message translates to:
  /// **'Yayın'**
  String get tabPublish;

  /// No description provided for @tabArchive.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv'**
  String get tabArchive;

  /// No description provided for @languageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageTitle;

  /// No description provided for @languageTurkish.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get languageTurkish;

  /// No description provided for @languageRussian.
  ///
  /// In tr, this message translates to:
  /// **'Русский'**
  String get languageRussian;

  /// No description provided for @languagePickHint.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama dilini seçin. Tüm metinler buna göre değişir.'**
  String get languagePickHint;

  /// No description provided for @authTagline.
  ///
  /// In tr, this message translates to:
  /// **'Mizah fikirleri ve görseller — tek akışta'**
  String get authTagline;

  /// No description provided for @authSignInTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get authSignInTitle;

  /// No description provided for @authUsername.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adı'**
  String get authUsername;

  /// No description provided for @authUsernameHint.
  ///
  /// In tr, this message translates to:
  /// **'admin'**
  String get authUsernameHint;

  /// No description provided for @authPassword.
  ///
  /// In tr, this message translates to:
  /// **'Şifre'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In tr, this message translates to:
  /// **'12345678'**
  String get authPasswordHint;

  /// No description provided for @authSignIn.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yap'**
  String get authSignIn;

  /// No description provided for @authSignUp.
  ///
  /// In tr, this message translates to:
  /// **'İlk kurulum: kayıt oluştur (admin + şifre)'**
  String get authSignUp;

  /// No description provided for @authErrEmptyUser.
  ///
  /// In tr, this message translates to:
  /// **'Kullanıcı adını girin.'**
  String get authErrEmptyUser;

  /// No description provided for @authErrNoAt.
  ///
  /// In tr, this message translates to:
  /// **'Sadece kullanıcı adı yazın (@ ve e-posta yok).'**
  String get authErrNoAt;

  /// No description provided for @authErrPasswordShort.
  ///
  /// In tr, this message translates to:
  /// **'Şifre en az 6 karakter olsun (örn. 12345678).'**
  String get authErrPasswordShort;

  /// No description provided for @authErrInvalidLogin.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı Supabase’te yok veya şifre uyuşmuyor. Alttaki «İlk kurulum: kayıt oluştur» ile dene, ya da Dashboard’da Authentication → Users ile kullanıcı ekle.'**
  String get authErrInvalidLogin;

  /// No description provided for @authErrAlreadyRegistered.
  ///
  /// In tr, this message translates to:
  /// **'Bu kullanıcı zaten var. Doğrudan «Giriş yap» kullan.'**
  String get authErrAlreadyRegistered;

  /// No description provided for @authSnackSignUp.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt oluşturuldu. Giriş olmadıysa: Supabase → Authentication → Providers → «Confirm email» kapatıp tekrar dene, veya e-postadaki linke tıkla.'**
  String get authSnackSignUp;

  /// No description provided for @authBenefitTitle.
  ///
  /// In tr, this message translates to:
  /// **'Giriş yapınca neler kazanırsın?'**
  String get authBenefitTitle;

  /// No description provided for @authBenefitTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram kanalından canlı özet ve fikirler'**
  String get authBenefitTelegram;

  /// No description provided for @authBenefitProfession.
  ///
  /// In tr, this message translates to:
  /// **'Meslek / konuya göre AI durum mizahı'**
  String get authBenefitProfession;

  /// No description provided for @authBenefitImage.
  ///
  /// In tr, this message translates to:
  /// **'gpt-image-1 ile kare meme görseli'**
  String get authBenefitImage;

  /// No description provided for @authBenefitSupabase.
  ///
  /// In tr, this message translates to:
  /// **'Supabase’de brief ve görsel sürümleri'**
  String get authBenefitSupabase;

  /// No description provided for @configTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yapılandırma'**
  String get configTitle;

  /// No description provided for @configBody.
  ///
  /// In tr, this message translates to:
  /// **'Public Supabase URL + anon key ve MemeOps API tabanı eksik. Uygulamada servis rolü veya OpenAI anahtarı yok:'**
  String get configBody;

  /// No description provided for @configBullet1.
  ///
  /// In tr, this message translates to:
  /// **'1) Proje kökünde `.env` (env.sample’dan kopyala) — IDE / simülatör bu dosyayı okur.'**
  String get configBullet1;

  /// No description provided for @configBullet2.
  ///
  /// In tr, this message translates to:
  /// **'2) flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=MEMEOPS_API_BASE=https://...'**
  String get configBullet2;

  /// No description provided for @configApiNote.
  ///
  /// In tr, this message translates to:
  /// **'Yerel API: MEMEOPS_API_BASE=http://127.0.0.1:3000 (iOS Simülatör uyumlu; ./run_dev.sh veya ./run_telegram_api.sh).'**
  String get configApiNote;

  /// No description provided for @archiveTitle.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv'**
  String get archiveTitle;

  /// No description provided for @archiveSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Yerel üretimler bu cihazda; aynı hesabın Supabase’deki görseller ve videolar aşağıda birleşir. Filtreyle cihaz / bulut ayrılabilir.'**
  String get archiveSubtitle;

  /// No description provided for @archiveSourceCloud.
  ///
  /// In tr, this message translates to:
  /// **'Supabase'**
  String get archiveSourceCloud;

  /// No description provided for @archiveSupabaseLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Hesabındaki sunucu medyaları yüklenemedi. Yerel arşiv gösteriliyor.'**
  String get archiveSupabaseLoadError;

  /// No description provided for @archiveFilterAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get archiveFilterAll;

  /// No description provided for @archiveFilterLocal.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihaz'**
  String get archiveFilterLocal;

  /// No description provided for @archiveFilterCloud.
  ///
  /// In tr, this message translates to:
  /// **'Supabase'**
  String get archiveFilterCloud;

  /// No description provided for @archiveEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Henüz kayıtlı görsel yok.\nMeslek veya Telegram sekmesinden meme üret.'**
  String get archiveEmpty;

  /// No description provided for @archiveFileMissing.
  ///
  /// In tr, this message translates to:
  /// **'Dosya bulunamadı (silinmiş olabilir).'**
  String get archiveFileMissing;

  /// No description provided for @archiveShare.
  ///
  /// In tr, this message translates to:
  /// **'Paylaş'**
  String get archiveShare;

  /// No description provided for @archiveVideoErrorTitle.
  ///
  /// In tr, this message translates to:
  /// **'Video açılamadı'**
  String get archiveVideoErrorTitle;

  /// No description provided for @archiveShareFailed.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşma menüsü açılamadı.'**
  String get archiveShareFailed;

  /// No description provided for @archiveShareFailedWithError.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşma: {error}'**
  String archiveShareFailedWithError(String error);

  /// No description provided for @archiveShareSheetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telegram veya VK. Zamanlama ve metin düzenleme: arşivde öğenin içine girin.'**
  String get archiveShareSheetSubtitle;

  /// No description provided for @archiveCaptionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi metni'**
  String get archiveCaptionLabel;

  /// No description provided for @archiveCaptionSave.
  ///
  /// In tr, this message translates to:
  /// **'Metni kaydet'**
  String get archiveCaptionSave;

  /// No description provided for @archiveCaptionSaved.
  ///
  /// In tr, this message translates to:
  /// **'Metin kaydedildi.'**
  String get archiveCaptionSaved;

  /// No description provided for @archiveCaptionCloudNeedsBrief.
  ///
  /// In tr, this message translates to:
  /// **'Bu bulut kaydında brief bağlantısı yok; metin yalnızca bu gönderim için kullanılır.'**
  String get archiveCaptionCloudNeedsBrief;

  /// No description provided for @archivePublishTitle.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım'**
  String get archivePublishTitle;

  /// No description provided for @archiveTelegramSmartRoutingTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telegram: akıllı kanal önerisi'**
  String get archiveTelegramSmartRoutingTitle;

  /// No description provided for @archiveTelegramSmartRoutingHint.
  ///
  /// In tr, this message translates to:
  /// **'Metin ve başlığa göre «{channel}» öne çıkıyor. Aşağıdan istediğin kanalları işaretle; birden fazlasına aynı gönderi gidebilir.'**
  String archiveTelegramSmartRoutingHint(String channel);

  /// No description provided for @archiveTelegramSuggestedBadge.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
  String get archiveTelegramSuggestedBadge;

  /// No description provided for @archivePlatformNameTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram'**
  String get archivePlatformNameTelegram;

  /// No description provided for @archivePlatformNameVk.
  ///
  /// In tr, this message translates to:
  /// **'VK'**
  String get archivePlatformNameVk;

  /// No description provided for @archivePlatformNameDzen.
  ///
  /// In tr, this message translates to:
  /// **'Dzen'**
  String get archivePlatformNameDzen;

  /// No description provided for @archiveWeRecommendTitle.
  ///
  /// In tr, this message translates to:
  /// **'Size şunu öneriyoruz'**
  String get archiveWeRecommendTitle;

  /// No description provided for @archiveTelegramRecMatchesThisPost.
  ///
  /// In tr, this message translates to:
  /// **'Bu gönderiyle en uyumlu'**
  String get archiveTelegramRecMatchesThisPost;

  /// No description provided for @archiveTelegramRecCategoryName.
  ///
  /// In tr, this message translates to:
  /// **'{category} → {name}'**
  String archiveTelegramRecCategoryName(String category, String name);

  /// No description provided for @archiveTelegramRecFooter.
  ///
  /// In tr, this message translates to:
  /// **'Metin ve başlıktaki kelimelere göre (kozmetik, okul vb.) uyumlu kanal yıldızla işaretlenir. VK ve Dzen: yalnızca «paylaşıldı» (Telegram dışı gerçek istek yok).'**
  String get archiveTelegramRecFooter;

  /// No description provided for @archivePublishChannelsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Telegram, VK, Dzen. Alttaki kartlar sadece Telegram hedefi içindir.'**
  String get archivePublishChannelsSubtitle;

  /// No description provided for @archivePublishSelectAtLeastOneChannel.
  ///
  /// In tr, this message translates to:
  /// **'En az bir kanal seçin.'**
  String get archivePublishSelectAtLeastOneChannel;

  /// No description provided for @archivePublishWhenHeading.
  ///
  /// In tr, this message translates to:
  /// **'Gönderim zamanı'**
  String get archivePublishWhenHeading;

  /// No description provided for @archivePublishWhenNow.
  ///
  /// In tr, this message translates to:
  /// **'Hemen gönder'**
  String get archivePublishWhenNow;

  /// No description provided for @archivePublishWhenSchedule.
  ///
  /// In tr, this message translates to:
  /// **'İleri tarih'**
  String get archivePublishWhenSchedule;

  /// No description provided for @archivePublishPickDateTime.
  ///
  /// In tr, this message translates to:
  /// **'Tarih ve saat seç'**
  String get archivePublishPickDateTime;

  /// No description provided for @archivePublishSubmit.
  ///
  /// In tr, this message translates to:
  /// **'Gönder'**
  String get archivePublishSubmit;

  /// No description provided for @archivePublishScheduledAck.
  ///
  /// In tr, this message translates to:
  /// **'Zamanlandı: {when}'**
  String archivePublishScheduledAck(String when);

  /// No description provided for @archivePublishChooseSchedule.
  ///
  /// In tr, this message translates to:
  /// **'Önce tarih ve saat seçin.'**
  String get archivePublishChooseSchedule;

  /// No description provided for @archivePublishSchedulePast.
  ///
  /// In tr, this message translates to:
  /// **'Zaman geçmiş olamaz.'**
  String get archivePublishSchedulePast;

  /// No description provided for @archivePublishScheduleNeedOpenApp.
  ///
  /// In tr, this message translates to:
  /// **'Uygulama açıkken sıraya alınır; tamamen kapalıysa gönderim gecikebilir.'**
  String get archivePublishScheduleNeedOpenApp;

  /// No description provided for @archiveDownloadFailed.
  ///
  /// In tr, this message translates to:
  /// **'Görsel indirilemedi (HTTP {code}).'**
  String archiveDownloadFailed(int code);

  /// No description provided for @archiveListLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Liste açılırken beklenmeyen bir gecikme oldu. Aşağı çekerek yenile.'**
  String get archiveListLoadError;

  /// No description provided for @archiveEntryDeleteTitle.
  ///
  /// In tr, this message translates to:
  /// **'Silinsin mi?'**
  String get archiveEntryDeleteTitle;

  /// No description provided for @archiveEntryDeleteMessage.
  ///
  /// In tr, this message translates to:
  /// **'Bu kayıt kalıcı olarak silinir. Supabase satırı (ve mümkünse dosya) kaldırılır; yerel dosya da silinir.'**
  String get archiveEntryDeleteMessage;

  /// No description provided for @archiveEntryDelete.
  ///
  /// In tr, this message translates to:
  /// **'Sil'**
  String get archiveEntryDelete;

  /// No description provided for @archiveEntryDeleteCancel.
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get archiveEntryDeleteCancel;

  /// No description provided for @publishTitle.
  ///
  /// In tr, this message translates to:
  /// **'Yayın'**
  String get publishTitle;

  /// No description provided for @publishBody.
  ///
  /// In tr, this message translates to:
  /// **'İleride: kayıtlı `meme_brief` + `asset` satırlarını bağlı Telegram / VK vb. kanallara `publish_jobs` ile göndermek. Mobil uygulamada henüz yok.'**
  String get publishBody;

  /// No description provided for @publishStubButton.
  ///
  /// In tr, this message translates to:
  /// **'PublicationPort’u çağır (stub)'**
  String get publishStubButton;

  /// No description provided for @publicationComingSoon.
  ///
  /// In tr, this message translates to:
  /// **'Yayın hattı henüz bağlı değil.'**
  String get publicationComingSoon;

  /// No description provided for @publicationDone.
  ///
  /// In tr, this message translates to:
  /// **'Tamam'**
  String get publicationDone;

  /// No description provided for @shareTargetTitle.
  ///
  /// In tr, this message translates to:
  /// **'Nereye paylaşılsın?'**
  String get shareTargetTitle;

  /// No description provided for @shareTargetSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Hedefi seç; ağ isteği sadece bu paylaşım için gider.'**
  String get shareTargetSubtitle;

  /// No description provided for @shareTargetTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram'**
  String get shareTargetTelegram;

  /// No description provided for @shareTargetVk.
  ///
  /// In tr, this message translates to:
  /// **'ВКонтакте (grup duvarı)'**
  String get shareTargetVk;

  /// No description provided for @shareTargetDzen.
  ///
  /// In tr, this message translates to:
  /// **'Дзен'**
  String get shareTargetDzen;

  /// No description provided for @shareNoServiceConfigured.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım için .env içinde TELEGRAM_PUBLISH_* veya VK_ACCESS_TOKEN + VK_GROUP_ID gerekir; Dzen ayrıca her zaman (simüle) seçilebilir.'**
  String get shareNoServiceConfigured;

  /// No description provided for @archivePublishNoTgVkDzenOnly.
  ///
  /// In tr, this message translates to:
  /// **'Telegram ve VK .env’te tanımlı değil. Aşağıdan Dzen’i (simülasyon) seçebilirsin.'**
  String get archivePublishNoTgVkDzenOnly;

  /// No description provided for @dzenPublishSimulated.
  ///
  /// In tr, this message translates to:
  /// **'Dzen: paylaşım kaydedildi.'**
  String get dzenPublishSimulated;

  /// No description provided for @vkPostDone.
  ///
  /// In tr, this message translates to:
  /// **'VK’da paylaşıldı.'**
  String get vkPostDone;

  /// No description provided for @vkPostFailed.
  ///
  /// In tr, this message translates to:
  /// **'VK paylaşımı başarısız.'**
  String get vkPostFailed;

  /// No description provided for @vkPostNeedUserToken.
  ///
  /// In tr, this message translates to:
  /// **'VK: topluluk (grup) access token resim/gönderi yükleyemez. .env’e kullanıcı OAuth token ekle: VK_USER_ACCESS_TOKEN= (kapsam: wall, photos, video, groups, offline). Proje kökünde: ./setup_vk_user_token.sh'**
  String get vkPostNeedUserToken;

  /// No description provided for @analysisTitle.
  ///
  /// In tr, this message translates to:
  /// **'Telegram analizi'**
  String get analysisTitle;

  /// No description provided for @analysisSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Canlı analizden gelen sinyalleri burada topla; hangi saatler, hangi formatlar ve hangi gönderi tipleri daha güçlü görünüyor hızlıca gör.'**
  String get analysisSubtitle;

  /// No description provided for @analysisEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Önce Telegram sekmesinden bir kanal analiz et. Son sonuç burada görünür.'**
  String get analysisEmpty;

  /// No description provided for @analysisOverview.
  ///
  /// In tr, this message translates to:
  /// **'Genel görünüm'**
  String get analysisOverview;

  /// No description provided for @analysisSampleSize.
  ///
  /// In tr, this message translates to:
  /// **'İncelenen gönderi'**
  String get analysisSampleSize;

  /// No description provided for @analysisSource.
  ///
  /// In tr, this message translates to:
  /// **'Kaynak'**
  String get analysisSource;

  /// No description provided for @analysisSourceLive.
  ///
  /// In tr, this message translates to:
  /// **'Canlı Telethon analizi'**
  String get analysisSourceLive;

  /// No description provided for @analysisSourceStub.
  ///
  /// In tr, this message translates to:
  /// **'Stub / sınırlı veri'**
  String get analysisSourceStub;

  /// No description provided for @analysisActivity.
  ///
  /// In tr, this message translates to:
  /// **'Aktif zaman aralıkları'**
  String get analysisActivity;

  /// No description provided for @analysisNoActivity.
  ///
  /// In tr, this message translates to:
  /// **'Henüz aktif zaman aralığı verisi yok.'**
  String get analysisNoActivity;

  /// No description provided for @analysisTopPosts.
  ///
  /// In tr, this message translates to:
  /// **'Öne çıkan gönderiler'**
  String get analysisTopPosts;

  /// No description provided for @analysisNoTopPosts.
  ///
  /// In tr, this message translates to:
  /// **'Henüz öne çıkan gönderi verisi yok.'**
  String get analysisNoTopPosts;

  /// No description provided for @analysisAudience.
  ///
  /// In tr, this message translates to:
  /// **'Kitle ve etkileşim sinyalleri'**
  String get analysisAudience;

  /// No description provided for @analysisNoAudience.
  ///
  /// In tr, this message translates to:
  /// **'Henüz etkileşim sinyali yok.'**
  String get analysisNoAudience;

  /// No description provided for @analysisOpportunities.
  ///
  /// In tr, this message translates to:
  /// **'İçerik fırsatları'**
  String get analysisOpportunities;

  /// No description provided for @analysisNoOpportunities.
  ///
  /// In tr, this message translates to:
  /// **'Henüz içerik fırsatı çıkarılamadı.'**
  String get analysisNoOpportunities;

  /// No description provided for @analysisMyPublications.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazdan kanala paylaştıkların'**
  String get analysisMyPublications;

  /// No description provided for @analysisMyPublicationsBody.
  ///
  /// In tr, this message translates to:
  /// **'Telegram veya VK’ya arşivden paylaştığında burada listelenir: Telegram’da mesaj no ve izlenme; VK’da duvar gönderi no. Detayda metrikleri görebilir, VK’da yenile ile güncelleyebilirsin. Kanal analizi aşağıda devam eder.'**
  String get analysisMyPublicationsBody;

  /// No description provided for @analysisNoMyPublications.
  ///
  /// In tr, this message translates to:
  /// **'Bu uygulamadan henüz kanal paylaşımı yok. Meslek / Telegram veya Arşiv’deki paylaş akışını dene.'**
  String get analysisNoMyPublications;

  /// No description provided for @analysisEmptyVideoGrid.
  ///
  /// In tr, this message translates to:
  /// **'Henüz paylaştığın video yok. Arşivden videoyu Telegram veya VK’ya paylaş; burada ızgarada görünür.'**
  String get analysisEmptyVideoGrid;

  /// No description provided for @analysisNotSharedTitle.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bu içerik için metrik yok'**
  String get analysisNotSharedTitle;

  /// No description provided for @analysisNotSharedBody.
  ///
  /// In tr, this message translates to:
  /// **'Bu medya arşivde kayıtlı ancak uygulamadan Telegram / VK’ya eşleşen bir paylaşım yok. Arşivden paylaş; sonraki açılışlarda burada izlenme ve (VK’da) beğeni / paylaşım görebilirsin. Eski paylaşımlar kimlik eşleşmediyse de boş kalabilir.'**
  String get analysisNotSharedBody;

  /// No description provided for @analysisOpenPreview.
  ///
  /// In tr, this message translates to:
  /// **'Önizleme aç'**
  String get analysisOpenPreview;

  /// No description provided for @analysisViewCount.
  ///
  /// In tr, this message translates to:
  /// **'{n} izlenme'**
  String analysisViewCount(int n);

  /// No description provided for @analysisViewUnknown.
  ///
  /// In tr, this message translates to:
  /// **'izlenme: —'**
  String get analysisViewUnknown;

  /// No description provided for @analysisPostKindImage.
  ///
  /// In tr, this message translates to:
  /// **'Görsel'**
  String get analysisPostKindImage;

  /// No description provided for @analysisPostKindVideo.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get analysisPostKindVideo;

  /// No description provided for @analysisPlatformTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram'**
  String get analysisPlatformTelegram;

  /// No description provided for @analysisPlatformVk.
  ///
  /// In tr, this message translates to:
  /// **'VK'**
  String get analysisPlatformVk;

  /// No description provided for @myPubSummaryTitle.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım özeti'**
  String get myPubSummaryTitle;

  /// No description provided for @myPubSummaryEmpty.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda henüz kayıtlı paylaşım yok. Arşivden paylaş; sayılar yüklenince burada dolar.'**
  String get myPubSummaryEmpty;

  /// No description provided for @myPubSummaryTotalLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam paylaşım'**
  String get myPubSummaryTotalLabel;

  /// No description provided for @myPubSummaryViewsLabel.
  ///
  /// In tr, this message translates to:
  /// **'Toplam izlenme (bilinen)'**
  String get myPubSummaryViewsLabel;

  /// No description provided for @myPubSummaryByType.
  ///
  /// In tr, this message translates to:
  /// **'İçerik türü (adet)'**
  String get myPubSummaryByType;

  /// No description provided for @myPubSummaryByPlatform.
  ///
  /// In tr, this message translates to:
  /// **'Platform (adet)'**
  String get myPubSummaryByPlatform;

  /// No description provided for @myPubSummaryRolling.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün: {cur} paylaşım · önceki 7 gün: {prev} paylaşım'**
  String myPubSummaryRolling(int cur, int prev);

  /// No description provided for @myPubSummaryChartTitle.
  ///
  /// In tr, this message translates to:
  /// **'Son 7 gün — günlük paylaşım adedi'**
  String get myPubSummaryChartTitle;

  /// No description provided for @myPubSummaryTypeViews.
  ///
  /// In tr, this message translates to:
  /// **'Türe göre toplam izlenme'**
  String get myPubSummaryTypeViews;

  /// No description provided for @myPubSummaryPlatformViews.
  ///
  /// In tr, this message translates to:
  /// **'Platforma göre toplam izlenme'**
  String get myPubSummaryPlatformViews;

  /// No description provided for @myPubSummaryBest.
  ///
  /// In tr, this message translates to:
  /// **'En çok izlenen (kayıtlı)'**
  String get myPubSummaryBest;

  /// No description provided for @myPubSummaryDzenLabel.
  ///
  /// In tr, this message translates to:
  /// **'Dzen'**
  String get myPubSummaryDzenLabel;

  /// No description provided for @myPubSummaryDzenNoViews.
  ///
  /// In tr, this message translates to:
  /// **'Dzen simüle: izlenme sayılmaz.'**
  String get myPubSummaryDzenNoViews;

  /// No description provided for @myPubImageShort.
  ///
  /// In tr, this message translates to:
  /// **'Görsel'**
  String get myPubImageShort;

  /// No description provided for @myPubVideoShort.
  ///
  /// In tr, this message translates to:
  /// **'Video'**
  String get myPubVideoShort;

  /// No description provided for @myPubOpenFullAnalytics.
  ///
  /// In tr, this message translates to:
  /// **'Tüm paylaşım analizi'**
  String get myPubOpenFullAnalytics;

  /// No description provided for @myPubOpenFullAnalyticsSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Grafikler, özet ve her gönderi için önizleme + izlenme'**
  String get myPubOpenFullAnalyticsSubtitle;

  /// No description provided for @myPubFullPageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Detay analiz'**
  String get myPubFullPageTitle;

  /// No description provided for @myPubPerPostListTitle.
  ///
  /// In tr, this message translates to:
  /// **'Gönderiler (izlenmeye göre, önizlemeli)'**
  String get myPubPerPostListTitle;

  /// No description provided for @myPubPerPostNoThumb.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get myPubPerPostNoThumb;

  /// No description provided for @myPubViewUnknown.
  ///
  /// In tr, this message translates to:
  /// **'İzlenme: bilinmiyor'**
  String get myPubViewUnknown;

  /// No description provided for @myPubPlatformVkTr.
  ///
  /// In tr, this message translates to:
  /// **'VK'**
  String get myPubPlatformVkTr;

  /// No description provided for @publicationDetailTitle.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım detayı'**
  String get publicationDetailTitle;

  /// No description provided for @publicationDetailSectionInfo.
  ///
  /// In tr, this message translates to:
  /// **'Bilgiler'**
  String get publicationDetailSectionInfo;

  /// No description provided for @publicationDetailPublishedAt.
  ///
  /// In tr, this message translates to:
  /// **'Yayın'**
  String get publicationDetailPublishedAt;

  /// No description provided for @publicationDetailRefreshTelegram.
  ///
  /// In tr, this message translates to:
  /// **'Telegram metriklerini yenile'**
  String get publicationDetailRefreshTelegram;

  /// No description provided for @publicationDetailRefreshVk.
  ///
  /// In tr, this message translates to:
  /// **'VK istatistiklerini yenile'**
  String get publicationDetailRefreshVk;

  /// No description provided for @publicationDetailReactions.
  ///
  /// In tr, this message translates to:
  /// **'Reaksiyonlar'**
  String get publicationDetailReactions;

  /// No description provided for @publicationDetailReactionsEmpty.
  ///
  /// In tr, this message translates to:
  /// **'—'**
  String get publicationDetailReactionsEmpty;

  /// No description provided for @publicationDetailEmojiReaction.
  ///
  /// In tr, this message translates to:
  /// **'{emoji}  ×{count}'**
  String publicationDetailEmojiReaction(String emoji, int count);

  /// No description provided for @publicationDetailCustomReaction.
  ///
  /// In tr, this message translates to:
  /// **'Özel  ×{count}'**
  String publicationDetailCustomReaction(int count);

  /// No description provided for @publicationDetailReactionCountOnly.
  ///
  /// In tr, this message translates to:
  /// **'×{count}'**
  String publicationDetailReactionCountOnly(int count);

  /// No description provided for @publicationDetailKind.
  ///
  /// In tr, this message translates to:
  /// **'Tür'**
  String get publicationDetailKind;

  /// No description provided for @publicationDetailMessageId.
  ///
  /// In tr, this message translates to:
  /// **'Mesaj'**
  String get publicationDetailMessageId;

  /// No description provided for @publicationDetailChat.
  ///
  /// In tr, this message translates to:
  /// **'Sohbet'**
  String get publicationDetailChat;

  /// No description provided for @publicationDetailChannel.
  ///
  /// In tr, this message translates to:
  /// **'Kanal (Telegram)'**
  String get publicationDetailChannel;

  /// No description provided for @publicationDetailViews.
  ///
  /// In tr, this message translates to:
  /// **'İzlenme'**
  String get publicationDetailViews;

  /// No description provided for @publicationDetailForwards.
  ///
  /// In tr, this message translates to:
  /// **'İletme (Telegram)'**
  String get publicationDetailForwards;

  /// No description provided for @publicationDetailVkGroup.
  ///
  /// In tr, this message translates to:
  /// **'Grup'**
  String get publicationDetailVkGroup;

  /// No description provided for @publicationDetailVkPost.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi'**
  String get publicationDetailVkPost;

  /// No description provided for @publicationDetailVkHint.
  ///
  /// In tr, this message translates to:
  /// **'Yenile ile çekilebilir'**
  String get publicationDetailVkHint;

  /// No description provided for @publicationDetailLikes.
  ///
  /// In tr, this message translates to:
  /// **'Beğeni'**
  String get publicationDetailLikes;

  /// No description provided for @publicationDetailReposts.
  ///
  /// In tr, this message translates to:
  /// **'Paylaşım'**
  String get publicationDetailReposts;

  /// No description provided for @publicationDetailCaption.
  ///
  /// In tr, this message translates to:
  /// **'Açıklama'**
  String get publicationDetailCaption;

  /// No description provided for @publicationDetailTabAll.
  ///
  /// In tr, this message translates to:
  /// **'Tümü'**
  String get publicationDetailTabAll;

  /// No description provided for @publicationDetailTabDzen.
  ///
  /// In tr, this message translates to:
  /// **'Dzen'**
  String get publicationDetailTabDzen;

  /// No description provided for @publicationDetailDzen.
  ///
  /// In tr, this message translates to:
  /// **'Durum'**
  String get publicationDetailDzen;

  /// No description provided for @publicationDetailDzenBody.
  ///
  /// In tr, this message translates to:
  /// **'Simülasyon; gerçek metrik yok.'**
  String get publicationDetailDzenBody;

  /// No description provided for @publicationDetailMembers.
  ///
  /// In tr, this message translates to:
  /// **'Topluluk (abone)'**
  String get publicationDetailMembers;

  /// No description provided for @publicationDetailTgReplies.
  ///
  /// In tr, this message translates to:
  /// **'Yorum (tartışma)'**
  String get publicationDetailTgReplies;

  /// No description provided for @publicationDetailTgMessageTime.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi saati (Telegram)'**
  String get publicationDetailTgMessageTime;

  /// No description provided for @publicationDetailComments.
  ///
  /// In tr, this message translates to:
  /// **'Yorum'**
  String get publicationDetailComments;

  /// No description provided for @publicationDetailStatsNotFound.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi bu oturumda bulunamadı. Kanal ve mesaj no ile eşleşmeyi kontrol edin; API: ./run_telegram_api.sh'**
  String get publicationDetailStatsNotFound;

  /// No description provided for @publicationDetailRefreshAll.
  ///
  /// In tr, this message translates to:
  /// **'Yenile'**
  String get publicationDetailRefreshAll;

  /// No description provided for @professionStep1Title.
  ///
  /// In tr, this message translates to:
  /// **'Meslek veya konu'**
  String get professionStep1Title;

  /// No description provided for @professionStep1Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'AI’dan 7–10 durum fikri almak için kısa bir başlık yaz.'**
  String get professionStep1Subtitle;

  /// No description provided for @professionFlowCaption.
  ///
  /// In tr, this message translates to:
  /// **'Meslek akışı — GPT fikirler + gpt-image-1'**
  String get professionFlowCaption;

  /// No description provided for @professionNameLabel.
  ///
  /// In tr, this message translates to:
  /// **'Meslek adı'**
  String get professionNameLabel;

  /// No description provided for @professionNameHint.
  ///
  /// In tr, this message translates to:
  /// **'örn. mimar, hemşire, sihirbaz'**
  String get professionNameHint;

  /// No description provided for @professionGenerateIdeas.
  ///
  /// In tr, this message translates to:
  /// **'Durum fikirlerini üret'**
  String get professionGenerateIdeas;

  /// No description provided for @professionStartOver.
  ///
  /// In tr, this message translates to:
  /// **'Baştan başla'**
  String get professionStartOver;

  /// No description provided for @professionStep2Title.
  ///
  /// In tr, this message translates to:
  /// **'Metin seç'**
  String get professionStep2Title;

  /// No description provided for @professionStep2Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir satıra dokun; sonra görsel üret.'**
  String get professionStep2Subtitle;

  /// No description provided for @professionGeneratingMeme.
  ///
  /// In tr, this message translates to:
  /// **'Mem görseli oluşturuluyor…'**
  String get professionGeneratingMeme;

  /// No description provided for @professionGenerateImage.
  ///
  /// In tr, this message translates to:
  /// **'Mem görselini üret'**
  String get professionGenerateImage;

  /// No description provided for @professionErrShortName.
  ///
  /// In tr, this message translates to:
  /// **'En az 3 karakterlik bir meslek adı girin.'**
  String get professionErrShortName;

  /// No description provided for @professionErrNoVariants.
  ///
  /// In tr, this message translates to:
  /// **'Sunucudan varyant gelmedi. Backend / mock modunu kontrol edin.'**
  String get professionErrNoVariants;

  /// No description provided for @professionSnackSaved.
  ///
  /// In tr, this message translates to:
  /// **'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets; tablolar: meme_assets / meme_asset_versions).'**
  String get professionSnackSaved;

  /// No description provided for @professionSourceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Meslek akışı'**
  String get professionSourceLabel;

  /// No description provided for @professionSavedLine.
  ///
  /// In tr, this message translates to:
  /// **'Kayıt: {info}'**
  String professionSavedLine(String info);

  /// No description provided for @professionPublication.
  ///
  /// In tr, this message translates to:
  /// **'Yayın (yakında)'**
  String get professionPublication;

  /// No description provided for @profProgressCreating.
  ///
  /// In tr, this message translates to:
  /// **'Meslek kaydı oluşturuluyor…'**
  String get profProgressCreating;

  /// No description provided for @profProgressSituations.
  ///
  /// In tr, this message translates to:
  /// **'7–10 durum fikri üretiliyor (API’de OpenAI)…'**
  String get profProgressSituations;

  /// No description provided for @profProgressImage.
  ///
  /// In tr, this message translates to:
  /// **'Mem görseli oluşturuluyor…'**
  String get profProgressImage;

  /// No description provided for @profProgressSaving.
  ///
  /// In tr, this message translates to:
  /// **'Sonuç kaydediliyor…'**
  String get profProgressSaving;

  /// No description provided for @telegramChannelDefault.
  ///
  /// In tr, this message translates to:
  /// **'Telegram kanalı'**
  String get telegramChannelDefault;

  /// No description provided for @telegramStep1Title.
  ///
  /// In tr, this message translates to:
  /// **'Kanal bağlantısı'**
  String get telegramStep1Title;

  /// No description provided for @telegramStep1SubtitleLive.
  ///
  /// In tr, this message translates to:
  /// **'Yerel Telethon API ile canlı özet; aynı bağlamdan fikirler.'**
  String get telegramStep1SubtitleLive;

  /// No description provided for @telegramStep1SubtitleStub.
  ///
  /// In tr, this message translates to:
  /// **'Genel kanal linki · canlı çekim için ./run_telegram_api.sh'**
  String get telegramStep1SubtitleStub;

  /// No description provided for @telegramLinkLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telegram kanalı / genel link'**
  String get telegramLinkLabel;

  /// No description provided for @telegramQuickPickTitle.
  ///
  /// In tr, this message translates to:
  /// **'Hızlı seçim (kanal)'**
  String get telegramQuickPickTitle;

  /// No description provided for @telegramQuickPickRecommended.
  ///
  /// In tr, this message translates to:
  /// **'Önerilen'**
  String get telegramQuickPickRecommended;

  /// No description provided for @telegramQuickChannelMems.
  ///
  /// In tr, this message translates to:
  /// **'memsit52'**
  String get telegramQuickChannelMems;

  /// No description provided for @telegramQuickChannelNakida.
  ///
  /// In tr, this message translates to:
  /// **'nakidaifuturememes'**
  String get telegramQuickChannelNakida;

  /// No description provided for @telegramQuickPickHintLearn.
  ///
  /// In tr, this message translates to:
  /// **'Meslek metninde öğrenme / eğitim geçerse aşağıdaki “öğrenme / gelecek” kanalı öne çıkar.'**
  String get telegramQuickPickHintLearn;

  /// No description provided for @telegramAnalyzing.
  ///
  /// In tr, this message translates to:
  /// **'Kanal analiz ediliyor…'**
  String get telegramAnalyzing;

  /// No description provided for @telegramAnalyseButton.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantıyı analiz et'**
  String get telegramAnalyseButton;

  /// No description provided for @telegramStep2Title.
  ///
  /// In tr, this message translates to:
  /// **'Özet ve fikir üretimi'**
  String get telegramStep2Title;

  /// No description provided for @telegramStep2Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kanal DNA’sını kontrol et; ardından varyantları oluştur.'**
  String get telegramStep2Subtitle;

  /// No description provided for @telegramStubBanner.
  ///
  /// In tr, this message translates to:
  /// **'Stub modu — Telegram okunmuyor. ./run_telegram_api.sh çalıştırın; .env içinde TELEGRAM_* ve geçerli TELEGRAM_SESSION_STRING olsun.'**
  String get telegramStubBanner;

  /// No description provided for @telegramInsightChannel.
  ///
  /// In tr, this message translates to:
  /// **'Kanal: {title}'**
  String telegramInsightChannel(String title);

  /// No description provided for @telegramInsightTopic.
  ///
  /// In tr, this message translates to:
  /// **'Konu: {topic}'**
  String telegramInsightTopic(String topic);

  /// No description provided for @telegramInsightStyle.
  ///
  /// In tr, this message translates to:
  /// **'Üslup: {style}'**
  String telegramInsightStyle(String style);

  /// No description provided for @telegramInsightTone.
  ///
  /// In tr, this message translates to:
  /// **'Ton: {tone}'**
  String telegramInsightTone(String tone);

  /// No description provided for @telegramInsightThemes.
  ///
  /// In tr, this message translates to:
  /// **'Temalar: {themes}'**
  String telegramInsightThemes(String themes);

  /// No description provided for @telegramInsightPostMix.
  ///
  /// In tr, this message translates to:
  /// **'Gönderi dengesi: {mix}'**
  String telegramInsightPostMix(String mix);

  /// No description provided for @telegramInsightMediaTypes.
  ///
  /// In tr, this message translates to:
  /// **'Medya türleri: {types}'**
  String telegramInsightMediaTypes(String types);

  /// No description provided for @telegramMediaSection.
  ///
  /// In tr, this message translates to:
  /// **'Medya / görseller'**
  String get telegramMediaSection;

  /// No description provided for @telegramRecentSection.
  ///
  /// In tr, this message translates to:
  /// **'Son örnekler'**
  String get telegramRecentSection;

  /// No description provided for @telegramMemeAngles.
  ///
  /// In tr, this message translates to:
  /// **'Mem açıları: {angles}'**
  String telegramMemeAngles(String angles);

  /// No description provided for @telegramBadgeLive.
  ///
  /// In tr, this message translates to:
  /// **'Canlı'**
  String get telegramBadgeLive;

  /// No description provided for @telegramBadgeStub.
  ///
  /// In tr, this message translates to:
  /// **'Stub'**
  String get telegramBadgeStub;

  /// No description provided for @telegramGenerateLive.
  ///
  /// In tr, this message translates to:
  /// **'7–10 yapay zeka varyantı üret ve kaydet'**
  String get telegramGenerateLive;

  /// No description provided for @telegramGenerateHosted.
  ///
  /// In tr, this message translates to:
  /// **'5 fikir varyantı üret (barındırılan API)'**
  String get telegramGenerateHosted;

  /// No description provided for @telegramLiveHint.
  ///
  /// In tr, this message translates to:
  /// **'Varyantlar meme_briefs olarak kaydedilir; görseller Python API’de OPENAI_API_KEY kullanır.'**
  String get telegramLiveHint;

  /// No description provided for @telegramStep3Title.
  ///
  /// In tr, this message translates to:
  /// **'Metin ve görsel'**
  String get telegramStep3Title;

  /// No description provided for @telegramStep3Subtitle.
  ///
  /// In tr, this message translates to:
  /// **'Bir varyanta dokun; meme görselini üret.'**
  String get telegramStep3Subtitle;

  /// No description provided for @telegramGeneratingMeme.
  ///
  /// In tr, this message translates to:
  /// **'Mem görseli oluşturuluyor…'**
  String get telegramGeneratingMeme;

  /// No description provided for @telegramGenerateMemeButton.
  ///
  /// In tr, this message translates to:
  /// **'Seçimden meme üret'**
  String get telegramGenerateMemeButton;

  /// No description provided for @telegramSnackSaved.
  ///
  /// In tr, this message translates to:
  /// **'Görsel üretildi ve Supabase’e kaydedildi (Storage: meme-assets).'**
  String get telegramSnackSaved;

  /// No description provided for @telegramSourceLabel.
  ///
  /// In tr, this message translates to:
  /// **'Telegram akışı'**
  String get telegramSourceLabel;

  /// No description provided for @telegramAssetVersion.
  ///
  /// In tr, this message translates to:
  /// **'Varlık sürümü: {id}'**
  String telegramAssetVersion(String id);

  /// No description provided for @telegramErrShortLink.
  ///
  /// In tr, this message translates to:
  /// **'Tam kanal bağlantısı yapıştırın (en az 8 karakter).'**
  String get telegramErrShortLink;

  /// No description provided for @telegramErrStubOffline.
  ///
  /// In tr, this message translates to:
  /// **'Bu çevrimdışı stub verisi, gerçek kanalınız değil. .env içinde TELEGRAM_* + oturum ile ./run_telegram_api.sh başlatın ve tekrar deneyin.'**
  String get telegramErrStubOffline;

  /// No description provided for @telegramErrTooFewIdeas.
  ///
  /// In tr, this message translates to:
  /// **'Sunucudan çok az fikir geldi ({count}). API .env içinde OPENAI_API_KEY kontrol edin.'**
  String telegramErrTooFewIdeas(int count);

  /// No description provided for @telegramErrNoIdeas.
  ///
  /// In tr, this message translates to:
  /// **'Sunucudan fikir gelmedi.'**
  String get telegramErrNoIdeas;

  /// No description provided for @telegramFutureContext.
  ///
  /// In tr, this message translates to:
  /// **'Telegram içe aktarma — kanal DNA’sı olarak meme ajanlarına verin.'**
  String get telegramFutureContext;

  /// No description provided for @tgProgressFetching.
  ///
  /// In tr, this message translates to:
  /// **'Kanal mesajları alınıyor ve özet oluşturuluyor…'**
  String get tgProgressFetching;

  /// No description provided for @tgProgressPreparing.
  ///
  /// In tr, this message translates to:
  /// **'Bağlam hazırlanıyor…'**
  String get tgProgressPreparing;

  /// No description provided for @tgProgressIdeas.
  ///
  /// In tr, this message translates to:
  /// **'7–10 meme fikri (AI) üretiliyor ve çalışma alanınıza kaydediliyor…'**
  String get tgProgressIdeas;

  /// No description provided for @tgProgressImage.
  ///
  /// In tr, this message translates to:
  /// **'Seçilen varyanttaki meme görseli oluşturuluyor…'**
  String get tgProgressImage;

  /// No description provided for @tgProgressSaving.
  ///
  /// In tr, this message translates to:
  /// **'Kaydediliyor…'**
  String get tgProgressSaving;

  /// No description provided for @retry.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden dene'**
  String get retry;

  /// No description provided for @imageLoadError.
  ///
  /// In tr, this message translates to:
  /// **'Görsel yüklenemedi'**
  String get imageLoadError;

  /// No description provided for @imageOfflineError.
  ///
  /// In tr, this message translates to:
  /// **'Görsel URL’si var ancak çevrimdışı görüntülenemedi.'**
  String get imageOfflineError;

  /// No description provided for @errUnexpected.
  ///
  /// In tr, this message translates to:
  /// **'Bir şeyler ters gitti. Lütfen tekrar deneyin.'**
  String get errUnexpected;

  /// No description provided for @errNetworkUser.
  ///
  /// In tr, this message translates to:
  /// **'Sunucuya ulaşılamıyor. Bağlantınızı kontrol edin.'**
  String get errNetworkUser;

  /// No description provided for @errNetworkDebug.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps API’ye ulaşılamıyor. Proje kökünde ./run_telegram_api.sh çalıştırın (veya MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh).'**
  String get errNetworkDebug;

  /// No description provided for @errApiTimeoutDebug.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps API zaman aşımı ({origin}, {seconds} sn).'**
  String errApiTimeoutDebug(String origin, int seconds);

  /// No description provided for @errApiTimeoutUser.
  ///
  /// In tr, this message translates to:
  /// **'Sunucu çok geç yanıt verdi. Daha sonra tekrar deneyin.'**
  String get errApiTimeoutUser;

  /// No description provided for @errApiUnreachableDebug.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps API’ye ({origin}) ulaşılamıyor. Proje kökünde: ./run_telegram_api.sh (Python, port {port}; .env’de TELEGRAM_* + OPENAI_* gerekir). Veya: MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh — aynı API’yi başlatır. OpenAI/Telegram yoksa Dart stub: dart run tool/memeops_dev_server.dart --port {port}.'**
  String errApiUnreachableDebug(String origin, int port);

  /// No description provided for @errApiUnreachableUser.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps sunucusuna ulaşılamıyor. Bağlantınızı kontrol edin.'**
  String get errApiUnreachableUser;

  /// No description provided for @debugApiNotRunning.
  ///
  /// In tr, this message translates to:
  /// **'MemeOps: {base} yanıt vermiyor. Gömülü stub BAŞLATILMIYOR (MEMEOPS_USE_PYTHON_API=1). Önce ./run_telegram_api.sh çalıştır, sonra uygulamayı yeniden aç.'**
  String debugApiNotRunning(String base);

  /// No description provided for @archiveDebugSkip.
  ///
  /// In tr, this message translates to:
  /// **'Arşiv kaydı atlandı: {error}'**
  String archiveDebugSkip(String error);

  /// No description provided for @stubDefaultTopic.
  ///
  /// In tr, this message translates to:
  /// **'konu'**
  String get stubDefaultTopic;

  /// No description provided for @stubProfessionIdea1.
  ///
  /// In tr, this message translates to:
  /// **'Beklenti ve gerçek mizahı: «{topic}»'**
  String stubProfessionIdea1(String topic);

  /// No description provided for @stubProfessionIdea2.
  ///
  /// In tr, this message translates to:
  /// **'«{topic}» gönderisine kitle tepkisi'**
  String stubProfessionIdea2(String topic);

  /// No description provided for @stubProfessionIdea3.
  ///
  /// In tr, this message translates to:
  /// **'«{topic}» nişindeki tartışmanın ironisi'**
  String stubProfessionIdea3(String topic);

  /// No description provided for @stubProfessionIdea4.
  ///
  /// In tr, this message translates to:
  /// **'Önce/sonra: «{topic}» farkındalığı'**
  String stubProfessionIdea4(String topic);

  /// No description provided for @stubProfessionIdea5.
  ///
  /// In tr, this message translates to:
  /// **'«{topic}» kitlesinin iç şakaları'**
  String stubProfessionIdea5(String topic);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
