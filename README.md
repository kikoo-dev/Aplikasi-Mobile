# ProfilKita 📱

Aplikasi mobile Flutter dengan **Splash Screen → Login/Register → Profil & Biodata → Sosial Media → Kalkulator**, memakai **Supabase** sebagai backend (Auth + Postgres + Storage).

---

## ✨ Fitur

| Fitur | Keterangan |
|---|---|
| **Splash Screen** | Animasi logo, pengecekan sesi otomatis (auto-login bila sudah pernah masuk) |
| **Login** | Email + password, validasi, error handling ramah, lupa password |
| **Register** | Nama lengkap, username, email, password + indikator kekuatan password |
| **Home** | Sapaan waktu, kartu profil + persentase kelengkapan, menu utama |
| **Profil Saya** | Avatar, bio, about me, biodata lengkap, sosial media yang bisa diklik |
| **Edit Profil** | Upload foto (galeri), biodata, about me, Instagram/Facebook/TikTok |
| **Kalkulator** | Operasi dasar, persen, kurung, live preview, riwayat, haptic feedback |
| **Dark Mode** | Otomatis mengikuti tema sistem |
| **Mode Demo** | Bisa langsung dijalankan tanpa Supabase (data lokal) |

---

## 🚀 Cara Menjalankan

```bash
flutter pub get
flutter run
```

> Saat pertama dijalankan **tanpa kredensial Supabase**, aplikasi otomatis masuk **MODE DEMO**
> (data disimpan di perangkat). Semua tampilan & alur bisa dicoba.

---

## 🗄️ Menghubungkan ke Supabase

