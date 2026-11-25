# 📲 Panduan Instalasi ProfilKita ITENAS

Aplikasi bisa disimpan permanen di HP tanpa perlu laptop/Flutter lagi.

---

## 📦 File yang tersedia

| File | Ukuran | Untuk |
|---|---|---|
| **ProfilKita-ITENAS-arm64.apk** | 18.9 MB | **Rekomendasi** — HP Android modern (2017 ke atas) |
| ProfilKita-ITENAS-armv7.apk | 16.6 MB | HP Android lama (32-bit) |
| ProfilKita-ITENAS-universal.apk | 54 MB | Semua HP — kalau ragu, pakai ini |

> **ROG Phone 3 kamu**: pakai **arm64** (paling kecil & paling cepat).

---

## ✅ Cara install (pilih salah satu)

### Cara 1 — Lewat kabel USB (paling mudah, sudah terbukti)

```powershell
adb install -r release\ProfilKita-ITENAS-arm64.apk
```

Atau pakai Android Studio / VS Code → jalankan APK ke device.

### Cara 2 — Transfer file ke HP

1. Copy file `.apk` ke HP (via kabel, WhatsApp, Google Drive, atau email)
2. Buka **File Manager** di HP → cari file `.apk`
3. Tap file tersebut
4. Jika muncul peringatan **"Install unknown apps"**:
   - Tap **Settings** → aktifkan **Allow from this source**
   - Kembali → tap **Install**
5. Tunggu sampai selesai → tap **Open**

### Cara 3 — Via ADB wireless (tanpa kabel)

1. Di HP: **Settings → Developer options → Wireless debugging** → aktifkan
2. Tap **Pair device with pairing code** → catat IP:port & kode
3. Di laptop:
   ```powershell
   adb pair 192.168.x.x:xxxxx
   adb connect 192.168.x.x:5555
   adb install -r release\ProfilKita-ITENAS-arm64.apk
   ```

---

## 🎯 Setelah terpasang

Aplikasi muncul di **app drawer** dengan nama **ProfilKita** dan ikon Flutter default.

Bisa dibuka **tanpa kabel, tanpa laptop, tanpa internet** (mode demo).

### Alur pertama kali

1. **Splash** (~2,5 detik, logo ITENAS)
2. **Login** → tap **"Daftar sekarang"**
3. Isi nama, username, email, password → **Daftar Sekarang**
4. Masuk **Beranda** — feed kampus dengan postingan & foto
5. Tap **Edit Profil** → lengkapi biodata, about me, Instagram/Facebook/TikTok
6. Tap **Kalkulator** → coba `12+5×3=` → hasil **27**

---

## 🔧 Perintah build ulang

```bash
# APK universal (semua HP)
flutter build apk --release

# APK per arsitektur (lebih kecil)
flutter build apk --release --split-per-abi

# App Bundle untuk Google Play Store
flutter build appbundle --release
```

Hasil build ada di:
- `build/app/outputs/flutter-apk/`
- `build/app/outputs/bundle/release/`

---

## ⚠️ Catatan penting

### Soal tanda tangan (signing)

APK ini ditandatangani dengan **debug key** (default Flutter). Artinya:

- ✅ Bisa dipasang & dipakai di HP sendiri
- ✅ Bisa dibagikan ke teman untuk demo
- ❌ **Tidak bisa** diupload ke Google Play Store
- ❌ Tidak bisa diupdate lewat Play Store

Untuk Play Store, perlu buat **keystore sendiri**:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Lalu daftarkan di `android/key.properties` dan `android/app/build.gradle.kts`.
Beri tahu saya kalau mau saya siapkan konfigurasi ini.

### Soal data

Saat ini aplikasi berjalan dalam **mode demo** — data (akun, profil, postingan) tersimpan **lokal di HP** memakai SharedPreferences.

Artinya:
- Data hilang kalau aplikasi di-uninstall
- Data tidak tersinkron antar HP
- Tidak ada backup otomatis

Untuk data nyata & multi-device, sambungkan ke **Supabase**:
1. Jalankan `supabase/schema.sql` di Supabase SQL Editor
2. Isi URL + anon key di `lib/core/env.dart`
3. Build ulang APK

### Soal ikon aplikasi

Ikon masih ikon Flutter default. Untuk mengganti dengan logo ITENAS, beri tahu saya — bisa dibuatkan.

---

## 🗑️ Uninstall

- **Dari HP**: tekan lama ikon ProfilKita → Uninstall
- **Via ADB**: `adb uninstall com.example.social_profile_app`
