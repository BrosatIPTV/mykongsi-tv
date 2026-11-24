-- MyKongsi TV: Kongsi Movie schema
-- Jalankan sekali sahaja di Supabase SQL Editor.
-- Semua rahsia API kekal di Supabase Edge Function Secrets, bukan dalam jadual ini.

create extension if not exists pgcrypto;

create table if not exists public.km_providers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  api_type text not null default 'REST' check (api_type in ('REST','GraphQL','Other')),
  website_url text,
  docs_url text,
  notes text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.km_categories (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  slug text unique,
  description text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.km_movies (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid references public.km_providers(id) on delete set null,
  external_id text,
  title text not null,
  original_title text,
  content_type text not null default 'movie'
    check (content_type in ('movie','series','anime','documentary','kids')),
  overview text,
  poster_url text,
  backdrop_url text,
  release_date date,
  release_year integer,
  original_language text,
  runtime_minutes integer,
  status text not null default 'draft'
    check (status in ('draft','published','archived')),
  is_featured boolean not null default false,
  sort_order integer not null default 0,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(provider_id, external_id)
);

create table if not exists public.km_movie_categories (
  movie_id uuid not null references public.km_movies(id) on delete cascade,
  category_id uuid not null references public.km_categories(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(movie_id, category_id)
);

create table if not exists public.km_seasons (
  id uuid primary key default gen_random_uuid(),
  movie_id uuid not null references public.km_movies(id) on delete cascade,
  season_number integer not null,
  name text,
  overview text,
  poster_url text,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(movie_id, season_number)
);

create table if not exists public.km_episodes (
  id uuid primary key default gen_random_uuid(),
  season_id uuid not null references public.km_seasons(id) on delete cascade,
  episode_number integer not null,
  title text not null,
  overview text,
  still_url text,
  runtime_minutes integer,
  status text not null default 'draft' check (status in ('draft','published','archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(season_id, episode_number)
);

-- URL playback disimpan berasingan dan tidak diberi SELECT kepada pengguna awam.
-- Aplikasi pelanggan kelak perlu meminta playback melalui Edge Function yang mengesahkan hak akses.
create table if not exists public.km_playback_sources (
  id uuid primary key default gen_random_uuid(),
  movie_id uuid references public.km_movies(id) on delete cascade,
  episode_id uuid references public.km_episodes(id) on delete cascade,
  source_name text not null default 'Primary',
  source_type text not null default 'HLS' check (source_type in ('HLS','DASH','FILE','EMBED','OTHER')),
  playback_url text not null,
  is_active boolean not null default true,
  priority integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint km_playback_one_parent check (
    (movie_id is not null and episode_id is null) or
    (movie_id is null and episode_id is not null)
  )
);

create table if not exists public.km_sync_logs (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid references public.km_providers(id) on delete set null,
  sync_type text not null default 'catalog_import',
  status text not null default 'pending' check (status in ('pending','success','partial','failed')),
  message text,
  records_count integer not null default 0,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists km_movies_status_type_idx on public.km_movies(status, content_type);
create index if not exists km_movies_provider_external_idx on public.km_movies(provider_id, external_id);
create index if not exists km_seasons_movie_idx on public.km_seasons(movie_id, season_number);
create index if not exists km_episodes_season_idx on public.km_episodes(season_id, episode_number);
create index if not exists km_sync_logs_created_idx on public.km_sync_logs(created_at desc);

-- RLS: pentadbir ditentukan melalui jadual admin_users MyKongsi TV yang sedia ada.
alter table public.km_providers enable row level security;
alter table public.km_categories enable row level security;
alter table public.km_movies enable row level security;
alter table public.km_movie_categories enable row level security;
alter table public.km_seasons enable row level security;
alter table public.km_episodes enable row level security;
alter table public.km_playback_sources enable row level security;
alter table public.km_sync_logs enable row level security;

-- Admin policies
drop policy if exists "km_providers_admin_all" on public.km_providers;
create policy "km_providers_admin_all" on public.km_providers
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_categories_admin_all" on public.km_categories;
create policy "km_categories_admin_all" on public.km_categories
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_movies_admin_all" on public.km_movies;
create policy "km_movies_admin_all" on public.km_movies
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_movie_categories_admin_all" on public.km_movie_categories;
create policy "km_movie_categories_admin_all" on public.km_movie_categories
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_seasons_admin_all" on public.km_seasons;
create policy "km_seasons_admin_all" on public.km_seasons
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_episodes_admin_all" on public.km_episodes;
create policy "km_episodes_admin_all" on public.km_episodes
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_playback_sources_admin_all" on public.km_playback_sources;
create policy "km_playback_sources_admin_all" on public.km_playback_sources
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

drop policy if exists "km_sync_logs_admin_all" on public.km_sync_logs;
create policy "km_sync_logs_admin_all" on public.km_sync_logs
for all to authenticated
using (exists (select 1 from public.admin_users a where a.user_id = auth.uid()))
with check (exists (select 1 from public.admin_users a where a.user_id = auth.uid()));

-- Read-only access for app clients to published catalog metadata.
drop policy if exists "km_categories_public_read_active" on public.km_categories;
create policy "km_categories_public_read_active" on public.km_categories
for select to anon, authenticated using (is_active = true);

drop policy if exists "km_movies_public_read_published" on public.km_movies;
create policy "km_movies_public_read_published" on public.km_movies
for select to anon, authenticated using (status = 'published');

drop policy if exists "km_movie_categories_public_read_published" on public.km_movie_categories;
create policy "km_movie_categories_public_read_published" on public.km_movie_categories
for select to anon, authenticated using (
  exists (select 1 from public.km_movies m where m.id = movie_id and m.status = 'published')
);

drop policy if exists "km_seasons_public_read_published" on public.km_seasons;
create policy "km_seasons_public_read_published" on public.km_seasons
for select to anon, authenticated using (
  status = 'published' and exists (select 1 from public.km_movies m where m.id = movie_id and m.status = 'published')
);

drop policy if exists "km_episodes_public_read_published" on public.km_episodes;
create policy "km_episodes_public_read_published" on public.km_episodes
for select to anon, authenticated using (
  status = 'published' and exists (
    select 1 from public.km_seasons s join public.km_movies m on m.id = s.movie_id
    where s.id = season_id and s.status = 'published' and m.status = 'published'
  )
);

-- IMPORTANT: no public SELECT policy on km_playback_sources or provider records.
-- Playback URLs should be resolved by a server-side Edge Function after entitlement checks.
