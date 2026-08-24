class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleMapsApiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  // appVersion/buildNumber saíram daqui: vinham de --dart-define que ninguém
  // passava, então serviam só para reportar uma versão falsa ao Sentry. Agora
  // main.dart lê do bundle via PackageInfo.
}
