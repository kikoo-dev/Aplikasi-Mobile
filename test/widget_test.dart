import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'package:social_profile_app/core/env.dart';
import 'package:social_profile_app/main.dart';

void main() {
  setUpAll(() async {
    // Supabase memakai SharedPreferences untuk menyimpan sesi,
    // jadi mock-nya harus disiapkan sebelum initialize.
    SharedPreferences.setMockInitialValues({});
    TestWidgetsFlutterBinding.ensureInitialized();

    if (Env.isSupabaseConfigured) {
      await sb.Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
      );
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Splash tampil lalu berpindah ke halaman Login', (tester) async {
    await tester.pumpWidget(const ProfileApp());

    // Splash langsung tampil.
    expect(find.text('ITENAS'), findsWidgets);

    // Jalankan animasi + jeda splash (2.2 detik) lalu transisi halaman.
    // (Tidak memakai pumpAndSettle karena ada progress indicator berulang.)
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Halaman login muncul.
    expect(find.text('Selamat Datang'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
  });
}
