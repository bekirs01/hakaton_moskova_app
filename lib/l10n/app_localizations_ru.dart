// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MemeOps';

  @override
  String get defaultDisplayName => 'создатель';

  @override
  String greeting(String name) {
    return 'Добрый день, $name';
  }

  @override
  String get backToLogin => 'Вернуться ко входу';

  @override
  String get homeSubtitle => 'Продолжайте поток мемов — выберите вкладку ниже.';

  @override
  String get tabProfession => 'Профессия';

  @override
  String get tabTelegram => 'Telegram';

  @override
  String get tabAnalysis => 'Анализ';

  @override
  String get tabPublish => 'Публикация';

  @override
  String get tabArchive => 'Архив';

  @override
  String get languageTitle => 'Язык';

  @override
  String get languageTurkish => 'Türkçe';

  @override
  String get languageRussian => 'Русский';

  @override
  String get languagePickHint =>
      'Выберите язык приложения. Все тексты изменятся.';

  @override
  String get authTagline => 'Идеи для юмора и картинки — в одном потоке';

  @override
  String get authSignInTitle => 'Вход';

  @override
  String get authUsername => 'Имя пользователя';

  @override
  String get authUsernameHint => 'admin';

  @override
  String get authPassword => 'Пароль';

  @override
  String get authPasswordHint => '12345678';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authSignUp => 'Первый запуск: создать аккаунт (admin + пароль)';

  @override
  String get authErrEmptyUser => 'Введите имя пользователя.';

  @override
  String get authErrNoAt => 'Только имя пользователя (без @ и e-mail).';

  @override
  String get authErrPasswordShort =>
      'Пароль не короче 6 символов (например 12345678).';

  @override
  String get authErrInvalidLogin =>
      'Такого пользователя нет в Supabase или неверный пароль. Попробуйте «Первый запуск: создать аккаунт» ниже или добавьте пользователя в Dashboard → Authentication → Users.';

  @override
  String get authErrAlreadyRegistered =>
      'Пользователь уже существует. Используйте «Войти».';

  @override
  String get authSnackSignUp =>
      'Регистрация создана. Если вход не выполнен: Supabase → Authentication → Providers → отключите «Confirm email» и попробуйте снова, или перейдите по ссылке в письме.';

  @override
  String get authBenefitTitle => 'Что вы получите после входа?';

  @override
  String get authBenefitTelegram => 'Живое резюме канала Telegram и идеи';

  @override
  String get authBenefitProfession => 'AI-ситуации для профессии / темы';

  @override
  String get authBenefitImage => 'Квадратный мем через gpt-image-1';

  @override
  String get authBenefitSupabase => 'Брифы и версии изображений в Supabase';

  @override
  String get configTitle => 'Настройка';

  @override
  String get configBody =>
      'Не заданы публичный URL Supabase + anon key и база MemeOps API. В приложении нет сервисной роли или ключа OpenAI:';

  @override
  String get configBullet1 =>
      '1) Файл `.env` в корне проекта (скопируйте из env.sample) — IDE / симулятор читают его.';

  @override
  String get configBullet2 =>
      '2) flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=MEMEOPS_API_BASE=https://...';

  @override
  String get configApiNote =>
      'Локальный API: MEMEOPS_API_BASE=http://127.0.0.1:3000 (совместимо с iOS Simulator; ./run_dev.sh или ./run_telegram_api.sh).';

  @override
  String get archiveTitle => 'Архив';

  @override
  String get archiveSubtitle =>
      'Локальные файлы; картинки и видео из Supabase того же аккаунта в общем списке. Фильтр: устройство / Supabase.';

  @override
  String get archiveSourceCloud => 'Supabase';

  @override
  String get archiveSupabaseLoadError =>
      'Не удалось загрузить список с сервера. Показан только локальный архив.';

  @override
  String get archiveFilterAll => 'Все';

  @override
  String get archiveFilterLocal => 'Устройство';

  @override
  String get archiveFilterCloud => 'Supabase';

  @override
  String get archiveEmpty =>
      'Пока нет сохранённых изображений.\nСоздайте мем во вкладке «Профессия» или «Telegram».';

  @override
  String get archiveFileMissing => 'Файл не найден (возможно удалён).';

  @override
  String get archiveShare => 'Поделиться';

  @override
  String get archiveVideoErrorTitle => 'Видео не воспроизводится';

  @override
  String get archiveShareFailed => 'Не удалось открыть меню шаринга.';

  @override
  String archiveShareFailedWithError(String error) {
    return 'Публикация: $error';
  }

  @override
  String get archiveShareSheetSubtitle =>
      'Telegram или ВК. Расписание и текст — внутри карточки в архиве.';

  @override
  String get archiveCaptionLabel => 'Текст к посту';

  @override
  String get archiveCaptionSave => 'Сохранить текст';

  @override
  String get archiveCaptionSaved => 'Текст сохранён.';

  @override
  String get archiveCaptionCloudNeedsBrief =>
      'Нет связанного brief; текст используется только для этой отправки.';

  @override
  String get archivePublishTitle => 'Публикация';

  @override
  String get archiveTelegramSmartRoutingTitle => 'Telegram: умный выбор канала';

  @override
  String archiveTelegramSmartRoutingHint(String channel) {
    return 'По тексту и заголовку сейчас выделен «$channel». Отметьте нужные каналы ниже; в несколько можно отправить одну публикацию.';
  }

  @override
  String get archiveTelegramSuggestedBadge => 'Советуем';

  @override
  String get archivePlatformNameTelegram => 'Telegram';

  @override
  String get archivePlatformNameVk => 'VK';

  @override
  String get archivePlatformNameDzen => 'Дзен';

  @override
  String get archiveWeRecommendTitle => 'Рекомендации для вас';

  @override
  String get archiveTelegramRecMatchesThisPost =>
      'Лучше всего под это сообщение';

  @override
  String archiveTelegramRecCategoryName(String category, String name) {
    return '$category → $name';
  }

  @override
  String get archiveTelegramRecFooter =>
      'По тексту и словам (косметика, школа и т.д.) отмечается подходящий канал. VK / Дзен: только «опубликовано» без реальной отправки с вашей стороны (кроме Telegram-бота).';

  @override
  String get archivePublishChannelsSubtitle =>
      'Telegram, VK, Дзен. Каналы в нижней карточке — только для направления в Telegram.';

  @override
  String get archivePublishSelectAtLeastOneChannel =>
      'Выберите хотя бы один канал.';

  @override
  String get archivePublishWhenHeading => 'Когда отправить';

  @override
  String get archivePublishWhenNow => 'Сразу';

  @override
  String get archivePublishWhenSchedule => 'Позже';

  @override
  String get archivePublishPickDateTime => 'Дата и время';

  @override
  String get archivePublishSubmit => 'Отправить';

  @override
  String archivePublishScheduledAck(String when) {
    return 'Запланировано: $when';
  }

  @override
  String get archivePublishChooseSchedule => 'Сначала выберите дату и время.';

  @override
  String get archivePublishSchedulePast => 'Время не может быть в прошлом.';

  @override
  String get archivePublishScheduleNeedOpenApp =>
      'Очередь работает пока приложение открыто; если закрыто — отправка может задержаться.';

  @override
  String archiveDownloadFailed(int code) {
    return 'Не удалось скачать изображение (HTTP $code).';
  }

  @override
  String get archiveListLoadError =>
      'Список долго не открывался. Потяните вниз, чтобы обновить.';

  @override
  String get archiveEntryDeleteTitle => 'Удалить?';

  @override
  String get archiveEntryDeleteMessage =>
      'Запись удалится безвозвратно. Строка в Supabase (и файл, если получится) и локальный файл.';

  @override
  String get archiveEntryDelete => 'Удалить';

  @override
  String get archiveEntryDeleteCancel => 'Отмена';

  @override
  String get publishTitle => 'Публикация';

  @override
  String get publishBody =>
      'В будущем: отправка сохранённых строк `meme_brief` + `asset` в подключённые каналы Telegram / VK и т.д. через `publish_jobs` на бэкенде. В мобильном приложении пока не реализовано.';

  @override
  String get publishStubButton => 'Вызвать PublicationPort (заглушка)';

  @override
  String get publicationComingSoon => 'Конвейер публикации ещё не подключён.';

  @override
  String get publicationDone => 'Готово';

  @override
  String get shareTargetTitle => 'Куда опубликовать?';

  @override
  String get shareTargetSubtitle =>
      'Выберите сервис; сеть уйдёт только на эту публикацию.';

  @override
  String get shareTargetTelegram => 'Telegram';

  @override
  String get shareTargetVk => 'ВКонтакте (стена группы)';

  @override
  String get shareTargetDzen => 'Дзен';

  @override
  String get shareNoServiceConfigured =>
      'В .env нужны TELEGRAM_PUBLISH_* или VK_ACCESS_TOKEN + VK_GROUP_ID; Дзен также всегда доступен (имитация).';

  @override
  String get archivePublishNoTgVkDzenOnly =>
      'Telegram и VK в .env не настроены. Можно выбрать Дзен (имитация).';

  @override
  String get dzenPublishSimulated => 'Дзен: публикация учтена.';

  @override
  String get vkPostDone => 'Опубликовано в VK.';

  @override
  String get vkPostFailed => 'Публикация в VK не удалась.';

  @override
  String get vkPostNeedUserToken =>
      'VK: community token не подходит для загрузки. Добавь OAuth пользователя в .env: VK_USER_ACCESS_TOKEN= (права: wall, photos, video, groups, offline). Скрипт: ./setup_vk_user_token.sh';

  @override
  String get analysisTitle => 'Анализ Telegram';

  @override
  String get analysisSubtitle =>
      'Собирайте сигналы из live-анализа: когда канал активнее, какие форматы тянут лучше и какие посты выглядят сильнее.';

  @override
  String get analysisEmpty =>
      'Сначала проанализируйте канал во вкладке Telegram. Последний результат появится здесь.';

  @override
  String get analysisOverview => 'Общий обзор';

  @override
  String get analysisSampleSize => 'Постов в выборке';

  @override
  String get analysisSource => 'Источник';

  @override
  String get analysisSourceLive => 'Живой анализ Telethon';

  @override
  String get analysisSourceStub => 'Stub / ограниченные данные';

  @override
  String get analysisActivity => 'Окна активности';

  @override
  String get analysisNoActivity => 'Пока нет данных по активности.';

  @override
  String get analysisTopPosts => 'Лучшие посты';

  @override
  String get analysisNoTopPosts => 'Пока нет данных по лучшим постам.';

  @override
  String get analysisAudience => 'Сигналы аудитории и отклика';

  @override
  String get analysisNoAudience => 'Пока нет сигналов вовлечения.';

  @override
  String get analysisOpportunities => 'Контентные возможности';

  @override
  String get analysisNoOpportunities =>
      'Пока не удалось выделить контентные возможности.';

  @override
  String get analysisMyPublications => 'Отправлено в канал с этого устройства';

  @override
  String get analysisMyPublicationsBody =>
      'После публикации в Telegram или VK из «Архива» здесь появляется запись. В деталях — просмотры; для VK обновите кнопкой. Ниже — анализ канала.';

  @override
  String get analysisNoMyPublications =>
      'Пока нет публикаций в канал из приложения. Попробуй «Поделиться» в Профессии / Telegram или в «Архиве».';

  @override
  String get analysisEmptyVideoGrid =>
      'Пока нет опубликованных видео. Поделись из «Архива» в Telegram или VK — карточка появится здесь.';

  @override
  String get analysisNotSharedTitle => 'Пока нет метрик';

  @override
  String get analysisNotSharedBody =>
      'Файл в архиве, но нет публикации из приложения в Telegram/VK. Поделись из «Архива». Старые записи без id могут не сопасться.';

  @override
  String get analysisOpenPreview => 'Открыть просмотр';

  @override
  String analysisViewCount(int n) {
    return '$n просм.';
  }

  @override
  String get analysisViewUnknown => 'просм.: —';

  @override
  String get analysisPostKindImage => 'Картинка';

  @override
  String get analysisPostKindVideo => 'Видео';

  @override
  String get analysisPlatformTelegram => 'Telegram';

  @override
  String get analysisPlatformVk => 'ВКонтакте';

  @override
  String get myPubSummaryTitle => 'Сводка публикаций';

  @override
  String get myPubSummaryEmpty =>
      'На этом устройстве ещё нет записей о публикациях. Поделись из «Архива» — цифры появятся после загрузки метрик.';

  @override
  String get myPubSummaryTotalLabel => 'Всего публикаций';

  @override
  String get myPubSummaryViewsLabel => 'Суммарные просмотры (где известны)';

  @override
  String get myPubSummaryByType => 'Тип контента (шт.)';

  @override
  String get myPubSummaryByPlatform => 'Платформа (шт.)';

  @override
  String myPubSummaryRolling(int cur, int prev) {
    return 'Последние 7 дней: $cur публ. · предыдущие 7 дней: $prev публ.';
  }

  @override
  String get myPubSummaryChartTitle => '7 дней — публикации по дням';

  @override
  String get myPubSummaryTypeViews => 'Просмотры по типу';

  @override
  String get myPubSummaryPlatformViews => 'Просмотры по платформе';

  @override
  String get myPubSummaryBest => 'Самый просматриваемый (в логе)';

  @override
  String get myPubSummaryDzenLabel => 'Дзен';

  @override
  String get myPubSummaryDzenNoViews =>
      'Дзен: имитация, просмотры не учитываются.';

  @override
  String get myPubImageShort => 'Фото';

  @override
  String get myPubVideoShort => 'Видео';

  @override
  String get myPubOpenFullAnalytics => 'Вся аналитика публикаций';

  @override
  String get myPubOpenFullAnalyticsSubtitle =>
      'Графики, сводка и превью по каждому посту';

  @override
  String get myPubFullPageTitle => 'Детальная аналитика';

  @override
  String get myPubPerPostListTitle => 'Посты (по просмотрам, с превью)';

  @override
  String get myPubPerPostNoThumb => '—';

  @override
  String get myPubViewUnknown => 'Просмотры: неизвестно';

  @override
  String get myPubPlatformVkTr => 'VK';

  @override
  String get publicationDetailTitle => 'Детали публикации';

  @override
  String get publicationDetailSectionInfo => 'Сведения';

  @override
  String get publicationDetailPublishedAt => 'Публикация';

  @override
  String get publicationDetailRefreshTelegram => 'Обновить метрики Telegram';

  @override
  String get publicationDetailRefreshVk => 'Обновить статистику VK';

  @override
  String get publicationDetailReactions => 'Реакции';

  @override
  String get publicationDetailReactionsEmpty => '—';

  @override
  String publicationDetailEmojiReaction(String emoji, int count) {
    return '$emoji  ×$count';
  }

  @override
  String publicationDetailCustomReaction(int count) {
    return 'Своя  ×$count';
  }

  @override
  String publicationDetailReactionCountOnly(int count) {
    return '×$count';
  }

  @override
  String get publicationDetailKind => 'Тип';

  @override
  String get publicationDetailMessageId => 'Сообщение';

  @override
  String get publicationDetailChat => 'Чат';

  @override
  String get publicationDetailChannel => 'Канал (Telegram)';

  @override
  String get publicationDetailViews => 'Просмотры';

  @override
  String get publicationDetailForwards => 'Пересылок (Telegram)';

  @override
  String get publicationDetailVkGroup => 'Группа';

  @override
  String get publicationDetailVkPost => 'Пост';

  @override
  String get publicationDetailVkHint => 'Нажмите «Обновить»';

  @override
  String get publicationDetailLikes => 'Лайки';

  @override
  String get publicationDetailReposts => 'Репосты';

  @override
  String get publicationDetailCaption => 'Текст';

  @override
  String get publicationDetailTabAll => 'Все';

  @override
  String get publicationDetailTabDzen => 'Дзен';

  @override
  String get publicationDetailDzen => 'Статус';

  @override
  String get publicationDetailDzenBody => 'Имитация; метрик нет.';

  @override
  String get publicationDetailMembers => 'Сообщество (подписчики)';

  @override
  String get publicationDetailTgReplies => 'Комментарии (обсуждение)';

  @override
  String get publicationDetailTgMessageTime => 'Время поста (Telegram)';

  @override
  String get publicationDetailComments => 'Комментарии';

  @override
  String get publicationDetailStatsNotFound =>
      'Пост не найден для этой сессии. Проверьте канал и номер; API: ./run_telegram_api.sh';

  @override
  String get publicationDetailRefreshAll => 'Обновить';

  @override
  String get professionStep1Title => 'Профессия или тема';

  @override
  String get professionStep1Subtitle =>
      'Краткий заголовок, чтобы получить 7–10 идей ситуаций от AI.';

  @override
  String get professionFlowCaption =>
      'Поток профессии — идеи GPT + gpt-image-1';

  @override
  String get professionNameLabel => 'Название профессии';

  @override
  String get professionNameHint => 'напр. архитектор, медсестра, волшебник';

  @override
  String get professionGenerateIdeas => 'Сгенерировать идеи ситуаций';

  @override
  String get professionStartOver => 'Начать заново';

  @override
  String get professionStep2Title => 'Выберите текст';

  @override
  String get professionStep2Subtitle =>
      'Нажмите на строку; затем создайте изображение.';

  @override
  String get professionGeneratingMeme => 'Создаётся изображение мема…';

  @override
  String get professionGenerateImage => 'Создать изображение мема';

  @override
  String get professionErrShortName =>
      'Введите название профессии (не меньше 3 символов).';

  @override
  String get professionErrNoVariants =>
      'Сервер не вернул варианты. Проверьте бэкенд / режим mock.';

  @override
  String get professionSnackSaved =>
      'Изображение создано и сохранено в Supabase (Storage: meme-assets; таблицы: meme_assets / meme_asset_versions).';

  @override
  String get professionSourceLabel => 'Поток профессии';

  @override
  String get professionPublication => 'Публикация (скоро)';

  @override
  String get profProgressCreating => 'Создаётся запись профессии…';

  @override
  String get profProgressSituations =>
      'Генерируются 7–10 идей ситуаций (OpenAI на API)…';

  @override
  String get profProgressImage => 'Создаётся изображение мема…';

  @override
  String get profProgressSaving => 'Сохранение результата…';

  @override
  String get telegramChannelDefault => 'Канал Telegram';

  @override
  String get telegramStep1Title => 'Ссылка на канал';

  @override
  String get telegramStep1SubtitleLive =>
      'Живое резюме через локальный Telethon API; идеи из того же контекста.';

  @override
  String get telegramStep1SubtitleStub =>
      'Публичная ссылка на канал · для живого чтения запустите ./run_telegram_api.sh';

  @override
  String get telegramLinkLabel => 'Канал Telegram / публичная ссылка';

  @override
  String get telegramQuickPickTitle => 'Быстрый выбор (канал)';

  @override
  String get telegramQuickPickRecommended => 'Советуем';

  @override
  String get telegramQuickChannelMems => 'memsit52';

  @override
  String get telegramQuickChannelNakida => 'nakidaifuturememes';

  @override
  String get telegramQuickPickHintLearn =>
      'Если в теме профессии есть обучение / школа, подсвечиваем канал «будущее / обучение».';

  @override
  String get telegramAnalyzing => 'Анализ канала…';

  @override
  String get telegramAnalyseButton => 'Анализировать ссылку';

  @override
  String get telegramStep2Title => 'Резюме и идеи';

  @override
  String get telegramStep2Subtitle =>
      'Проверьте ДНК канала; затем создайте варианты.';

  @override
  String get telegramStubBanner =>
      'Режим заглушки — Telegram не читается. Запустите ./run_telegram_api.sh с TELEGRAM_* и действующей TELEGRAM_SESSION_STRING в .env.';

  @override
  String telegramInsightChannel(String title) {
    return 'Канал: $title';
  }

  @override
  String telegramInsightTopic(String topic) {
    return 'Тема: $topic';
  }

  @override
  String telegramInsightStyle(String style) {
    return 'Стиль: $style';
  }

  @override
  String telegramInsightTone(String tone) {
    return 'Тон: $tone';
  }

  @override
  String telegramInsightThemes(String themes) {
    return 'Темы: $themes';
  }

  @override
  String telegramInsightPostMix(String mix) {
    return 'Смесь постов: $mix';
  }

  @override
  String telegramInsightMediaTypes(String types) {
    return 'Типы медиа: $types';
  }

  @override
  String get telegramMediaSection => 'Медиа / изображения';

  @override
  String get telegramRecentSection => 'Недавние примеры';

  @override
  String telegramMemeAngles(String angles) {
    return 'Углы для мемов: $angles';
  }

  @override
  String get telegramBadgeLive => 'Живой';

  @override
  String get telegramBadgeStub => 'Stub';

  @override
  String get telegramGenerateLive =>
      'Сгенерировать и сохранить 7–10 AI-вариантов';

  @override
  String get telegramGenerateHosted =>
      'Сгенерировать 5 вариантов идей (хостинг API)';

  @override
  String get telegramLiveHint =>
      'Варианты сохраняются как meme_briefs; изображения используют OPENAI_API_KEY в Python API.';

  @override
  String get telegramStep3Title => 'Текст и изображение';

  @override
  String get telegramStep3Subtitle =>
      'Нажмите на вариант; создайте изображение мема.';

  @override
  String get telegramGeneratingMeme => 'Создаётся изображение мема…';

  @override
  String get telegramGenerateMemeButton => 'Создать мем из выбора';

  @override
  String get telegramSnackSaved =>
      'Изображение создано и сохранено в Supabase (Storage: meme-assets).';

  @override
  String get telegramSourceLabel => 'Поток Telegram';

  @override
  String telegramAssetVersion(String id) {
    return 'Версия ассета: $id';
  }

  @override
  String get memeVideoTitle => 'Короткое видео из мема';

  @override
  String get memeVideoSubtitle => 'Клип 4, 8 или 12 с, сохраняется в архиве.';

  @override
  String memeVideoGenerating(String seconds) {
    return 'Создаём видео $seconds с (Sora), обычно 1–3 минуты.';
  }

  @override
  String memeVideoSaved(int seconds) {
    return 'Видео $seconds с сохранено. Откройте вкладку «Архив».';
  }

  @override
  String memeVideoSec(String n) {
    return '$n с';
  }

  @override
  String get telegramErrShortLink =>
      'Вставьте полную ссылку на канал (минимум 8 символов).';

  @override
  String get telegramErrStubOffline =>
      'Это офлайн-заглушка, не ваш канал. Запустите ./run_telegram_api.sh с TELEGRAM_* и сессией в .env и попробуйте снова.';

  @override
  String telegramErrTooFewIdeas(int count) {
    return 'Слишком мало идей с сервера ($count). Проверьте OPENAI_API_KEY в .env API.';
  }

  @override
  String get telegramErrNoIdeas => 'Сервер не вернул идей.';

  @override
  String get telegramFutureContext =>
      'Импорт из Telegram — передайте агентам мемов как ДНК канала.';

  @override
  String get tgProgressFetching => 'Загрузка сообщений канала и сводки…';

  @override
  String get tgProgressPreparing => 'Подготовка контекста…';

  @override
  String get tgProgressIdeas =>
      'Генерация 7–10 идей мемов (AI) и сохранение в рабочую область…';

  @override
  String get tgProgressImage => 'Создание мема по выбранному варианту…';

  @override
  String get tgProgressSaving => 'Сохранение…';

  @override
  String get retry => 'Повторить';

  @override
  String get imageLoadError => 'Ошибка загрузки изображения';

  @override
  String get imageOfflineError =>
      'URL изображения есть, но офлайн показать нельзя.';

  @override
  String get errUnexpected => 'Что-то пошло не так. Попробуйте ещё раз.';

  @override
  String get errNetworkUser =>
      'Не удаётся связаться с сервером. Проверьте подключение.';

  @override
  String get errNetworkDebug =>
      'Нет доступа к MemeOps API. В корне проекта выполните ./run_telegram_api.sh (или MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh).';

  @override
  String errApiTimeoutDebug(String origin, int seconds) {
    return 'Тайм-аут MemeOps API ($origin, $seconds с).';
  }

  @override
  String get errApiTimeoutUser =>
      'Сервер отвечает слишком долго. Попробуйте позже.';

  @override
  String errApiUnreachableDebug(String origin, int port) {
    return 'Нет доступа к MemeOps API ($origin). В корне: ./run_telegram_api.sh (Python, порт $port; в .env нужны TELEGRAM_* + OPENAI_*). Или: MEMEOPS_USE_PYTHON_API=1 ./run_dev.sh — тот же API. Без OpenAI/Telegram можно Dart-заглушку: dart run tool/memeops_dev_server.dart --port $port.';
  }

  @override
  String get errApiUnreachableUser =>
      'Не удаётся связаться с сервером MemeOps. Проверьте сеть.';

  @override
  String debugApiNotRunning(String base) {
    return 'MemeOps: $base не отвечает. Встроенная заглушка НЕ запускается (MEMEOPS_USE_PYTHON_API=1). Сначала ./run_telegram_api.sh, затем откройте приложение снова.';
  }

  @override
  String archiveDebugSkip(String error) {
    return 'Запись в архив пропущена: $error';
  }

  @override
  String get stubDefaultTopic => 'тема';

  @override
  String stubProfessionIdea1(String topic) {
    return 'Мем-контраст: ожидание vs реальность в «$topic»';
  }

  @override
  String stubProfessionIdea2(String topic) {
    return 'Реакция аудитории на пост про «$topic»';
  }

  @override
  String stubProfessionIdea3(String topic) {
    return 'Ирония над спором в нише «$topic»';
  }

  @override
  String stubProfessionIdea4(String topic) {
    return 'До/после: осознание про «$topic»';
  }

  @override
  String stubProfessionIdea5(String topic) {
    return 'Внутренний жаргон аудитории «$topic»';
  }
}
