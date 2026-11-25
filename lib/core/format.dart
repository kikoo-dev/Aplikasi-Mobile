import 'package:intl/intl.dart';

/// Format tanggal dengan locale Indonesia, dengan fallback aman
/// jika data locale belum diinisialisasi.
String formatTanggal(DateTime date, {String pattern = 'd MMMM yyyy'}) {
  try {
    return DateFormat(pattern, 'id_ID').format(date);
  } catch (_) {
    return DateFormat(pattern).format(date);
  }
}

/// Waktu relatif ala media sosial: "Baru saja", "5 mnt", "2 jam", "3 hr".
String waktuRelatif(DateTime date) {
  final diff = DateTime.now().difference(date);

  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} mnt';
  if (diff.inHours < 24) return '${diff.inHours} jam';
  if (diff.inDays < 7) return '${diff.inDays} hr';
  if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} mgg';
  if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} bln';
  return '${(diff.inDays / 365).floor()} thn';
}

/// Angka ringkas: 1200 -> "1,2 rb", 2500000 -> "2,5 jt".
String angkaRingkas(int value) {
  if (value < 1000) return value.toString();
  if (value < 1000000) {
    final v = value / 1000;
    return '${_trim(v)} rb';
  }
  final v = value / 1000000;
  return '${_trim(v)} jt';
}

String _trim(double v) {
  final text = v.toStringAsFixed(1);
  return text.endsWith('.0') ? text.substring(0, text.length - 2) : text.replaceAll('.', ',');
}
