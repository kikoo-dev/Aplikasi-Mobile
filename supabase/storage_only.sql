-- ============================================================
--  ProfilKita — BUAT STORAGE BUCKET SAJA
--  Jalankan ini jika tabel & RPC sudah ada tetapi bucket belum.
--  Aman dijalankan berulang.
-- ============================================================

-- ------------------------------------------------------------
-- 1. BUCKET
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit)
values ('avatars', 'avatars', true, 5242880)
on conflict (id) do update
  set public = true,
      file_size_limit = 5242880;

insert into storage.buckets (id, name, public, file_size_limit)
values ('posts', 'posts', true, 5242880)
on conflict (id) do update
  set public = true,
      file_size_limit = 5242880;

-- ------------------------------------------------------------
-- 2. POLICY UNTUK BUCKET avatars
-- ------------------------------------------------------------
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

drop policy if exists "Users can upload their own avatar" on storage.objects;
create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update their own avatar" on storage.objects;
create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete their own avatar" on storage.objects;
create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ------------------------------------------------------------
-- 3. POLICY UNTUK BUCKET posts
-- ------------------------------------------------------------
drop policy if exists "Post images are publicly accessible" on storage.objects;
create policy "Post images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'posts');

drop policy if exists "Users can upload post images" on storage.objects;
create policy "Users can upload post images"
  on storage.objects for insert
  with check (
    bucket_id = 'posts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can update post images" on storage.objects;
create policy "Users can update post images"
  on storage.objects for update
  using (
    bucket_id = 'posts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can delete own post images" on storage.objects;
create policy "Users can delete own post images"
  on storage.objects for delete
  using (
    bucket_id = 'posts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ------------------------------------------------------------
-- VERIFIKASI (opsional — jalankan terpisah untuk melihat hasil)
-- ------------------------------------------------------------
-- select id, name, public from storage.buckets where id in ('avatars','posts');
