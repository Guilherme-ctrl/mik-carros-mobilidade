class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');
  static const buildNumber = String.fromEnvironment('BUILD_NUMBER', defaultValue: '1');
}
