create extension if not exists "pgcrypto" with schema extensions;

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  email text not null,
  linkedin_url text,
  tiktok_handle text,
  resume_url text,
  video_url text
);

create unique index if not exists waitlist_email_lower_key
  on public.waitlist (lower(email));

alter table public.waitlist enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'waitlist'
      and policyname = 'Allow anon inserts'
  ) then
    create policy "Allow anon inserts"
      on public.waitlist
      for insert
      to anon
      with check (true);
  end if;
end
$$;

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
select
  'resumes',
  'resumes',
  true,
  10485760,
  array[
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]::text[]
where not exists (
  select 1
  from storage.buckets
  where id = 'resumes'
);

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
select
  'videos',
  'videos',
  true,
  209715200,
  array[
    'video/mp4',
    'video/quicktime',
    'video/webm'
  ]::text[]
where not exists (
  select 1
  from storage.buckets
  where id = 'videos'
);

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow anon uploads to resumes'
  ) then
    create policy "Allow anon uploads to resumes"
      on storage.objects
      for insert
      to anon
      with check (bucket_id = 'resumes');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow public read of resumes'
  ) then
    create policy "Allow public read of resumes"
      on storage.objects
      for select
      to public
      using (bucket_id = 'resumes');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow anon uploads to videos'
  ) then
    create policy "Allow anon uploads to videos"
      on storage.objects
      for insert
      to anon
      with check (bucket_id = 'videos');
  end if;

  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname = 'Allow public read of videos'
  ) then
    create policy "Allow public read of videos"
      on storage.objects
      for select
      to public
      using (bucket_id = 'videos');
  end if;
end
$$;
