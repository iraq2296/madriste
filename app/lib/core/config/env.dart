/// Build-time configuration injected with `--dart-define` / `--dart-define-from-file`.
///
/// Only **public** client values belong here (Supabase URL + anon key, which are
/// safe to ship because every table is protected by Row-Level Security).
/// Secrets (service-role key, payment gateway secrets, Agora certificate,
/// FCM server credentials) live ONLY in backend Edge Function secrets.
class Env {
  Env._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Agora App ID (public) for in-app audio/video meetings.
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  /// Store URLs used by the mandatory-update screen.
  static const playStoreUrl = String.fromEnvironment(
    'PLAY_STORE_URL',
    defaultValue: 'https://play.google.com/store/apps/details?id=iq.madrasi.madrasi',
  );
  static const appStoreUrl = String.fromEnvironment('APP_STORE_URL');

  /// Current client build version (kept in sync with pubspec `version`).
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

  static bool get isBackendConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// Preview mode runs the full UI against an in-memory data store so that
  /// screens can be reviewed before the backend is provisioned. It is never
  /// enabled when backend credentials are present.
  static bool get isPreview => !isBackendConfigured;
}

