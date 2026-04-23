/// Web / no-IO platforms: no in-process stub.
abstract final class EmbeddedMemeopsDevApi {
  static Future<void> tryStart() async {}
}
