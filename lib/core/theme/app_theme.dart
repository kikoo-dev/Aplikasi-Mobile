import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Palet warna aplikasi — tema Orange & Putih
/// Institut Teknologi Nasional Bandung (ITENAS).
class AppColors {
  AppColors._();

  // ---------- Identitas ITENAS ----------
  /// Oranye utama ITENAS.
  static const Color primary = Color(0xFFF26522);
  static const Color primaryDark = Color(0xFFD14E0E);
  static const Color primaryLight = Color(0xFFFF8A47);
  static const Color secondary = Color(0xFFFFA53D);
  static const Color accent = Color(0xFFE23E2C);
  static const Color mint = Color(0xFF1FA97A);

  /// Oranye lembut untuk aksen/background.
  static const Color orangeSoft = Color(0xFFFFF1E8);
  static const Color orangeSoft2 = Color(0xFFFFE3D2);

  static const Color bgLight = Color(0xFFFFFFFF);
  static const Color bgCream = Color(0xFFFFFAF6);
  static const Color bgDark = Color(0xFF1A120C);
  static const Color cardDark = Color(0xFF251912);

  static const Color ink = Color(0xFF241A12);
  static const Color inkSoft = Color(0xFF6E6157);
  static const Color inkMuted = Color(0xFF9E9189);

  static const Color line = Color(0xFFF0E7E0);
  static const Color lineDark = Color(0xFF3A2A20);

  static const Color instagram = Color(0xFFE1306C);
  static const Color facebook = Color(0xFF1877F2);
  static const Color tiktok = Color(0xFF010101);

  /// Gradient utama (oranye ITENAS).
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9A4D), Color(0xFFF26522), Color(0xFFD14E0E)],
    stops: [0.0, 0.55, 1.0],
  );

  /// Gradient oranye terang untuk tombol.
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF8A47), Color(0xFFF26522)],
  );

  /// Background halaman terang (putih → krem).
  static const LinearGradient softGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFAF6), Color(0xFFFFF4EC)],
  );

  static const LinearGradient softGradientDark = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF21160F), Color(0xFF1A120C), Color(0xFF140D08)],
  );

  static const LinearGradient instagramGradient = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [
      Color(0xFFFEDA75),
      Color(0xFFFA7E1E),
      Color(0xFFD62976),
      Color(0xFF962FBF),
    ],
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? const Color(0xFFFF9A4D) : AppColors.primary,
      secondary: AppColors.secondary,
      surface: isDark ? AppColors.bgDark : Colors.white,
      error: const Color(0xFFD93025),
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor:
          isDark ? AppColors.bgDark : AppColors.bgCream,
      splashFactory: InkSparkle.splashFactory,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : AppColors.ink,
        systemOverlayStyle:
            isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: isDark ? Colors.white : AppColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardDark : Colors.white,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFFFF6F0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        hintStyle: TextStyle(
          fontSize: 14.5,
          color: isDark ? Colors.white38 : AppColors.inkMuted,
        ),
        labelStyle: TextStyle(
          fontSize: 14.5,
          color: isDark ? Colors.white60 : AppColors.inkSoft,
        ),
        prefixIconColor: isDark ? Colors.white54 : AppColors.inkMuted,
        suffixIconColor: isDark ? Colors.white54 : AppColors.inkMuted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.lineDark : AppColors.line,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFFFF9A4D) : AppColors.primary,
            width: 1.8,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFD93025), width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor:
              isDark ? const Color(0xFFFF9A4D) : AppColors.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isDark ? const Color(0xFF3A2A20) : AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        insetPadding: const EdgeInsets.all(16),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.lineDark : AppColors.line,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}
