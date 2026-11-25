import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme/app_theme.dart';
import '../models/feed_post.dart';
import '../models/user_profile.dart';
import 'profile_avatar.dart';

/// Gambar postingan: mendukung URL jaringan maupun data-URI (mode demo).
class PostImage extends StatelessWidget {
  final String url;
  final double? height;
  final BoxFit fit;

  const PostImage({
    super.key,
    required this.url,
    this.height,
    this.fit = BoxFit.cover,
  });

  ImageProvider? _provider() {
    if (url.isEmpty) return null;
    if (url.startsWith('data:image')) {
      final comma = url.indexOf(',');
      if (comma < 0) return null;
      try {
        return MemoryImage(Uint8List.fromList(base64Decode(url.substring(comma + 1))));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(url);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = _provider();

    if (provider == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : AppColors.orangeSoft,
        constraints: height != null ? BoxConstraints.tightFor(height: height) : null,
        width: double.infinity,
        child: Image(
          image: provider,
          fit: fit,
          width: double.infinity,
          height: height,
          errorBuilder: (_, _, _) => _placeholder(context),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _placeholder(context, showSpinner: true);
          },
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context, {bool showSpinner = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: height ?? 200,
      child: Center(
        child: showSpinner
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : Icon(
                Icons.image_outlined,
                size: 34,
                color: isDark ? Colors.white24 : AppColors.inkMuted,
              ),
      ),
    );
  }
}

/// Kartu postingan bergaya LinkedIn.
class FeedPostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  final VoidCallback? onAuthorTap;
  final VoidCallback? onImageTap;

  /// True jika postingan ini milik pengguna yang sedang login.
  final bool isMine;

  /// Dipanggil saat pengguna memilih "Hapus postingan".
  final VoidCallback? onDelete;

  const FeedPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onAuthorTap,
    this.onImageTap,
    this.isMine = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------- Header: avatar + nama + waktu ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: onAuthorTap,
                  child: ProfileAvatar(
                    profile: _authorProfile(),
                    size: 44,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: GestureDetector(
                    onTap: onAuthorTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                post.authorName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color:
                                      isDark ? Colors.white : AppColors.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          post.authorHeadline.isEmpty
                              ? '@${post.authorUsername}'
                              : post.authorHeadline,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isDark ? Colors.white54 : AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            Text(
                              waktuRelatif(post.createdAt),
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark
                                    ? Colors.white38
                                    : AppColors.inkMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.public_rounded,
                              size: 10.5,
                              color: isDark
                                  ? Colors.white38
                                  : AppColors.inkMuted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _showPostMenu(context),
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: isDark ? Colors.white54 : AppColors.inkMuted,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // ---------- Teks ----------
          if (post.content.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : AppColors.ink,
                ),
              ),
            ),

          // ---------- Gambar ----------
          if (post.imageUrl.trim().isNotEmpty)
            GestureDetector(
              onTap: onImageTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: PostImage(url: post.imageUrl),
              ),
            ),

          // ---------- Statistik ----------
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                if (post.likeCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.thumb_up_alt_rounded,
                      size: 8,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    angkaRingkas(post.likeCount),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white54 : AppColors.inkSoft,
                    ),
                  ),
                ],
                const Spacer(),
                if (post.commentCount > 0)
                  Text(
                    '${angkaRingkas(post.commentCount)} komentar',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : AppColors.inkSoft,
                    ),
                  ),
              ],
            ),
          ),

          Divider(
            height: 1,
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),

          // ---------- Tombol aksi ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: post.liked
                        ? Icons.thumb_up_alt_rounded
                        : Icons.thumb_up_alt_outlined,
                    label: 'Suka',
                    active: post.liked,
                    onTap: onLike,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.mode_comment_outlined,
                    label: 'Komentar',
                    onTap: onComment,
                  ),
                ),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.share_outlined,
                    label: 'Bagikan',
                    onTap: onShare,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  UserProfile _authorProfile() => UserProfile(
        id: post.authorId,
        email: '',
        fullName: post.authorName,
        avatarUrl: post.authorAvatar,
      );

  void _showPostMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.bookmark_border_rounded),
                title: const Text('Simpan postingan'),
                onTap: () => Navigator.pop(ctx),
              ),
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('Salin tautan'),
                onTap: () => Navigator.pop(ctx),
              ),
              if (isMine && onDelete != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFD93025),
                  ),
                  title: const Text(
                    'Hapus postingan',
                    style: TextStyle(
                      color: Color(0xFFD93025),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    onDelete!();
                  },
                ),
              if (!isMine)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Laporkan'),
                  onTap: () => Navigator.pop(ctx),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool active;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = active
        ? AppColors.primary
        : (isDark ? Colors.white60 : AppColors.inkSoft);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

