import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

/// Logo Institut Teknologi Nasional Bandung.
///
/// Digambar dengan widget (bukan aset gambar) agar selalu tajam di segala
/// resolusi. Menampilkan perisai + pita dengan inisial "ITN".
class ItenasLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final bool onDarkBackground;

  const ItenasLogo({
    super.key,
    this.size = 72,
    this.showShadow = true,
    this.onDarkBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.26),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: size * 0.3,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Perisai
            Container(
              width: size * 0.52,
              height: size * 0.52,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                  bottomLeft: Radius.circular(22),
                  bottomRight: Radius.circular(22),
                ),
              ),
              child: Center(
                child: Text(
                  'ITN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: size * 0.045),
            // Pita nama
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: size * 0.055,
                vertical: size * 0.02,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'ITENAS',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: size * 0.085,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Logo versi kecil + teks nama kampus untuk header.
class ItenasBrand extends StatelessWidget {
  final bool compact;
  final bool light; // true = teks putih (di atas background oranye)

  const ItenasBrand({super.key, this.compact = false, this.light = false});

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : AppColors.ink;
    final subColor = light
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.inkMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ItenasLogo(size: compact ? 34 : 42, showShadow: false),
        SizedBox(width: compact ? 9 : 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ITENAS',
              style: TextStyle(
                fontSize: compact ? 13 : 14.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: textColor,
              ),
            ),
            Text(
              'Institut Teknologi\nNasional Bandung',
              style: TextStyle(
                fontSize: compact ? 8 : 8.8,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: subColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
