/// Central, non-secret configuration for G.R. Book.
///
/// IMPORTANT (see project requirement #46):
/// - `supabaseUrl` and `supabaseAnonKey` are PUBLIC/CLIENT-SAFE values.
///   They are safe to ship inside the APK because Supabase enforces
///   access exclusively through Row Level Security (see
///   supabase/sql/02_rls_policies.sql) — the anon key alone grants
///   nothing without a valid authenticated session and a matching
///   school_members row.
/// - The Supabase **service-role key must NEVER** appear here, in the
///   app, or in any client-side code. It is only ever used from a
///   trusted server context (e.g. a Supabase Edge Function), and this
///   project does not require one for its current feature set.
///
/// HOW TO CONFIGURE:
/// Supply real values at build time instead of hard-coding them here,
/// e.g.:
///   flutter run \
///     --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
/// or via a `.env`-style loader of your choice. The String.fromEnvironment
/// fallbacks below are placeholders only and will not work until replaced.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://paisrmhvdeevekksewsb.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_Q7-yXj36gzhxnhZLIxk4Rw_GE_dodFp',
  );

  /// Google Sign-In OAuth client ID (Android), for Google Drive backup.
  /// Public by design — configured in Google Cloud Console, not a secret.
  static const String googleOAuthClientId = String.fromEnvironment(
    'GOOGLE_OAUTH_CLIENT_ID',
    defaultValue: '854448656632-jrjdeuq7hlte70ghbqkf7fumvvig2du2.apps.googleusercontent.com',
  );

  static const String studentPhotosBucket = 'student-photos';

  /// How long a signed URL for a private student photo stays valid.
  static const int signedUrlExpirySeconds = 3600;

  /// Default configurable rules (mirrors the `classes` table columns so
  /// the app has sane defaults before the first sync completes offline).
  static const int defaultEceMinAdmissionAgeMonths = 36; // 3 years
  static const int defaultEceToClass1MinAgeMonths = 61; // 5 years 1 month

  static bool get isConfigured =>
      !supabaseUrl.contains('YOUR-PROJECT-REF') &&
      !supabaseAnonKey.contains('YOUR-SUPABASE-ANON-PUBLIC-KEY');
}
