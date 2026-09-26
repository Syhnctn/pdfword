create extension if not exists "pgcrypto";

insert into storage.buckets (id, name, public)
values ('ocr-inputs', 'ocr-inputs', false)
on conflict (id) do nothing;

insert into storage.buckets (id, name, public)
values ('ocr-results', 'ocr-results', false)
on conflict (id) do nothing;

create table if not exists public.ocr_jobs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null,
  device_id_hash text null,
  source text not null default 'flutter_app',
  status text not null default 'queued',
  progress_pct integer not null default 0,
  error_code text null,
  error_message text null,
  input_meta jsonb not null default '[]'::jsonb,
  output_md_path text null,
  output_docx_path text null,
  total_size_mb numeric(10,2) not null default 0,
  created_at timestamptz not null default now(),
  started_at timestamptz null,
  finished_at timestamptz null,
  expires_at timestamptz not null default now() + interval '1 hour'
);

create index if not exists idx_ocr_jobs_created_at on public.ocr_jobs(created_at desc);
create index if not exists idx_ocr_jobs_status on public.ocr_jobs(status);
create index if not exists idx_ocr_jobs_user_id on public.ocr_jobs(user_id);

create table if not exists public.daily_usage (
  id uuid primary key default gen_random_uuid(),
  user_id uuid null,
  device_id_hash text null,
  usage_date date not null default current_date,
  docs_used integer not null default 0,
  created_at timestamptz not null default now()
);

create unique index if not exists uq_daily_usage_user_day
  on public.daily_usage((coalesce(user_id::text, 'anon')), usage_date);

alter table public.ocr_jobs enable row level security;
alter table public.daily_usage enable row level security;

drop policy if exists "ocr_jobs_owner_select" on public.ocr_jobs;
create policy "ocr_jobs_owner_select"
  on public.ocr_jobs
  for select
  to authenticated
  using (auth.uid() = user_id);

drop policy if exists "ocr_jobs_owner_insert" on public.ocr_jobs;
create policy "ocr_jobs_owner_insert"
  on public.ocr_jobs
  for insert
  to authenticated
  with check (auth.uid() = user_id);

drop policy if exists "daily_usage_owner_select" on public.daily_usage;
create policy "daily_usage_owner_select"
  on public.daily_usage
  for select
  to authenticated
  using (auth.uid() = user_id);
