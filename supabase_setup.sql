-- Paste this whole file into Supabase -> SQL Editor -> New query -> Run.

create table public.items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  type text not null check (type in ('lost', 'found')),
  title text not null,
  description text not null default '',
  category text not null default 'Other',
  location text not null default '',
  photo_url text,
  status text not null default 'open' check (status in ('open', 'recovered')),
  contact_name text not null,
  contact_phone text,
  contact_email text,
  created_at timestamptz not null default now()
);

create index items_created_at_idx on public.items (created_at desc);
create index items_user_idx on public.items (user_id);

alter table public.items enable row level security;

-- Any signed-in user can browse reports
create policy "Signed-in users can view items"
  on public.items for select to authenticated using (true);

-- Users can only create / change / delete their own reports
create policy "Users insert own items"
  on public.items for insert to authenticated with check (auth.uid() = user_id);

create policy "Users update own items"
  on public.items for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "Users delete own items"
  on public.items for delete to authenticated using (auth.uid() = user_id);

-- Photo storage bucket (public read so images load in the app)
insert into storage.buckets (id, name, public)
values ('item-photos', 'item-photos', true)
on conflict (id) do nothing;

create policy "Public can read item photos"
  on storage.objects for select using (bucket_id = 'item-photos');

create policy "Signed-in users can upload item photos"
  on storage.objects for insert to authenticated with check (bucket_id = 'item-photos');
