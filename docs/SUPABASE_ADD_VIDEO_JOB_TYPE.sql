-- Sora video jobs için ai_generation_jobs.job_type kısıtını genişlet.
-- Supabase Dashboard → SQL Editor → yapıştır → Run.

alter table public.ai_generation_jobs
  drop constraint if exists ai_generation_jobs_job_type_check;

alter table public.ai_generation_jobs
  add constraint ai_generation_jobs_job_type_check
  check (job_type in ('brief_batch', 'image', 'text', 'video'));
