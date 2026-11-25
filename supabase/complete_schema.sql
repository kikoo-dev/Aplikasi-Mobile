-- ============================================================
--  ProfilKita — LENGKAPI SKEMA (bagian 6-9)
--  Jalankan di Supabase SQL Editor untuk project yang sudah
--  memiliki tabel `profiles` (bagian 1-5).
--  Aman dijalankan berulang (idempotent).
-- ============================================================

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

-- Trigger updated_at (fungsi set_updated_at sudah dibuat di bagian 2)
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
-- 8. RPC PENGHITUNG LIKE
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
-- 9. STORAGE BUCKET (FOTO PROFIL & FOTO POSTINGAN)
-- ------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do update set public = true;

insert into storage.buckets (id, name, public)
values ('posts', 'posts', true)
on conflict (id) do update set public = true;

drop policy if exists "Avatar images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload their own avatar" on storage.objects;
drop policy if exists "Users can update their own avatar" on storage.objects;
drop policy if exists "Users can delete their own avatar" on storage.objects;

create policy "Avatar images are publicly accessible"
  on storage.objects for select using (bucket_id = 'avatars');

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

drop policy if exists "Post images are publicly accessible" on storage.objects;
drop policy if exists "Users can upload post images" on storage.objects;
drop policy if exists "Users can delete own post images" on storage.objects;

create policy "Post images are publicly accessible"
  on storage.objects for select using (bucket_id = 'posts');

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

-- ------------------------------------------------------------
-- SELESAI ✅  Sekarang tabel posts, post_likes, dan bucket siap.
-- ------------------------------------------------------------
