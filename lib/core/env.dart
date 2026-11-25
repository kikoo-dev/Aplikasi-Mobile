/// Konfigurasi Supabase.
///
/// ADA 2 CARA MENGISI KREDENSIAL:
///
/// 1) Cara cepat  -> ganti 2 konstanta di bawah ini (SUPABASE_URL & SUPABASE_ANON_KEY).
/// 2) Cara aman   -> jalankan dengan dart-define:
///    flutter run --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///                --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
///
/// Selama kredensial belum diisi, aplikasi otomatis berjalan dalam
/// **MODE DEMO** (data disimpan lokal di perangkat) supaya UI tetap bisa dicoba.
/// Begitu kredensial valid diisi, aplikasi otomatis memakai Supabase.
class Env {
  Env._();

  static const String _urlFromDefine = String.fromEnvironment('SUPABASE_URL');
  static const String _keyFromDefine =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  // ======================= GANTI DI SINI =======================
  // Project: cgqespmtpvoafiinygao (ITENAS ProfilKita)
  static const String supabaseUrl = _urlFromDefine != ''
      ? _urlFromDefine
      : 'https://cgqespmtpvoafiinygao.supabase.co';

  static const String supabaseAnonKey = _keyFromDefine != ''
      ? _keyFromDefine
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNncWVzcG10cHZvYWZpaW55Z2FvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI2MDI5MzcsImV4cCI6MjEwODE3ODkzN30.TAdJ_8sOAokyt0LZ82q-GAA9I1gkhgyJ3wxyc9vI1gc';
  // =============================================================

  /// Nama bucket storage untuk foto profil.
  static const String avatarBucket = 'avatars';

  /// True jika kredensial sudah diisi dengan benar.
  static bool get isSupabaseConfigured {
    final url = supabaseUrl.trim();
    final key = supabaseAnonKey.trim();
    if (url.isEmpty || key.isEmpty) return false;
    if (url.contains('YOUR-PROJECT')) return false;
    if (key.contains('YOUR_ANON_KEY')) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }

  /// True jika aplikasi berjalan tanpa backend (data lokal).
  static bool get isDemoMode => !isSupabaseConfigured;
}
