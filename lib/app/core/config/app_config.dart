abstract final class AppConfig {
  static const String appName = 'Visitor Management';

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://playground.nileslabs.com/api/v1',
  );

  static const String visitorsResource = String.fromEnvironment(
    'API_VISITORS_PATH',
    defaultValue: '/custom/visitors',
  );

  static const String playgroundIdentity = String.fromEnvironment(
    'API_IDENTITY',
    defaultValue: '6f5c1e2a-8b7d-4c3e-9a1f-2d4b6c8e0a13',
  );

  static const Duration apiTimeout = Duration(seconds: 20);
}
