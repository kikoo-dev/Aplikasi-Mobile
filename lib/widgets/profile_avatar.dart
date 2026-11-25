import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../models/user_profile.dart';

/// Avatar bulat: foto jaringan / data-URI (mode demo) / bytes lokal / inisial.
///
/// Sengaja memakai [Uint8List] (bukan `dart:io File`) agar tetap
/// kompatibel dengan Android, iOS, dan Web.
class ProfileAvatar extends StatelessWidget {
  final UserProfile? profile;
  final double size;
  final Uint8List? localBytes;
  final VoidCallback? onTap;
  final bool showEditBadge;

  const ProfileAvatar({
    super.key,
    this.profile,
    this.size = 96,
    this.localBytes,
    this.onTap,
    this.showEditBadge = false,
  });

  ImageProvider? _image() {
    if (localBytes != null && localBytes!.isNotEmpty) {
      return MemoryImage(localBytes!);
    }

    final url = profile?.avatarUrl ?? '';
    if (url.isEmpty) return null;

    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(base64Decode(url.substring(comma + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isDark ? const Color(0xFF2A2350) : Colors.white;
    final image = _image();

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(color: ringColor, width: size * 0.045),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.32),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.09),
          ),
        ],
      ),
      child: ClipOval(
        child: image != null
            ? Image(
                image: image,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _initials(),
              )
            : _initials(),
      ),
    );

    final content = showEditBadge
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: size * 0.32,
                  height: size * 0.32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    border: Border.all(color: ringColor, width: 2.5),
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: size * 0.16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : avatar;

    if (onTap == null) return content;
    return GestureDetector(onTap: onTap, child: content);
  }

  Widget _initials() {
    return Center(
      child: Text(
        profile?.initials ?? '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
