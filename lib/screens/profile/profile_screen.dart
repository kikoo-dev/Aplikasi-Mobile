import 'package:flutter/material.dart';


import '../../core/app_scope.dart';
import '../../core/format.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_profile.dart';
import '../../widgets/common.dart';
import '../../widgets/itenas_logo.dart';
import '../../widgets/profile_avatar.dart';
import '../auth/login_screen.dart';
import '../calculator/calculator_screen.dart';
import 'edit_profile_screen.dart';
import 'social_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = AppScope.of(context);
    final profile = controller.profile ?? UserProfile.empty;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshProfile,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
              children: [
                PageHeader(
                  title: 'Profil Saya',
                  subtitle: 'Informasi akun & biodata',
                  trailing: IconButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    icon: Icon(
                      Icons.edit_rounded,
                      size: 18,
                      color: isDark ? Colors.white : const Color(0xFF1B1436),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ---------- Kartu header profil ----------
                GlassCard(
                  gradient: AppColors.primaryGradient,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                  padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                  child: Column(
                    children: [
                      ProfileAvatar(profile: profile, size: 92),
                      const SizedBox(height: 16),
                      Text(
                        profile.displayName.isEmpty
                            ? 'Tanpa Nama'
                            : profile.displayName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        profile.username.isEmpty
                            ? 'Belum ada username'
                            : '@${profile.username}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (profile.bio.trim().isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            profile.bio,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12.5,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _HeaderButton(
                              icon: Icons.edit_rounded,
                              label: 'Edit Profil',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _HeaderButton(
                              icon: Icons.calculate_rounded,
                              label: 'Kalkulator',
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const CalculatorScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ---------- About me ----------
                _Section(
                  icon: Icons.info_outline_rounded,
                  title: 'About Me',
                  child: profile.aboutMe.trim().isEmpty
                      ? const _EmptyHint(
                          text:
                              'Belum ada deskripsi. Ceritakan tentang dirimu di Edit Profil.',
                        )
                      : Text(
                          profile.aboutMe,
                          style: TextStyle(
                            fontSize: 13.2,
                            height: 1.6,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.86)
                                : const Color(0xFF3B3459),
                          ),
                        ),
                ),
                const SizedBox(height: 14),

                // ---------- Biodata ----------
                _Section(
                  icon: Icons.badge_outlined,
                  title: 'Biodata',
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: profile.email,
                      ),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'No. Telepon',
                        value: profile.phone,
                      ),
                      _InfoRow(
                        icon: Icons.cake_outlined,
                        label: 'Tanggal Lahir',
                        value: profile.birthDate == null
                            ? ''
                            : formatTanggal(profile.birthDate!),
                      ),
                      _InfoRow(
                        icon: Icons.wc_rounded,
                        label: 'Jenis Kelamin',
                        value: profile.gender,
                      ),
                      _InfoRow(
                        icon: Icons.work_outline_rounded,
                        label: 'Pekerjaan',
                        value: profile.occupation,
                      ),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Alamat',
                        value: profile.address,
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // ---------- Sosial media ----------
                _Section(
                  icon: Icons.share_outlined,
                  title: 'Sosial Media',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      SocialChip(
                        label: 'Instagram',
                        icon: Icons.camera_alt_rounded,
                        value: profile.instagram,
                        gradient: AppColors.instagramGradient,
                      ),
                      SocialChip(
                        label: 'Facebook',
                        icon: Icons.facebook_rounded,
                        value: profile.facebook,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1877F2), Color(0xFF0F5FD1)],
                        ),
                      ),
                      SocialChip(
                        label: 'TikTok',
                        icon: Icons.music_note_rounded,
                        value: profile.tiktok,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1F1F1F), Color(0xFF000000)],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ---------- Logout ----------
                const Center(child: ItenasBrand(compact: true)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Keluar dari Akun'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    foregroundColor: AppColors.accent,
                    side: BorderSide(
                      color: AppColors.accent.withValues(alpha: 0.4),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Keluar Akun?'),
        content: const Text('Kamu bisa masuk kembali kapan saja.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              minimumSize: const Size(0, 42),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await AppScope.read(context).logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1B1436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final empty = value.trim().isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark ? Colors.white38 : const Color(0xFFA9A3C2),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  empty ? 'Belum diisi' : value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontStyle: empty ? FontStyle.italic : FontStyle.normal,
                    color: empty
                        ? (isDark ? Colors.white30 : const Color(0xFFB9B3CC))
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF2C2547)),
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

class _EmptyHint extends StatelessWidget {
  final String text;

  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.8,
        height: 1.55,
        fontStyle: FontStyle.italic,
        color: isDark ? Colors.white38 : const Color(0xFFA9A3C2),
      ),
    );
  }
}
