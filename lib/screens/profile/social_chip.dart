import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';

/// Chip sosial media yang bisa diklik untuk membuka profil.
class SocialChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final Gradient gradient;

  const SocialChip({
    super.key,
    required this.label,
    required this.icon,
    required this.value,
    required this.gradient,
  });

  bool get _hasValue => value.trim().isNotEmpty;

  String get _url {
    final v = value.trim();
    if (v.startsWith('http://') || v.startsWith('https://')) return v;
    final handle = v.startsWith('@') ? v.substring(1) : v;
    switch (label.toLowerCase()) {
      case 'instagram':
        return 'https://instagram.com/$handle';
      case 'facebook':
        return 'https://facebook.com/$handle';
      case 'tiktok':
        return 'https://tiktok.com/@$handle';
      default:
        return 'https://$handle';
    }
  }

  Future<void> _open(BuildContext context) async {
    if (!_hasValue) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('$label belum diisi. Tambahkan di Edit Profil.'),
          ),
        );
      return;
    }

    final uri = Uri.tryParse(_url);
    if (uri == null) return;

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Tidak bisa membuka $label')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF5F3FD),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFEDEAF7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: _hasValue ? gradient : null,
                color: _hasValue
                    ? null
                    : (isDark ? Colors.white12 : const Color(0xFFE4E0F2)),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 15,
                color: _hasValue
                    ? Colors.white
                    : (isDark ? Colors.white38 : const Color(0xFFA9A3C2)),
              ),
            ),
            const SizedBox(width: 9),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF2C2547),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _hasValue ? value : 'Belum diisi',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _hasValue
                        ? (isDark
                            ? const Color(0xFF9B87FF)
                            : AppColors.primary)
                        : (isDark ? Colors.white30 : const Color(0xFFA9A3C2)),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_outward_rounded,
              size: 13,
              color: isDark ? Colors.white30 : const Color(0xFFC9C4DC),
            ),
          ],
        ),
      ),
    );
  }
}
