create extension if not exists "pgcrypto" with schema extensions;

create table if not exists public.waitlist (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  name text not null,
  email text not null
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
