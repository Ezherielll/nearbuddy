/// Compile-time build flavor config. Set via --dart-define=FLAVOR=dev|prod.
abstract final class AppConfig {
  static const String flavor =
      String.fromEnvironment('FLAVOR', defaultValue: 'prod');
  static const bool isDev = flavor == 'dev';
  static const String databaseName = isDev ? 'nearbuddy_db_dev' : 'nearbuddy_db';

  /// Nearby service ID — dev and prod builds must not discover each other.
  static String nearbyServiceId(String groupId) =>
      isDev ? 'com.nearbuddy.dev.$groupId' : 'com.nearbuddy.$groupId';
}
