
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_scope.dart';
import '../../core/env.dart';
import '../../core/theme/app_theme.dart';
import '../../models/feed_post.dart';
import '../../models/user_profile.dart';
import '../../services/feed_service.dart';
import 'comments_screen.dart';
import '../../widgets/feed_post_card.dart';
import '../../widgets/itenas_logo.dart';
import '../../widgets/media_button.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/login_screen.dart';
import '../calculator/calculator_screen.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';

/// Beranda bergaya LinkedIn: feed postingan + foto pengguna lain,
/// scroll vertikal.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final FeedService _feed;
  late final ScrollController _scroll;

  final List<FeedPost> _posts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _feed = createFeedService(useSupabase: Env.isSupabaseConfigured);
    _scroll = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppScope.read(context).refreshProfile();
    });
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await _feed.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts
          ..clear()
          ..addAll(posts);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() => _load();

  Future<void> _toggleLike(FeedPost post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;

    // Optimistic update.
    final current = _posts[index];
    final optimistic = current.copyWith(
      liked: !current.liked,
      likeCount: current.likeCount + (current.liked ? -1 : 1),
    );
    setState(() => _posts[index] = optimistic);

    try {
      final liked = await _feed.toggleLike(current);
      if (!mounted) return;
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i < 0) return;
      setState(() {
        _posts[i] = _posts[i].copyWith(liked: liked);
      });
    } catch (e) {
      if (!mounted) return;
      // Rollback.
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i >= 0) setState(() => _posts[i] = current);
      _snack('Gagal menyukai postingan: $e', isError: true);
    }
  }

  Future<void> _openComposer() async {
    final created = await showModalBottomSheet<FeedPost>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ComposerSheet(feed: _feed),
    );

    if (created != null && mounted) {
      setState(() {
        _posts.insert(0, created);
      });
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
      _snack('Postingan berhasil dibagikan');
    }
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? const Color(0xFFD93025) : AppColors.ink,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context);
    final profile = controller.profile ?? UserProfile.empty;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : const Color(0xFFF7F3EF),
      floatingActionButton: FloatingActionButton(
        onPressed: _openComposer,
        backgroundColor: AppColors.primary,
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scroll,
          slivers: [
            // ============ APP BAR ============
            SliverAppBar(
              pinned: true,
              floating: true,
              elevation: 0,
              scrolledUnderElevation: 1,
              backgroundColor: isDark ? AppColors.cardDark : Colors.white,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 16,
              title: Row(
                children: [
                  const ItenasLogo(size: 30, showShadow: false),
                  const SizedBox(width: 9),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ITENAS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                      Text(
                        'Jejaring Mahasiswa',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white38 : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorScreen(),
                    ),
                  ),
                  icon: Icon(
                    Icons.calculate_outlined,
                    size: 21,
                    color: isDark ? Colors.white70 : AppColors.inkSoft,
                  ),
                  tooltip: 'Kalkulator',
                ),
                IconButton(
                  onPressed: () => _confirmLogout(context),
                  icon: Icon(
                    Icons.logout_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : AppColors.inkSoft,
                  ),
                  tooltip: 'Keluar',
                ),
                const SizedBox(width: 4),
              ],
            ),

            // ============ KARTU PROFIL RINGKAS ============
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: _MiniProfileCard(
                  profile: profile,
                  onProfileTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  onEdit: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                ),
              ),
            ),

            // ============ SHORTCUT BAR ============
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                child: _ShortcutBar(
                  onCalculator: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CalculatorScreen(),
                    ),
                  ),
                  onEditProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  ),
                  onMyProfile: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                ),
              ),
            ),

            // ============ PEMISAH "FEED" ============
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      'Feed Kampus',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '${_posts.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _refresh,
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: isDark
                                ? Colors.white54
                                : AppColors.inkMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Muat ulang',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white54
                                  : AppColors.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ============ DAFTAR POSTINGAN ============
            if (_loading)
              const SliverToBoxAdapter(child: _FeedSkeleton())
            else if (_error != null)
              SliverToBoxAdapter(
                child: _ErrorState(
                  message: _error!,
                  onRetry: _load,
                ),
              )
            else if (_posts.isEmpty)
              const SliverToBoxAdapter(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                sliver: SliverList.builder(
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    final myId = AppScope.of(context).user?.id ?? '';
                    final isMine = myId.isNotEmpty &&
                        post.authorId == myId;
                    return FeedPostCard(
                      post: post,
                      isMine: isMine,
                      onDelete: isMine ? () => _deletePost(post) : null,
                      onLike: () => _toggleLike(post),
                      onComment: () => _openComments(context, post),
                      onShare: () => _sharePost(post),
                      onAuthorTap: () => _showAuthorSheet(context, post),
                      onImageTap: () => _openImage(context, post),
                    );
                  },
                ),
              ),

            // ============ FOOTER ============
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Center(
                  child: Column(
                    children: [
                      const ItenasBrand(compact: true),
                      const SizedBox(height: 8),
                      Text(
                        _feed.isRemote
                            ? 'Terhubung ke Supabase'
                            : 'Mode demo • data lokal',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark ? Colors.white30 : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthorSheet(BuildContext context, FeedPost post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
            const SizedBox(height: 20),
            ProfileAvatar(
              profile: UserProfile(
                id: post.authorId,
                email: '',
                fullName: post.authorName,
                avatarUrl: post.authorAvatar,
              ),
              size: 72,
            ),
            const SizedBox(height: 12),
            Text(
              post.authorName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              post.authorHeadline.isEmpty
                  ? '@${post.authorUsername}'
                  : post.authorHeadline,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : AppColors.inkMuted,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 17),
                label: const Text('Ikuti'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openImage(BuildContext context, FeedPost post) {
    if (post.imageUrl.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => _ImageViewer(
          url: post.imageUrl,
          caption: post.content,
          author: post.authorName,
        ),
      ),
    );
  }

  /// Buka halaman komentar lalu sinkronkan jumlah komentar di feed.
  Future<void> _openComments(BuildContext context, FeedPost post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CommentsScreen(post: post, feed: _feed),
      ),
    );
    if (!mounted) return;
    // Muat ulang agar comment_count terbaru tampil.
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    try {
      final items = await _feed.fetchComments(post.id);
      if (!mounted) return;
      final i = _posts.indexWhere((p) => p.id == post.id);
      if (i < 0) return;
      setState(() {
        _posts[i] = _posts[i].copyWith(commentCount: items.length);
      });
    } catch (_) {}
  }

  /// Bagikan postingan (salin teks + info ke clipboard).
  Future<void> _sharePost(FeedPost post) async {
    final text = [
      if (post.content.trim().isNotEmpty) post.content,
      '— ${post.authorName}',
      '',
      'Dibagikan dari ProfilKita ITENAS',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    _snack('Postingan disalin ke clipboard');
  }

  /// Hapus postingan dengan konfirmasi.
  Future<void> _deletePost(FeedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Hapus Postingan?'),
        content: const Text(
          'Postingan ini akan dihapus permanen, termasuk foto dan '
          'komentarnya. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD93025),
              minimumSize: const Size(0, 42),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Optimistic: hapus dari daftar dulu.
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index < 0) return;
    final removed = _posts[index];
    setState(() => _posts.removeAt(index));

    try {
      await _feed.deletePost(post.id);
      if (!mounted) return;
      _snack('Postingan dihapus');
    } catch (e) {
      if (!mounted) return;
      // Rollback bila gagal.
      setState(() => _posts.insert(index, removed));
      _snack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Keluar Akun?'),
        content: const Text('Kamu perlu login kembali untuk mengakses feed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 42),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      await AppScope.read(context).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

// ============================================================
// KARTU PROFIL RINGKAS
// ============================================================
class _MiniProfileCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback onProfileTap;
  final VoidCallback onEdit;

  const _MiniProfileCard({
    required this.profile,
    required this.onProfileTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final completion = profile.profileCompletion;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Banner oranye
          Container(
            height: 62,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -30,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: onProfileTap,
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.cardDark : Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: ProfileAvatar(profile: profile, size: 58),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_rounded, size: 14),
                        label: const Text(
                          'Edit Profil',
                          style: TextStyle(fontSize: 11.5),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          minimumSize: const Size(0, 34),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              profile.displayName.isEmpty
                                  ? 'Pengguna ITENAS'
                                  : profile.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? Colors.white : AppColors.ink,
                              ),
                            ),
                          ),
                          Text(
                            '$completion%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile.occupation.isEmpty
                            ? (profile.username.isEmpty
                                ? 'Lengkapi profilmu'
                                : '@${profile.username}')
                            : profile.occupation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : AppColors.inkMuted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: completion / 100,
                          minHeight: 5,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.orangeSoft,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SHORTCUT BAR
// ============================================================
class _ShortcutBar extends StatelessWidget {
  final VoidCallback onCalculator;
  final VoidCallback onEditProfile;
  final VoidCallback onMyProfile;

  const _ShortcutBar({
    required this.onCalculator,
    required this.onEditProfile,
    required this.onMyProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.lineDark : AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ShortcutItem(
              icon: Icons.calculate_rounded,
              label: 'Kalkulator',
              onTap: onCalculator,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _ShortcutItem(
              icon: Icons.edit_note_rounded,
              label: 'Edit Profil',
              onTap: onEditProfile,
            ),
          ),
          _divider(isDark),
          Expanded(
            child: _ShortcutItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil Saya',
              onTap: onMyProfile,
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 26,
        color: isDark ? AppColors.lineDark : AppColors.line,
      );
}

class _ShortcutItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShortcutItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white70 : AppColors.inkSoft,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPOSER (BUAT POSTINGAN)
// ============================================================
class _ComposerSheet extends StatefulWidget {
  final FeedService feed;

  const _ComposerSheet({required this.feed});

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  final _ctrl = TextEditingController();
  bool _posting = false;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _uploading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage({bool fromCamera = false}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 1400,
        maxHeight: 1400,
        imageQuality: 82,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        if (!mounted) return;
        _toast('Ukuran foto terlalu besar (maks 5 MB)', isError: true);
        return;
      }
      setState(() {
        _imageBytes = bytes;
        _imageName = picked.name.isEmpty ? 'foto.jpg' : picked.name;
      });
    } catch (e) {
      if (!mounted) return;
      _toast('Gagal memilih foto: $e', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
              isError ? const Color(0xFFD93025) : AppColors.ink,
        ),
      );
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _imageBytes == null) return;

    setState(() => _posting = true);
    try {
      // Upload foto terlebih dahulu (bila ada).
      var imageUrl = '';
      if (_imageBytes != null) {
        setState(() => _uploading = true);
        imageUrl = await widget.feed.uploadPostImage(
          bytes: _imageBytes!,
          fileName: _imageName ?? 'foto.jpg',
        );
        setState(() => _uploading = false);
      }

      final post = await widget.feed.createPost(
        content: text,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      Navigator.pop(context, post);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _posting = false;
        _uploading = false;
      });
      _toast(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = AppScope.of(context).profile ?? UserProfile.empty;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                ProfileAvatar(profile: profile, size: 42),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName.isEmpty
                            ? 'Pengguna ITENAS'
                            : profile.displayName,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.ink,
                        ),
                      ),
                      Text(
                        'Bagikan ke Jejaring Mahasiswa',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white38 : AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              maxLines: 6,
              minLines: 3,
              autofocus: true,
              maxLength: 800,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white : AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'Apa yang ingin kamu bagikan hari ini?',
                counterText: '',
                fillColor:
                    isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.orangeSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            // ---------- Preview foto terpilih ----------
            if (_imageBytes != null) ...[
              const SizedBox(height: 12),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _imageBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _posting
                            ? null
                            : () => setState(() {
                                  _imageBytes = null;
                                  _imageName = null;
                                }),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // ---------- Aksi: tambah foto ----------
            Row(
              children: [
                MediaButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  enabled: !_posting,
                  onTap: () => _pickImage(),
                ),
                const SizedBox(width: 8),
                MediaButton(
                  icon: Icons.photo_camera_rounded,
                  label: 'Kamera',
                  enabled: !_posting,
                  onTap: () => _pickImage(fromCamera: true),
                ),
                const Spacer(),
                Text(
                  '${_ctrl.text.length}/800',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : AppColors.inkMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _posting ||
                        (_ctrl.text.trim().isEmpty && _imageBytes == null)
                    ? null
                    : _submit,
                icon: _posting
                    ? const SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send_rounded, size: 16),
                label: Text(
                  _uploading
                      ? 'Mengunggah foto...'
                      : (_posting ? 'Mengirim...' : 'Bagikan'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SKELETON / ERROR / EMPTY
// ============================================================
class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
      child: Column(
        children: List.generate(3, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.lineDark : AppColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _bar(44, 44, radius: 22, isDark: isDark),
                    const SizedBox(width: 11),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _bar(120, 12, isDark: isDark),
                        const SizedBox(height: 6),
                        _bar(80, 9, isDark: isDark),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _bar(double.infinity, 10, isDark: isDark),
                const SizedBox(height: 6),
                _bar(220, 10, isDark: isDark),
                const SizedBox(height: 14),
                _bar(double.infinity, 150, isDark: isDark, radius: 14),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _bar(
    double width,
    double height, {
    bool isDark = false,
    double radius = 6,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
      child: Column(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: isDark ? Colors.white24 : AppColors.inkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'Gagal memuat feed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.5,
              color: isDark ? Colors.white38 : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Coba Lagi'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 80),
      child: Column(
        children: [
          Icon(
            Icons.dynamic_feed_outlined,
            size: 46,
            color: isDark ? Colors.white24 : AppColors.inkMuted,
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada postingan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jadilah yang pertama membagikan sesuatu!',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white38 : AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// IMAGE VIEWER
// ============================================================
class _ImageViewer extends StatelessWidget {
  final String url;
  final String caption;
  final String author;

  const _ImageViewer({
    required this.url,
    required this.caption,
    required this.author,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          author,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: PostImage(url: url, fit: BoxFit.contain),
              ),
            ),
          ),
          if (caption.trim().isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12.5,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
