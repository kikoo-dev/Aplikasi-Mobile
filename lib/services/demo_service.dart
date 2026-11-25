import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/user_profile.dart';

/// Implementasi [AuthService] tanpa backend.
///
/// Dipakai saat kredensial Supabase belum diisi, supaya aplikasi tetap bisa
/// dijalankan & dicoba. Data disimpan di SharedPreferences perangkat.
class DemoService implements AuthService {
  DemoService._();

  static final DemoService instance = DemoService._();

  static const String _kAccounts = 'demo_accounts';
  static const String _kSession = 'demo_session';
  static const String _kProfiles = 'demo_profiles';

  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  AppUser? _currentUser;

  @override
  bool get isRemote => false;

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Stream<AppUser?> get authStateChanges => _authController.stream;

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  /// Muat sesi tersimpan (dipanggil saat splash).
  Future<AppUser?> restoreSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kSession);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final user = AppUser(
        id: map['id'].toString(),
        email: map['email'].toString(),
      );
      _currentUser = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _accounts() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kAccounts);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _hash(String password) =>
      sha256.convert(utf8.encode('demo_salt_$password')).toString();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final accounts = await _accounts();
    final key = email.trim().toLowerCase();
    final account = accounts[key];

    if (account == null) {
      throw const AuthException('Akun tidak ditemukan. Silakan daftar dulu.');
    }
    if (account['password'] != _hash(password)) {
      throw const AuthException('Email atau password salah.');
    }

    final user = AppUser(id: account['id'].toString(), email: key);
    _currentUser = user;

    final prefs = await _prefs;
    await prefs.setString(
      _kSession,
      jsonEncode({'id': user.id, 'email': user.email}),
    );
    _authController.add(user);
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 750));
    final accounts = await _accounts();
    final key = email.trim().toLowerCase();

    if (accounts.containsKey(key)) {
      throw const AuthException('Email ini sudah terdaftar. Silakan login.');
    }

    final taken = accounts.values.any(
      (a) =>
          (a['username'] ?? '').toString().toLowerCase() ==
          username.trim().toLowerCase(),
    );
    if (taken) {
      throw const AuthException('Username sudah dipakai. Coba yang lain.');
    }

    final id = 'demo_${DateTime.now().millisecondsSinceEpoch}';
    accounts[key] = {
      'id': id,
      'password': _hash(password),
      'full_name': fullName.trim(),
      'username': username.trim(),
    };

    final prefs = await _prefs;
    await prefs.setString(_kAccounts, jsonEncode(accounts));

    // Buat profil awal.
    final profiles = await _profilesMap();
    profiles[id] = UserProfile(
      id: id,
      email: key,
      fullName: fullName.trim(),
      username: username.trim(),
    ).toMap();
    await prefs.setString(_kProfiles, jsonEncode(profiles));

    final user = AppUser(id: id, email: key);
    _currentUser = user;
    await prefs.setString(
      _kSession,
      jsonEncode({'id': user.id, 'email': user.email}),
    );
    _authController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await _prefs;
    await prefs.remove(_kSession);
    _authController.add(null);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final accounts = await _accounts();
    if (!accounts.containsKey(email.trim().toLowerCase())) {
      throw const AuthException('Email tidak terdaftar.');
    }
    // Mode demo tidak mengirim email; hanya simulasi sukses.
  }

  Future<Map<String, dynamic>> _profilesMap() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_kProfiles);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  @override
  Future<UserProfile?> fetchProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final user = _currentUser;
    if (user == null) return null;

    final profiles = await _profilesMap();
    final raw = profiles[user.id];
    if (raw is Map) {
      return UserProfile.fromMap(Map<String, dynamic>.from(raw));
    }
    return UserProfile(id: user.id, email: user.email);
  }

  @override
  Future<UserProfile> saveProfile(UserProfile profile) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final user = _currentUser;
    if (user == null) {
      throw const AuthException('Sesi berakhir. Silakan login ulang.');
    }

    final saved = profile.copyWith(
      id: user.id,
      email: user.email,
      updatedAt: DateTime.now(),
    );

    final prefs = await _prefs;
    final profiles = await _profilesMap();
    profiles[user.id] = saved.toMap();
    await prefs.setString(_kProfiles, jsonEncode(profiles));

    // Update nama di daftar akun agar konsisten.
    final accounts = await _accounts();
    final key = user.email.toLowerCase();
    if (accounts[key] != null) {
      accounts[key]['full_name'] = saved.fullName;
      accounts[key]['username'] = saved.username;
      await prefs.setString(_kAccounts, jsonEncode(accounts));
    }

    return saved;
  }

  @override
  Future<String> uploadAvatar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // Mode demo: simpan sebagai base64 data URI (cukup untuk pratinjau).
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpg';
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,${base64Encode(bytes)}';
  }
}
