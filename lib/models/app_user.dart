import 'dart:typed_data';

import 'user_profile.dart';

/// Model sederhana untuk state autentikasi.
class AppUser {
  final String id;
  final String email;

  const AppUser({required this.id, required this.email});
}

/// Service abstraksi autentikasi + profil.
///
/// Implementasi nyata: `SupabaseService` (services/supabase_service.dart)
/// Implementasi demo  : `DemoService`     (services/demo_service.dart)
abstract class AuthService {
  /// True jika memakai backend Supabase.
  bool get isRemote;

  /// Sesi yang sedang login (null jika belum).
  AppUser? get currentUser;

  /// Stream perubahan status login.
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  });

  Future<void> signOut();

  Future<void> sendPasswordReset(String email);

  Future<UserProfile?> fetchProfile();

  Future<UserProfile> saveProfile(UserProfile profile);

  /// Upload foto profil, mengembalikan URL publik.
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  });
}

/// Exception dengan pesan ramah pengguna.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}