### 1. Buat project
Buka [supabase.com](https://supabase.com) → **New Project**.

### 2. Jalankan skema database
Supabase Dashboard → **SQL Editor** → **New query** → copy-paste seluruh isi
[`supabase/schema.sql`](supabase/schema.sql) → **Run**.

Skema ini otomatis membuat:
- Tabel `profiles` (biodata, about me, instagram, facebook, tiktok, avatar)
- RLS policy (tiap user hanya bisa mengubah profilnya sendiri)
- Trigger `handle_new_user` (profil otomatis dibuat saat register)
- Bucket Storage `avatars` (public) + policy upload

### 3. Isi kredensial
Dashboard → **Project Settings → API**, ambil **Project URL** dan **anon/publishable key**.

**Cara A — langsung di kode** (`lib/core/env.dart`):

```dart
static const String supabaseUrl = 'https://xxxxx.supabase.co';
static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6...';
```

**Cara B — dart-define (disarankan, tidak menyimpan key di repo):**

```bash
flutter run --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi...
```

### 4. (Opsional) Matikan konfirmasi email
Authentication → **Providers → Email** → matikan **Confirm email**
agar bisa langsung login setelah daftar saat masa pengembangan.

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                     # Entry point + init Supabase & locale
├── app.dart                      # MaterialApp, tema, AuthController
├── core/
│   ├── env.dart                  # Konfigurasi Supabase (+ deteksi mode demo)
│   ├── app_scope.dart            # InheritedNotifier untuk state global
│   ├── format.dart               # Format tanggal Indonesia
│   └── theme/app_theme.dart      # Warna, gradient, ThemeData light/dark
├── models/
│   ├── app_user.dart             # AppUser + abstraksi AuthService
│   └── user_profile.dart         # Model profil (toMap/fromMap)
├── services/
│   ├── supabase_service.dart     # Implementasi Supabase (auth, db, storage)
│   ├── demo_service.dart         # Implementasi lokal (SharedPreferences)
│   └── auth_controller.dart      # State global (login, profil, busy)
├── screens/
│   ├── splash/splash_screen.dart
│   ├── auth/login_screen.dart
│   ├── auth/register_screen.dart
│   ├── home/home_screen.dart
│   ├── profile/profile_screen.dart
│   ├── profile/edit_profile_screen.dart
│   ├── profile/social_chip.dart
│   └── calculator/calculator_screen.dart
└── widgets/
    ├── common.dart               # GlassCard, GradientButton, PageHeader, dll
    └── profile_avatar.dart       # Avatar (network/data-uri/bytes/inisial)
```

---

## 🧱 Skema Tabel `profiles`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | uuid (PK) | = `auth.users.id` |
| `email` | text | |
| `full_name` | text | Nama lengkap |
| `username` | text | Unik (case-insensitive) |
| `phone` | text | |
| `bio` | text | Bio singkat |
| `about_me` | text | Deskripsi panjang |
| `address` | text | |
| `occupation` | text | |
| `birth_date` | date | |
| `gender` | text | |
| `avatar_url` | text | URL foto di Storage |
| `instagram` | text | Username IG |
| `facebook` | text | Username FB |
| `tiktok` | text | Username TikTok |
| `created_at` / `updated_at` | timestamptz | |

---

## ✅ Perintah Berguna

```bash
flutter analyze        # Cek statis (bersih, 0 issue)
flutter test           # Jalankan widget test
flutter build apk      # Build Android
flutter build web      # Build Web
```

---

## 📝 Catatan

- Kredensial di `Env` bersifat **publik** (anon key memang untuk client). Jangan pernah memakai `service_role` key di aplikasi.
- Keamanan data diatur oleh **Row Level Security** di `supabase/schema.sql`.
- Mode demo menyimpan password dalam bentuk hash SHA-256 + salt di perangkat — hanya untuk keperluan demo, bukan produksi.

---

## ?? Presentasi Project

File: **`Presentasi_ProfilKita_ITENAS.pptx`** (14 slide, 16:9)

| Slide | Isi |
|---|---|
| 1 | Cover � ProfilKita, ITENAS |
| 2 | Agenda |
| 3 | Latar belakang & solusi |
| 4 | Tujuan project |
| 5 | Fitur utama (6 fitur) |
| 6 | Stack teknologi & alur data |
| 7 | Struktur folder & prinsip kode |
| 8 | Desain & palet warna |
| 9 | Skema database & keamanan |
| 10 | Alur aplikasi (6 langkah) |
| 11 | **Demo � 6 screenshot asli dari ROG Phone 3** |
| 12 | Keunggulan |
| 13 | Kesimpulan & pengembangan lanjutan |
| 14 | Terima kasih |

### Regenerasi presentasi

```bash
python tools/generate_pptx.py    # buat ulang PPTX
python tools/check_pptx.py       # cek layout (teks meluber / keluar batas)
python tools/export_pptx.py      # export tiap slide ke PNG (butuh PowerPoint)
```

### Ambil ulang screenshot dari HP

```bash
python tools/capture_screens.py  # splash, login, register, beranda, feed, kalkulator
python tools/capture_profile.py  # halaman profil & edit profil
python tools/prepare_screens.py  # crop + resize untuk slide
python tools/generate_pptx.py    # tanam ulang ke PPT
```

---

## ?? Menyimpan Aplikasi di HP (APK)

Aplikasi sudah dibuild menjadi APK dan **siap dipasang permanen** di HP tanpa perlu laptop.

### File APK (folder `release/`)

| File | Ukuran | Untuk |
|---|---|---|
| `ProfilKita-ITENAS-arm64.apk` | 18.9 MB | **Rekomendasi** � HP Android modern (ROG Phone 3, dll) |
| `ProfilKita-ITENAS-armv7.apk` | 16.6 MB | HP Android lama (32-bit) |
| `ProfilKita-ITENAS-universal.apk` | 54 MB | Semua HP � kalau ragu |

Panduan lengkap: **`release/PANDUAN-INSTALASI.md`**

### Cara install

**Via kabel USB:**
```bash
adb install -r release/ProfilKita-ITENAS-arm64.apk
```

**Tanpa kabel:**
1. Copy APK ke HP (WhatsApp/Drive/email)
2. Buka File Manager ? tap APK
3. Izinkan "Install unknown apps" ? Install

### Build ulang

```bash
flutter build apk --release                      # universal
flutter build apk --release --split-per-abi      # per arsitektur (lebih kecil)
flutter build appbundle --release                # untuk Play Store
```

### Ikon aplikasi

Ikon sudah diganti dari default Flutter menjadi logo ITENAS (perisai + "ITENAS" di atas gradient orange). Dibuat oleh:

```bash
python tools/generate_icons.py
```

Menghasilkan ikon untuk Android (5 ukuran), iOS (15 ukuran), dan Web (3 ukuran).

### ?? Penting

- APK ini ditandatangani **debug key** ? bisa dipasang & dibagikan, tapi **tidak bisa** ke Play Store
- Data mode demo tersimpan **lokal di HP** � hilang jika di-uninstall
- Untuk data nyata & multi-device, sambungkan ke Supabase (isi `lib/core/env.dart`)


---

## Supabase (AKTIF)

Project: `cgqespmtpvoafiinygao`

| Komponen | Status |
|---|---|
| Auth (signup / login / logout) | OK - confirm email nonaktif |
| Tabel `profiles` + trigger `handle_new_user` | OK |
| Tabel `posts` + `post_likes` | OK |
| RPC `increment_like` / `decrement_like` | OK |
| Bucket storage `avatars` & `posts` | OK - public, limit 5 MB |

Kredensial ada di `lib/core/env.dart` (hanya anon key, aman untuk client).

### Catatan build release Android

Build release memakai `isMinifyEnabled = false` di
`android/app/build.gradle.kts` untuk menghindari bug
flutter/flutter#194649: R8 merusak signature `getAll` pada plugin
`shared_preferences_android` 2.5.x sehingga aplikasi crash
(NoSuchMethodError) saat dibuka.

Jangan aktifkan minify sampai bug tersebut diperbaiki di upstream.

### Tools verifikasi

```bash
python tools/verify_supabase_full.py   # 11 pemeriksaan integrasi Supabase
python tools/check_bucket.py           # cek bucket storage
python tools/diagnose_supabase.py      # diagnosa tabel / RPC / bucket
python tools/e2e_login_test.py         # uji login di HP + verifikasi data
```


---

## Fitur Feed: Bagikan, Foto & Komentar

### Bagikan postingan

Composer (tombol pensil kanan bawah) mendukung teks dan/atau foto.

PENTING: Supabase mengembalikan body kosong pada `insert` bila header
`Prefer: return=representation` tidak dikirim, sehingga `.single()` gagal
dan muncul pesan "Gagal membagikan". Klien Dart Supabase mengirim header
ini otomatis lewat `.select()`, jadi jangan menghapus `.select()` pada
rantai insert.

### Upload foto

- Tombol Galeri / Kamera di composer
- Validasi maksimal 5 MB
- Diunggah ke bucket `posts` dengan path `{user_id}/post_{timestamp}.jpg`
- URL publik disimpan di kolom `image_url`

### Komentar

Tabel `post_comments` + RPC `increment_comment` / `decrement_comment`.
Jalankan `supabase/comments_schema.sql` untuk mengaktifkannya.

Halaman komentar: `lib/screens/home/comments_screen.dart`

### Tools verifikasi

```bash
python tools/verify_comments.py        # 10 pemeriksaan komentar + RLS
python tools/cleanup_test_data.py      # cek data uji yang tersisa
```

### Membersihkan data uji

RLS memblokir penghapusan data user lain memakai anon key (ini benar).
Jalankan `supabase/cleanup_test_data.sql` di SQL Editor untuk menghapus
akun uji (`demo*`, `uji*`, `verif*`, `login*`, `post*`, `kom*`, dll).


---

## Hapus Postingan

Fitur hapus tersedia lewat menu titik tiga (more) pada kartu postingan.

- Menu **hanya muncul** pada postingan milik sendiri (`isMine`)
- Postingan orang lain menampilkan **"Laporkan"**, bukan "Hapus"
- Ada dialog konfirmasi sebelum menghapus
- Optimistic update: kartu langsung hilang, dikembalikan bila gagal
- Komentar dan like ikut terhapus otomatis (ON DELETE CASCADE)

Keamanan dijamin oleh RLS:

```sql
create policy "Users can delete own posts"
  on public.posts for delete
  using (auth.uid() = author_id);
```

`deletePost()` juga memverifikasi ulang setelah delete — jika baris masih
ada (misal policy belum dibuat), muncul pesan error yang jelas.

### Verifikasi

```bash
python tools/verify_delete_post.py   # 8 pemeriksaan (termasuk RLS + cascade)
python tools/e2e_delete_test.py      # uji hapus di perangkat
```
