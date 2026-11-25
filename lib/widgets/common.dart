import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Background gradient lembut yang dipakai di semua halaman.
class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool withBlobs;

  const GradientBackground({
    super.key,
    required this.child,
    this.withBlobs = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDark ? AppColors.softGradientDark : AppColors.softGradient,
      ),
      child: withBlobs
          ? Stack(
              children: [
                Positioned(
                  top: -90,
                  right: -70,
                  child: _Blob(
                    size: 240,
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.22),
                      AppColors.secondary.withValues(alpha: 0.05),
                    ],
                  ),
                ),
                Positioned(
                  bottom: -110,
                  left: -80,
                  child: _Blob(
                    size: 280,
                    colors: [
                      AppColors.accent.withValues(alpha: isDark ? 0.22 : 0.14),
                      AppColors.mint.withValues(alpha: 0.04),
                    ],
                  ),
                ),
                child,
              ],
            )
          : child,
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _Blob({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

/// Kartu putih semi transparan dengan border halus.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Gradient? gradient;
  final BoxBorder? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 24,
    this.color,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.cardDark : Colors.white);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? bg.withValues(alpha: isDark ? 0.92 : 0.86) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.9),
            ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.07),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Logo aplikasi (gradient rounded square + ikon).
class AppLogo extends StatelessWidget {
  final double size;
  final bool showShadow;

  const AppLogo({super.key, this.size = 72, this.showShadow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.42),
                  blurRadius: size * 0.42,
                  offset: Offset(0, size * 0.16),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: size * 0.48,
        ),
      ),
    );
  }
}

/// Tombol utama dengan gradient.
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || loading;

    return Opacity(
      opacity: disabled && !loading ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: disabled ? null : onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.38),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 19),
                          const SizedBox(width: 9),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header halaman dengan tombol back opsional.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1B1436);

    return Row(
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: IconButton.styleFrom(
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
              icon: Icon(Icons.arrow_back_rounded, color: textColor, size: 20),
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  color: textColor,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF8B84AC),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Field input dengan label di atas.
class LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool required;

  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : const Color(0xFF5B5478),
                ),
              ),
              if (required)
                const Text(
                  ' *',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accent,
                  ),
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

/// Badge kecil (dipakai di beberapa tempat).
class SoftBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;

  const SoftBadge({
    super.key,
    required this.text,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Menampilkan snackbar dengan gaya aplikasi.
void showAppSnack(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_outline,
              color: isError ? const Color(0xFFFF8A8A) : const Color(0xFF7CFFC4),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
