-- ============================================================x
--  ProfilKita — Skema Database Supabase
--  Jalankan seluruh file ini di Supabase Dashboard → SQL Editor
--  (New query → paste → Run)
-- ============================================================

-- ------------------------------------------------------------
-- 1. TABEL PROFIL
-- ------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text,
  full_name    text default '',
  username     text,
  phone        text default '',
  bio          text default '',
  about_me     text default '',
  address      text default '',
  occupation   text default '',
  birth_date   date,
  gender       text default '',
  avatar_url   text default '',
  instagram    text default '',
  facebook     text default '',
  tiktok       text default '',
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- Username unik (case-insensitive), hanya jika tidak kosong.
create unique index if not exists profiles_username_unique
  on public.profiles (lower(username))
  where username is not null and username <> '';

create index if not exists profiles_email_idx on public.profiles (email);

-- ------------------------------------------------------------
-- 2. TRIGGER updated_at
-- ------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ------------------------------------------------------------
-- 3. AUTO-CREATE PROFIL SAAT USER DAFTAR
-- ------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name, username)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'username', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS)
-- ------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists "Profiles are viewable by everyone" on public.profiles;
create policy "Profiles are viewable by everyone"
  on public.profiles for select
  using (true);

drop policy if exists "Users can insert own profile" on public.profiles;
create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

drop policy if exists "Users can delete own profile" on public.profiles;
create policy "Users can delete own profile"
  on public.profiles for delete
  using (auth.uid() = id);

-- ------------------------------------------------------------
-- 5. STORAGE BUCKET UNTUK FOTO PROFIL
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

-- Hapus policy lama (agar aman dijalankan ulang)
drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload their own avatar" on storage.objects;
drop policy if exists "Users can update their own avatar" on storage.objects;
drop policy if exists "Users can delete their own avatar" on storage.objects;

create policy "Avatar images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "Users can upload their own avatar"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their own avatar"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete their own avatar"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- ------------------------------------------------------------
-- SELESAI ✅
-- Catatan: jika "Confirm email" aktif di Authentication → Providers → Email,
-- pengguna harus konfirmasi email dulu sebelum bisa login.
-- Untuk pengembangan cepat, matikan opsi tersebut.
-- ------------------------------------------------------------

-- ------------------------------------------------------------
-- 6. TABEL FEED (POSTINGAN GAYA LINKEDIN)
-- ------------------------------------------------------------
create table if not exists public.posts (
  id            uuid primary key default gen_random_uuid(),
  author_id     uuid not null references public.profiles(id) on delete cascade,
  content       text default '',
  image_url     text default '',
  like_count    int not null default 0,
  comment_count int not null default 0,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists posts_created_at_idx
  on public.posts (created_at desc);

create index if not exists posts_author_idx
  on public.posts (author_id);

drop trigger if exists posts_set_updated_at on public.posts;
create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.set_updated_at();

alter table public.posts enable row level security;

drop policy if exists "Posts are viewable by everyone" on public.posts;
create policy "Posts are viewable by everyone"
  on public.posts for select using (true);

drop policy if exists "Users can create own posts" on public.posts;
create policy "Users can create own posts"
  on public.posts for insert
  with check (auth.uid() = author_id);

drop policy if exists "Users can update own posts" on public.posts;
create policy "Users can update own posts"
  on public.posts for update
  using (auth.uid() = author_id)
  with check (auth.uid() = author_id);

drop policy if exists "Users can delete own posts" on public.posts;
create policy "Users can delete own posts"
  on public.posts for delete
  using (auth.uid() = author_id);

-- ------------------------------------------------------------
-- 7. TABEL LIKE
-- ------------------------------------------------------------
create table if not exists public.post_likes (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (post_id, user_id)
);

create index if not exists post_likes_post_idx on public.post_likes (post_id);

alter table public.post_likes enable row level security;

drop policy if exists "Likes are viewable by everyone" on public.post_likes;
create policy "Likes are viewable by everyone"
  on public.post_likes for select using (true);

drop policy if exists "Users can like as themselves" on public.post_likes;
create policy "Users can like as themselves"
  on public.post_likes for insert
  with check (auth.uid() = user_id);

drop policy if exists "Users can remove own likes" on public.post_likes;
create policy "Users can remove own likes"
  on public.post_likes for delete
  using (auth.uid() = user_id);

-- ------------------------------------------------------------
-- 8. RPC PENGHITUNG LIKE (agar like_count konsisten)
-- ------------------------------------------------------------
create or replace function public.increment_like(post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
     set like_count = like_count + 1
   where id = post_id;
$$;

create or replace function public.decrement_like(post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
     set like_count = greatest(like_count - 1, 0)
   where id = post_id;
$$;

-- ------------------------------------------------------------
-- 9. STORAGE BUCKET UNTUK FOTO POSTINGAN
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do update set public = true;

drop policy if exists "Post images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload post images" on storage.objects;
drop policy if exists "Users can delete own post images" on storage.objects;

create policy "Post images are publicly accessible"
  on storage.objects for select
  using (bucket_id = 'posts');

create policy "Users can upload post images"
  on storage.objects for insert
  with check (
    bucket_id = 'posts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can delete own post images"
  on storage.objects for delete
  using (
    bucket_id = 'posts'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
