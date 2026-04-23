import 'package:hakaton_moskova_app/core/config/app_env.dart';
import 'package:hakaton_moskova_app/data/publication/telegram_bot_publication_port.dart';
import 'package:hakaton_moskova_app/domain/publication_port.dart';

PublicationPort createPublicationPort() {
  if (AppEnv.isTelegramPublishConfigured) {
    return TelegramBotPublicationPort();
  }
  return StubPublicationPort();
}
