-- ============================================================
--  ProfilKita — BERSIHKAN DATA UJI
--  Jalankan di Supabase SQL Editor (punya hak penuh).
--  Menghapus semua akun uji yang dibuat selama pengujian otomatis.
-- ============================================================

-- ------------------------------------------------------------
-- 1. LIHAT DULU data yang akan dihapus
-- ------------------------------------------------------------
select id, email, full_name, created_at
from public.profiles
where lower(split_part(email, '@', 1)) ~
      '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)'
order by created_at;

-- ------------------------------------------------------------
-- 2. HAPUS (buka komentar untuk menjalankan)
-- ------------------------------------------------------------
/*
-- Hapus komentar milik akun uji
delete from public.post_comments
where author_id in (
  select id from public.profiles
  where lower(split_part(email, '@', 1)) ~
        '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)'
);

-- Hapus like milik akun uji
delete from public.post_likes
where user_id in (
  select id from public.profiles
  where lower(split_part(email, '@', 1)) ~
        '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)'
);

-- Hapus postingan milik akun uji
delete from public.posts
where author_id in (
  select id from public.profiles
  where lower(split_part(email, '@', 1)) ~
        '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)'
);

-- Hapus profil akun uji
delete from public.profiles
where lower(split_part(email, '@', 1)) ~
      '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)';
*/

-- ------------------------------------------------------------
-- 3. HAPUS AKUN AUTH (jalankan terpisah)
--    Akun di auth.users hanya bisa dihapus dari sini,
--    bukan lewat anon key aplikasi.
-- ------------------------------------------------------------
/*
delete from auth.users
where lower(split_part(email, '@', 1)) ~
      '^(demo|uji|verif|login|post|pf|fix|kom|share|dbg|cekauth)';
*/

-- ------------------------------------------------------------
-- 4. VERIFIKASI sisa data
-- ------------------------------------------------------------
-- select count(*) as profiles from public.profiles;
-- select count(*) as posts from public.posts;
-- select count(*) as comments from public.post_comments;
