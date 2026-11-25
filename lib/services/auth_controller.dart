import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/app_user.dart';
import '../models/user_profile.dart';
import 'demo_service.dart';
import 'supabase_service.dart';

/// Menyimpan state global aplikasi (sesi login + profil).
class AuthController extends ChangeNotifier {
  AuthController({required this.service});

  final AuthService service;

  AppUser? _user;
  UserProfile? _profile;
  bool _booting = true;
  bool _busy = false;

  AppUser? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoggedIn => _user != null;
  bool get booting => _booting;
  bool get busy => _busy;
  bool get isDemo => !service.isRemote;

  /// Dipanggil sekali saat splash.
  Future<void> bootstrap() async {
    try {
      if (service is DemoService) {
        await (service as DemoService).restoreSession();
      }
      _user = service.currentUser;
      if (_user != null) {
        _profile = await service.fetchProfile();
      }
    } catch (_) {
      // Biarkan null; user bisa login ulang.
    } finally {
      _booting = false;
      // Tunda notifikasi ke frame berikutnya agar tidak memicu
      // "setState() called during build" saat dipanggil dari splash.
      _notifySafely();
    }
  }

  /// notifyListeners yang aman dipanggil kapan saja (termasuk saat build).
  void _notifySafely() {
    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      if (!_disposed) notifyListeners();
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> login({required String email, required String password}) async {
    _setBusy(true);
    try {
      _user = await service.signIn(email: email, password: password);
      _profile = await service.fetchProfile();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    _setBusy(true);
    try {
      _user = await service.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
      );
      _profile = await service.fetchProfile();
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await service.signOut();
      _user = null;
      _profile = null;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> refreshProfile() async {
    if (_user == null) return;
    try {
      _profile = await service.fetchProfile();
      notifyListeners();
    } catch (_) {
      // diamkan; halaman akan menampilkan data lama
    }
  }

  Future<void> saveProfile(UserProfile profile) async {
    _setBusy(true);
    try {
      _profile = await service.saveProfile(profile);
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    _setBusy(true);
    try {
      final url = await service.uploadAvatar(bytes: bytes, fileName: fileName);
      _profile = _profile?.copyWith(avatarUrl: url);
      notifyListeners();
      return url;
    } finally {
      _setBusy(false);
    }
  }

  Future<void> resetPassword(String email) =>
      service.sendPasswordReset(email);

  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }
}

/// Factory: pilih service sesuai konfigurasi.
AuthService createAuthService({required bool useSupabase}) {
  if (useSupabase) {
    return SupabaseService(sb.Supabase.instance.client);
  }
  return DemoService.instance;
}
