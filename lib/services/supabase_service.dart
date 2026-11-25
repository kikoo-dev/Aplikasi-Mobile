import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/env.dart';
import '../models/app_user.dart';
import '../models/user_profile.dart';

/// Implementasi [AuthService] memakai Supabase (Auth + tabel `profiles` + Storage).
class SupabaseService implements AuthService {
  SupabaseService(this._client);

  final sb.SupabaseClient _client;

  static const String _table = 'profiles';

  @override
  bool get isRemote => true;

  @override
  AppUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return AppUser(id: user.id, email: user.email ?? '');
  }

  @override
  Stream<AppUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      if (user == null) return null;
      return AppUser(id: user.id, email: user.email ?? '');
    });
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = res.user;
      if (user == null) {
        throw const AuthException('Gagal masuk. Silakan coba lagi.');
      }
      return AppUser(id: user.id, email: user.email ?? email.trim());
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    } catch (e) {
      throw AuthException('Terjadi kesalahan: $e');
    }
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'username': username.trim(),
        },
      );

      final user = res.user;
      if (user == null) {
        throw const AuthException('Pendaftaran gagal. Coba email lain.');
      }

      // Jika project Supabase mengaktifkan "Confirm email", session == null.
      // Beri tahu pengguna agar tidak masuk ke halaman dengan sesi kosong.
      if (res.session == null) {
        throw const AuthException(
          'Akun dibuat, tetapi email belum dikonfirmasi. Silakan cek kotak '
          'masuk email kamu untuk verifikasi, lalu login.\n\n'
          '(Tips: matikan "Confirm email" di Supabase → Authentication → '
          'Providers → Email saat masa pengembangan.)',
        );
      }

      await _ensureProfileRow(
        userId: user.id,
        email: email.trim(),
        fullName: fullName.trim(),
        username: username.trim(),
      );

      return AppUser(id: user.id, email: user.email ?? email.trim());
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    } catch (e) {
      throw AuthException('Terjadi kesalahan: $e');
    }
  }

  Future<void> _ensureProfileRow({
    required String userId,
    required String email,
    required String fullName,
    required String username,
  }) async {
    try {
      final existing =
          await _client.from(_table).select('id').eq('id', userId).maybeSingle();
      if (existing != null) return;

      await _client.from(_table).insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'username': username,
      });
    } catch (_) {
      // Diabaikan: RLS / konfirmasi email. Baris akan dibuat saat fetchProfile.
    }
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sb.AuthException catch (e) {
      throw AuthException(_translate(e));
    }
  }

  @override
  Future<UserProfile?> fetchProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    try {
      final row =
          await _client.from(_table).select().eq('id', user.id).maybeSingle();

      if (row == null) {
        // Buat baris profil otomatis dari metadata auth.
        final meta = user.userMetadata ?? {};
        final profile = UserProfile(
          id: user.id,
          email: user.email ?? '',
          fullName: (meta['full_name'] ?? '').toString(),
          username: (meta['username'] ?? '').toString(),
        );
        try {
          await _client.from(_table).insert(profile.toInsertMap());
        } catch (_) {
          // Jika insert gagal, tetap kembalikan profil sementara.
        }
        return profile;
      }

      return UserProfile.fromMap(Map<String, dynamic>.from(row));
    } catch (e) {
      throw AuthException(
        'Gagal memuat profil. Pastikan tabel "profiles" sudah dibuat '
        '(lihat supabase/schema.sql).\n\n$e',
      );
    }
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi berakhir. Silakan login ulang.');
    }

    final data = profile.toMap()..['id'] = user.id;

    try {
      final row = await _client
          .from(_table)
          .upsert(data, onConflict: 'id')
          .select()
          .single();
      return UserProfile.fromMap(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e) {
      throw AuthException('Gagal menyimpan profil: ${e.message}');
    } catch (e) {
      throw AuthException('Gagal menyimpan profil: $e');
    }
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Sesi berakhir. Silakan login ulang.');
    }

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final path = '${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';

    try {
      await _client.storage.from(Env.avatarBucket).uploadBinary(
            path,
            bytes,
            fileOptions: const sb.FileOptions(upsert: true),
          );

      final publicUrl =
          _client.storage.from(Env.avatarBucket).getPublicUrl(path);

      // Simpan juga ke kolom avatar_url.
      await _client
          .from(_table)
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      return publicUrl;
    } on sb.StorageException catch (e) {
      throw AuthException(
        'Gagal upload foto: ${e.message}. Pastikan bucket "${Env.avatarBucket}" '
        'sudah dibuat dan bersifat public.',
      );
    } catch (e) {
      throw AuthException('Gagal upload foto: $e');
    }
  }

  String _translate(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek kotak masuk email kamu.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Email ini sudah terdaftar. Silakan login.';
    }
    if (msg.contains('password should be at least')) {
      return 'Password terlalu lemah (minimal 6 karakter).';
    }
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email')) {
      return 'Format email tidak valid.';
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
    }
    if (msg.contains('network') || msg.contains('socket')) {
      return 'Tidak ada koneksi internet.';
    }
    return e.message;
  }
}
