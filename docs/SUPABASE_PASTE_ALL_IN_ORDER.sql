-- Moskova: core + AI pipeline (image-first)
-- idempotent-ish for local dev

create extension if not exists pgcrypto;

-- ——— Profiles (auth.users eşlemesi) ———
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

-- ——— Workspaces ———
create table if not exists public.workspaces (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  slug text not null unique,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

create table if not exists public.workspace_members (
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null check (role in ('admin', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (workspace_id, user_id)
);

create table if not exists public.profession_sources (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null
);

-- ——— Professions ———
create table if not exists public.professions (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  source_id uuid references public.profession_sources (id),
  title text not null,
  description text,
  future_context text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_professions_workspace on public.professions (workspace_id);

-- ——— Meme briefs ———
create table if not exists public.meme_briefs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  profession_id uuid not null references public.professions (id) on delete cascade,
  target_audience text,
  platform_target text,
  cultural_angle text,
  emotional_hook text,
  meme_style text,
  memotype_idea text,
  memotype_fact text,
  memotype_hook text,
  memotype_audience_angle text,
  phenotype_format text,
  phenotype_visual_style text,
  phenotype_caption_angle text,
  phenotype_text_overlay text,
  suggested_caption_ru text,
  short_rationale_ru text,
  admin_notes_tr text,
  admin_notes_en text,
  generation_direction text,
  internal_rank int,
  review_status text not null default 'draft' check (review_status in (
    'draft', 'needs_review', 'approved', 'rejected', 'regenerate'
  )),
  is_mock boolean not null default false,
  memotype jsonb,
  phenotype jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_meme_briefs_profession on public.meme_briefs (profession_id);
create index if not exists idx_meme_briefs_workspace on public.meme_briefs (workspace_id);

-- ——— Assets (sürümler) ———
create table if not exists public.meme_assets (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  meme_brief_id uuid not null references public.meme_briefs (id) on delete cascade,
  created_at timestamptz not null default now()
);
create index if not exists idx_meme_assets_brief on public.meme_assets (meme_brief_id);

create table if not exists public.meme_asset_versions (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.meme_assets (id) on delete cascade,
  version_number int not null,
  file_url text,
  storage_path text,
  width int,
  height int,
  metadata jsonb,
  prompt_used text,
  negative_constraints text,
  provider text,
  generation_parameters jsonb,
  source_meme_brief_id uuid not null references public.meme_briefs (id) on delete cascade,
  is_mock boolean not null default false,
  review_status text not null default 'needs_review' check (review_status in (
    'draft', 'needs_review', 'approved', 'rejected', 'regenerate'
  )),
  created_at timestamptz not null default now(),
  unique (asset_id, version_number)
);
create index if not exists idx_meme_asset_versions_brief
  on public.meme_asset_versions (source_meme_brief_id);

-- ——— AI jobs & outputs ———
create table if not exists public.ai_generation_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  job_type text not null check (job_type in ('brief_batch', 'image', 'text')),
  status text not null default 'pending' check (status in (
    'pending', 'processing', 'completed', 'failed', 'cancelled'
  )),
  profession_id uuid references public.professions (id) on delete set null,
  meme_brief_id uuid references public.meme_briefs (id) on delete set null,
  provider text,
  is_mock boolean not null default false,
  params jsonb,
  last_error text,
  retry_count int not null default 0,
  created_by uuid references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);
create index if not exists idx_ai_jobs_ws on public.ai_generation_jobs (workspace_id);
create index if not exists idx_ai_jobs_brief on public.ai_generation_jobs (meme_brief_id);

create table if not exists public.ai_generation_outputs (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.ai_generation_jobs (id) on delete cascade,
  output_kind text not null,
  text_payload text,
  image_url text,
  storage_path text,
  metadata jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_ai_gen_outputs_job on public.ai_generation_outputs (job_id);

-- ——— Prompt templates (DB-backed, sürümler) ———
create table if not exists public.prompt_templates (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  template_key text not null,
  display_name text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (workspace_id, template_key)
);

create table if not exists public.prompt_template_versions (
  id uuid primary key default gen_random_uuid(),
  template_id uuid not null references public.prompt_templates (id) on delete cascade,
  version_number int not null,
  body text not null,
  variable_schema jsonb,
  created_at timestamptz not null default now(),
  created_by uuid references public.profiles (id),
  unique (template_id, version_number)
);
create index if not exists idx_ptv_template on public.prompt_template_versions (template_id);

-- ——— Brief scores (ranking) ———
create table if not exists public.brief_scores (
  id uuid primary key default gen_random_uuid(),
  meme_brief_id uuid not null references public.meme_briefs (id) on delete cascade,
  direction text not null,
  score numeric(5, 2) not null,
  rank int,
  created_at timestamptz not null default now(),
  unique (meme_brief_id, direction)
);

-- ——— Asset review audit ———
create table if not exists public.asset_review_actions (
  id uuid primary key default gen_random_uuid(),
  asset_version_id uuid not null references public.meme_asset_versions (id) on delete cascade,
  from_status text,
  to_status text not null,
  action_type text not null check (action_type in (
    'submit', 'approve', 'reject', 'request_regenerate', 'comment'
  )),
  note text,
  actor_id uuid references public.profiles (id),
  created_at timestamptz not null default now()
);

-- ——— updated_at ———
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_professions_updated on public.professions;
create trigger trg_professions_updated
  before update on public.professions
  for each row execute function public.set_updated_at();

drop trigger if exists trg_meme_briefs_updated on public.meme_briefs;
create trigger trg_meme_briefs_updated
  before update on public.meme_briefs
  for each row execute function public.set_updated_at();

drop trigger if exists trg_ai_jobs_updated on public.ai_generation_jobs;
create trigger trg_ai_jobs_updated
  before update on public.ai_generation_jobs
  for each row execute function public.set_updated_at();

-- ——— Auth: yeni kullanıcı profil ———
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', ''));
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ——— RLS ———
alter table public.profiles enable row level security;
alter table public.workspaces enable row level security;
alter table public.workspace_members enable row level security;
alter table public.profession_sources enable row level security;
alter table public.professions enable row level security;
alter table public.meme_briefs enable row level security;
alter table public.meme_assets enable row level security;
alter table public.meme_asset_versions enable row level security;
alter table public.ai_generation_jobs enable row level security;
alter table public.ai_generation_outputs enable row level security;
alter table public.prompt_templates enable row level security;
alter table public.prompt_template_versions enable row level security;
alter table public.brief_scores enable row level security;
alter table public.asset_review_actions enable row level security;

-- Üye olan kullanıcı workspace içeriğine erişir
create or replace function public.is_workspace_member(wid uuid)
returns boolean
language sql
security definer
set search_path = public
stable
as $$
  select exists (
    select 1
    from public.workspace_members m
    where m.workspace_id = wid and m.user_id = auth.uid()
  );
$$;

-- profiles: kendisi
create policy "profiles self read" on public.profiles
  for select using (id = auth.uid());
create policy "profiles self update" on public.profiles
  for update using (id = auth.uid());

-- workspaces: oluşturucu veya üyeler
create policy "workspaces read members" on public.workspaces
  for select using (
    public.is_workspace_member(id)
    or (created_by is not null and created_by = auth.uid())
  );
create policy "workspaces insert" on public.workspaces
  for insert to authenticated
  with check (created_by = auth.uid());
create policy "workspaces update own or admin" on public.workspaces
  for update using (
    exists (select 1 from public.workspace_members m
      where m.workspace_id = id and m.user_id = auth.uid() and m.role in ('admin', 'editor')
    ) or (created_by is not null and created_by = auth.uid())
  );

-- workspace_members: üyelik; ilk üye: workspace oluşturucusu kendini admin ekler
create policy "wm self" on public.workspace_members
  for select using (user_id = auth.uid() or public.is_workspace_member(workspace_id));
create policy "wm insert founder or admin" on public.workspace_members
  for insert with check (
    (user_id = auth.uid() and exists (
      select 1 from public.workspaces w
      where w.id = workspace_id and w.created_by = auth.uid()
    ))
    or exists (select 1 from public.workspace_members o
      where o.workspace_id = workspace_id and o.user_id = auth.uid() and o.role = 'admin'
    )
  );

-- profession_sources: herkese oku (küçük lookup)
create policy "ps read all" on public.profession_sources
  for select to authenticated using (true);

-- tenant tablolar
create policy "prof r" on public.professions
  for select using (public.is_workspace_member(workspace_id));
create policy "prof w" on public.professions
  for all using (public.is_workspace_member(workspace_id));

create policy "mb r" on public.meme_briefs
  for select using (public.is_workspace_member(workspace_id));
create policy "mb w" on public.meme_briefs
  for all using (public.is_workspace_member(workspace_id));

create policy "ma r" on public.meme_assets
  for select using (public.is_workspace_member(workspace_id));
create policy "ma w" on public.meme_assets
  for all using (public.is_workspace_member(workspace_id));

create policy "mav r" on public.meme_asset_versions
  for select using (
    exists (select 1 from public.meme_assets a
      where a.id = asset_id and public.is_workspace_member(a.workspace_id))
  );
create policy "mav w" on public.meme_asset_versions
  for all using (
    exists (select 1 from public.meme_assets a
      where a.id = asset_id and public.is_workspace_member(a.workspace_id))
  );

create policy "aj r" on public.ai_generation_jobs
  for select using (public.is_workspace_member(workspace_id));
create policy "aj w" on public.ai_generation_jobs
  for all using (public.is_workspace_member(workspace_id));

create policy "ao r" on public.ai_generation_outputs
  for select using (exists (
    select 1 from public.ai_generation_jobs j
    where j.id = job_id and public.is_workspace_member(j.workspace_id)
  ));
create policy "ao w" on public.ai_generation_outputs
  for all using (exists (
    select 1 from public.ai_generation_jobs j
    where j.id = job_id and public.is_workspace_member(j.workspace_id)
  ));

create policy "pt r" on public.prompt_templates
  for select using (public.is_workspace_member(workspace_id));
create policy "pt w" on public.prompt_templates
  for all using (public.is_workspace_member(workspace_id));

create policy "ptv r" on public.prompt_template_versions
  for select using (exists (
    select 1 from public.prompt_templates t
    where t.id = template_id and public.is_workspace_member(t.workspace_id)
  ));
create policy "ptv w" on public.prompt_template_versions
  for all using (exists (
    select 1 from public.prompt_templates t
    where t.id = template_id and public.is_workspace_member(t.workspace_id)
  ));

create policy "bs r" on public.brief_scores
  for select using (exists (
    select 1 from public.meme_briefs b
    where b.id = meme_brief_id and public.is_workspace_member(b.workspace_id)
  ));
create policy "bs w" on public.brief_scores
  for all using (exists (
    select 1 from public.meme_briefs b
    where b.id = meme_brief_id and public.is_workspace_member(b.workspace_id)
  ));

create policy "ara r" on public.asset_review_actions
  for select using (exists (
    select 1 from public.meme_asset_versions v
    join public.meme_assets a on a.id = v.asset_id
    where v.id = asset_version_id and public.is_workspace_member(a.workspace_id)
  ));
create policy "ara w" on public.asset_review_actions
  for all using (exists (
    select 1 from public.meme_asset_versions v
    join public.meme_assets a on a.id = v.asset_id
    where v.id = asset_version_id and public.is_workspace_member(a.workspace_id)
  ));

-- ——— Storage ———
insert into storage.buckets (id, name, public)
  values ('meme-assets', 'meme-assets', true)
  on conflict (id) do nothing;

-- Yeniden çalıştırmada 42710 önlemi: policy zaten varsa kaldır, sonra oluştur
drop policy if exists "meme assets read" on storage.objects;
drop policy if exists "meme assets write" on storage.objects;
drop policy if exists "meme assets update" on storage.objects;

create policy "meme assets read"
  on storage.objects for select
  to authenticated
  using (bucket_id = 'meme-assets');

create policy "meme assets write"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'meme-assets');

create policy "meme assets update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'meme-assets');
-- PHASE 3: dağıtım + analitik (MVP VK + Telegram)
-- 0001_initial sonrası; mevcut is_workspace_member(wid) kullanır

do $$ begin
  create type public.publish_job_status as enum (
    'queued', 'processing', 'published', 'failed', 'partial'
  );
exception when duplicate_object then null; end $$;

do $$ begin
  create type public.analytics_sync_status as enum (
    'queued', 'running', 'succeeded', 'failed'
  );
exception when duplicate_object then null; end $$;

create table if not exists public.platform_connections (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  platform text not null check (platform in ('vk', 'telegram', 'mock')),
  display_name text not null,
  is_active boolean not null default true,
  settings jsonb not null default '{}',
  last_sync_error text,
  last_synced_at timestamptz,
  last_analytics_sync_at timestamptz,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_platform_connections_ws on public.platform_connections (workspace_id);

create table if not exists public.platform_connection_secrets (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null unique references public.platform_connections (id) on delete cascade,
  ciphertext text not null,
  key_version int not null default 1,
  created_at timestamptz not null default now()
);

create table if not exists public.publish_targets (
  id uuid primary key default gen_random_uuid(),
  connection_id uuid not null references public.platform_connections (id) on delete cascade,
  name text not null,
  target_type text not null,
  target_config jsonb not null default '{}',
  is_default boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists idx_publish_targets_conn on public.publish_targets (connection_id);

create table if not exists public.publish_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  target_id uuid not null references public.publish_targets (id) on delete restrict,
  status public.publish_job_status not null default 'queued',
  schedule_at timestamptz,
  asset_url text not null,
  asset_kind text not null check (asset_kind in ('image', 'video', 'mixed')),
  caption text,
  profession_slug text,
  meme_style text,
  audience_segment text,
  meme_brief_id uuid references public.meme_briefs (id) on delete set null,
  meme_asset_version_id uuid references public.meme_asset_versions (id) on delete set null,
  next_retry_at timestamptz,
  attempt_count int not null default 0,
  max_attempts int not null default 5,
  last_error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_publish_jobs_ws on public.publish_jobs (workspace_id, status, created_at);

create table if not exists public.publish_job_attempts (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.publish_jobs (id) on delete cascade,
  started_at timestamptz not null default now(),
  finished_at timestamptz,
  success boolean,
  error_message text,
  response jsonb
);
create index if not exists idx_publish_job_attempts_job on public.publish_job_attempts (job_id);

create table if not exists public.external_publications (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.publish_jobs (id) on delete cascade,
  platform text not null,
  external_post_id text,
  permalink text,
  raw_response jsonb,
  published_at timestamptz
);
create index if not exists idx_external_pubs_job on public.external_publications (job_id);

create table if not exists public.analytics_sync_jobs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  connection_id uuid references public.platform_connections (id) on delete set null,
  platform text not null,
  scope text not null default 'post_level',
  status public.analytics_sync_status not null default 'queued',
  started_at timestamptz,
  finished_at timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);
create index if not exists idx_analytics_sync_ws on public.analytics_sync_jobs (workspace_id, created_at);

create table if not exists public.analytics_metric_dimensions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  label text not null,
  description text
);

create table if not exists public.analytics_metric_facts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  time_bucket date not null,
  platform text not null,
  dimension_key text,
  dimension_value text,
  metric_key text not null,
  metric_value double precision,
  source_job_id uuid references public.analytics_sync_jobs (id) on delete set null,
  external_publication_id uuid references public.external_publications (id) on delete set null,
  raw jsonb,
  created_at timestamptz not null default now()
);
create index if not exists idx_analytics_facts_ws_time on public.analytics_metric_facts (workspace_id, time_bucket);

create table if not exists public.geo_metric_facts (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  time_bucket date not null,
  platform text not null,
  country_code text,
  region text,
  metric_key text not null,
  metric_value double precision,
  source_job_id uuid references public.analytics_sync_jobs (id) on delete set null,
  created_at timestamptz not null default now()
);
create index if not exists idx_geo_facts_ws on public.geo_metric_facts (workspace_id, time_bucket);

create table if not exists public.platform_capability_matrix (
  id uuid primary key default gen_random_uuid(),
  platform text not null,
  metric_key text not null,
  is_supported boolean not null,
  ui_label text not null,
  unique (platform, metric_key)
);

drop trigger if exists trg_pc_updated2 on public.platform_connections;
create trigger trg_pc_updated2
  before update on public.platform_connections
  for each row execute function public.set_updated_at();

drop trigger if exists trg_pj_updated2 on public.publish_jobs;
create trigger trg_pj_updated2
  before update on public.publish_jobs
  for each row execute function public.set_updated_at();

-- RLS
alter table public.platform_connections enable row level security;
alter table public.platform_connection_secrets enable row level security;
alter table public.publish_targets enable row level security;
alter table public.publish_jobs enable row level security;
alter table public.publish_job_attempts enable row level security;
alter table public.external_publications enable row level security;
alter table public.analytics_sync_jobs enable row level security;
alter table public.analytics_metric_dimensions enable row level security;
alter table public.analytics_metric_facts enable row level security;
alter table public.geo_metric_facts enable row level security;
alter table public.platform_capability_matrix enable row level security;

-- platform_connections: okuma tüm üyeler; yazma admin+editor
create policy "dist_pc read" on public.platform_connections
  for select using (public.is_workspace_member(workspace_id));
create policy "dist_pc write" on public.platform_connections
  for all using (
    public.is_workspace_member(workspace_id) and
    exists (select 1 from public.workspace_members m
            where m.workspace_id = platform_connections.workspace_id
            and m.user_id = auth.uid() and m.role in ('admin','editor'))
  ) with check (
    public.is_workspace_member(workspace_id) and
    exists (select 1 from public.workspace_members m
            where m.workspace_id = platform_connections.workspace_id
            and m.user_id = auth.uid() and m.role in ('admin','editor'))
  );

-- secrets: istemciye açık politika yok; yalnız service_role

-- publish_targets
create policy "dist_pt read" on public.publish_targets
  for select using (exists (select 1 from public.platform_connections c
    where c.id = publish_targets.connection_id and public.is_workspace_member(c.workspace_id)));
create policy "dist_pt write" on public.publish_targets
  for all using (exists (select 1 from public.platform_connections c
    join public.workspace_members m on m.workspace_id = c.workspace_id and m.user_id = auth.uid()
    where c.id = publish_targets.connection_id and m.role in ('admin','editor')))
  with check (exists (select 1 from public.platform_connections c
    join public.workspace_members m on m.workspace_id = c.workspace_id and m.user_id = auth.uid()
    where c.id = publish_targets.connection_id and m.role in ('admin','editor')));

-- publish_jobs
create policy "dist_pj read" on public.publish_jobs
  for select using (public.is_workspace_member(workspace_id));
create policy "dist_pj write" on public.publish_jobs
  for all using (public.is_workspace_member(workspace_id) and exists (select 1 from public.workspace_members m
    where m.workspace_id = publish_jobs.workspace_id and m.user_id = auth.uid() and m.role in ('admin','editor')))
  with check (public.is_workspace_member(workspace_id) and exists (select 1 from public.workspace_members m
    where m.workspace_id = publish_jobs.workspace_id and m.user_id = auth.uid() and m.role in ('admin','editor')));

-- attempts & external: okuma; yazma yalnız service_role (worker) — kullanıcıya politika yok
create policy "dist_pja read" on public.publish_job_attempts
  for select using (exists (select 1 from public.publish_jobs j
    where j.id = publish_job_attempts.job_id and public.is_workspace_member(j.workspace_id)));
create policy "dist_ep read" on public.external_publications
  for select using (exists (select 1 from public.publish_jobs j
    where j.id = external_publications.job_id and public.is_workspace_member(j.workspace_id)));

create policy "dist_asj read" on public.analytics_sync_jobs
  for select using (public.is_workspace_member(workspace_id));
create policy "dist_amf read" on public.analytics_metric_facts
  for select using (public.is_workspace_member(workspace_id));
create policy "dist_gmf read" on public.geo_metric_facts
  for select using (public.is_workspace_member(workspace_id));
create policy "dist_dim read" on public.analytics_metric_dimensions
  for select to authenticated using (true);
create policy "dist_pcm read" on public.platform_capability_matrix
  for select to authenticated using (true);

-- Seed: yetenek matrisi
insert into public.platform_capability_matrix (platform, metric_key, is_supported, ui_label) values
  ('telegram', 'views', false, 'Görüntülenme (Bot API)'),
  ('telegram', 'reach', false, 'Erişim'),
  ('telegram', 'reactions', false, 'Reaksiyon ayrıntıları'),
  ('vk', 'views', true, 'Görüntülenme (post)'),
  ('vk', 'reach', true, 'Erişim (mümkünse)'),
  ('vk', 'likes', true, 'Beğeni'),
  ('vk', 'comments', true, 'Yorum'),
  ('vk', 'reposts', true, 'Repost'),
  ('mock', 'views', true, 'Mock test')
on conflict (platform, metric_key) do nothing;

insert into public.analytics_metric_dimensions (key, label, description) values
  ('profession', 'Meslek', 'İçerik boyutu'),
  ('meme_style', 'Mim stili', 'Stil etiketi'),
  ('audience', 'Hedef kitle', 'Hedefleme etiketi')
on conflict (key) do nothing;
-- Optional AI provider registry per workspace; secrets only via secret_ref
create table if not exists public.ai_provider_configs (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references public.workspaces (id) on delete cascade,
  provider text not null,
  is_enabled boolean not null default true,
  settings jsonb not null default '{}',
  secret_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (workspace_id, provider)
);
create index if not exists idx_ai_provider_ws on public.ai_provider_configs (workspace_id);

drop trigger if exists trg_aipc_updated on public.ai_provider_configs;
create trigger trg_aipc_updated
  before update on public.ai_provider_configs
  for each row execute function public.set_updated_at();

alter table public.ai_provider_configs enable row level security;

create policy "aipc read" on public.ai_provider_configs
  for select using (public.is_workspace_member(workspace_id));
create policy "aipc write" on public.ai_provider_configs
  for all using (public.is_workspace_member(workspace_id) and exists (select 1 from public.workspace_members m
    where m.workspace_id = ai_provider_configs.workspace_id and m.user_id = auth.uid() and m.role in ('admin','editor')))
  with check (public.is_workspace_member(workspace_id) and exists (select 1 from public.workspace_members m
    where m.workspace_id = ai_provider_configs.workspace_id and m.user_id = auth.uid() and m.role in ('admin','editor')));

grant select, insert, update, delete on public.ai_provider_configs to authenticated;
-- Profil: username + updated_at; yeni kullanıcı trigger meta verisinden username

alter table public.profiles
  add column if not exists username text;

alter table public.profiles
  add column if not exists updated_at timestamptz not null default now();

create unique index if not exists profiles_username_unique
  on public.profiles (lower(username))
  where username is not null and length(trim(username)) > 0;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name, username, updated_at)
  values (
    new.id,
    coalesce(
      nullif(trim(new.raw_user_meta_data->>'display_name'), ''),
      nullif(trim(new.raw_user_meta_data->>'username'), '')
    ),
    nullif(lower(trim(new.raw_user_meta_data->>'username')), ''),
    now()
  );
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

comment on column public.profiles.username is 'Benzersiz (case-insensitive index); uygulama metadata ile doldurur.';
-- Meme brief AI v2: structured generation fields (Russian + image prompts)
alter table public.meme_briefs
  add column if not exists brief_title text,
  add column if not exists meme_insight text,
  add column if not exists short_post_text_ru text,
  add column if not exists visual_concept text,
  add column if not exists image_prompt text,
  add column if not exists negative_prompt text,
  add column if not exists hashtags_ru text;

comment on column public.meme_briefs.brief_title is 'AI: short working title (Russian)';
comment on column public.meme_briefs.meme_insight is 'AI: core meme insight (Russian)';
comment on column public.meme_briefs.short_post_text_ru is 'AI: post body / story text (Russian)';
comment on column public.meme_briefs.visual_concept is 'AI: what should be seen in the image (Russian)';
comment on column public.meme_briefs.image_prompt is 'AI: English prompt for image model';
comment on column public.meme_briefs.negative_prompt is 'AI: what to avoid (appended to prompt for models without native negative)';
comment on column public.meme_briefs.hashtags_ru is 'AI: RU hashtag line';
-- Seed lookup (profession_sources)
-- Örnek lookup: migration sonrası (supabase genelde superuser) çalıştır
insert into public.profession_sources (key, label) values
  ('manual', 'El ile'),
  ('telegram', 'Telegram'),
  ('imported', 'İçe aktarma')
  on conflict (key) do nothing;
