import 'package:characters/characters.dart';

/// Model data profil pengguna.
///
/// Dipakai untuk Supabase (tabel `profiles`) maupun mode demo (lokal).
class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String username;
  final String phone;
  final String bio;
  final String aboutMe;
  final String address;
  final String occupation;
  final DateTime? birthDate;
  final String gender;
  final String avatarUrl;
  final String instagram;
  final String facebook;
  final String tiktok;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName = '',
    this.username = '',
    this.phone = '',
    this.bio = '',
    this.aboutMe = '',
    this.address = '',
    this.occupation = '',
    this.birthDate,
    this.gender = '',
    this.avatarUrl = '',
    this.instagram = '',
    this.facebook = '',
    this.tiktok = '',
    this.updatedAt,
  });

  static const UserProfile empty = UserProfile(id: '', email: '');

  bool get isComplete =>
      fullName.trim().isNotEmpty && username.trim().isNotEmpty;

  String get displayName =>
      fullName.trim().isNotEmpty ? fullName.trim() : username.trim();

  String get initials {
    final name = displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts[1].characters.first)
        .toUpperCase();
  }

  int get profileCompletion {
    final fields = <String>[
      fullName,
      username,
      phone,
      bio,
      aboutMe,
      address,
      occupation,
      gender,
      avatarUrl,
      instagram,
      facebook,
      tiktok,
    ];
    final filled = fields.where((f) => f.trim().isNotEmpty).length;
    final hasBirth = birthDate != null ? 1 : 0;
    return (((filled + hasBirth) / (fields.length + 1)) * 100).round();
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? username,
    String? phone,
    String? bio,
    String? aboutMe,
    String? address,
    String? occupation,
    DateTime? birthDate,
    bool clearBirthDate = false,
    String? gender,
    String? avatarUrl,
    String? instagram,
    String? facebook,
    String? tiktok,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      aboutMe: aboutMe ?? this.aboutMe,
      address: address ?? this.address,
      occupation: occupation ?? this.occupation,
      birthDate: clearBirthDate ? null : (birthDate ?? this.birthDate),
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      tiktok: tiktok ?? this.tiktok,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      fullName: (map['full_name'] ?? '').toString(),
      username: (map['username'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
      aboutMe: (map['about_me'] ?? '').toString(),
      address: (map['address'] ?? '').toString(),
      occupation: (map['occupation'] ?? '').toString(),
      birthDate: map['birth_date'] != null
          ? DateTime.tryParse(map['birth_date'].toString())
          : null,
      gender: (map['gender'] ?? '').toString(),
      avatarUrl: (map['avatar_url'] ?? '').toString(),
      instagram: (map['instagram'] ?? '').toString(),
      facebook: (map['facebook'] ?? '').toString(),
      tiktok: (map['tiktok'] ?? '').toString(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'username': username,
      'phone': phone,
      'bio': bio,
      'about_me': aboutMe,
      'address': address,
      'occupation': occupation,
      'birth_date': birthDate?.toIso8601String().split('T').first,
      'gender': gender,
      'avatar_url': avatarUrl,
      'instagram': instagram,
      'facebook': facebook,
      'tiktok': tiktok,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Map untuk insert awal (tanpa updated_at opsional).
  Map<String, dynamic> toInsertMap() => toMap();
}
