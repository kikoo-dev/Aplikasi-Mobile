-- ============================================================
--  ProfilKita — FITUR KOMENTAR + PERBAIKAN RPC
--  Jalankan di Supabase SQL Editor. Aman dijalankan berulang.
-- ============================================================

-- ------------------------------------------------------------
-- 1. TABEL KOMENTAR
-- ------------------------------------------------------------
create table if not exists public.post_comments (
  id         uuid primary key default gen_random_uuid(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  author_id  uuid not null references public.profiles(id) on delete cascade,
  content    text not null,
  created_at timestamptz not null default now()
);

create index if not exists post_comments_post_idx
  on public.post_comments (post_id, created_at);

alter table public.post_comments enable row level security;

drop policy if exists "Comments are viewable by everyone" on public.post_comments;
create policy "Comments are viewable by everyone"
  on public.post_comments for select using (true);

drop policy if exists "Users can create own comments" on public.post_comments;
create policy "Users can create own comments"
  on public.post_comments for insert
  with check (auth.uid() = author_id);

drop policy if exists "Users can delete own comments" on public.post_comments;
create policy "Users can delete own comments"
  on public.post_comments for delete
  using (auth.uid() = author_id);

-- ------------------------------------------------------------
-- 2. RPC PENGHITUNG KOMENTAR
-- ------------------------------------------------------------
create or replace function public.increment_comment(post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
     set comment_count = comment_count + 1
   where id = post_id;
$$;

create or replace function public.decrement_comment(post_id uuid)
returns void
language sql
security definer
set search_path = public
as $$
  update public.posts
     set comment_count = greatest(comment_count - 1, 0)
   where id = post_id;
$$;

-- ------------------------------------------------------------
-- 3. SINKRONISASI comment_count YANG SUDAH ADA
-- ------------------------------------------------------------
update public.posts p
   set comment_count = (
     select count(*) from public.post_comments c where c.post_id = p.id
   );

-- ------------------------------------------------------------
-- SELESAI
-- ------------------------------------------------------------
