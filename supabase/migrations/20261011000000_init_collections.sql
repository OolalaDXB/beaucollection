-- Beau Collection — schéma initial (projet Supabase ffmvwzkvkzgdgejdtfyu)
-- Utilisé par index.html, asterix.html, mortelle-adele.html, tomtom-nana.html :
--   from('collections').select('series,data').eq('user_id', ...)
--   from('collections').upsert({user_id, series, data}, {onConflict: 'user_id,series'})
-- Le profil (first_name, alias, language, active_collections, show_prices)
-- est stocké dans auth.users.raw_user_meta_data via auth.updateUser().

create table public.collections (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  series      text not null,
  data        jsonb not null default '{}'::jsonb,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  constraint collections_user_series_key unique (user_id, series)
);

comment on table public.collections is
  'Une ligne par utilisateur et par série (asterix, mortelle-adele, tomtom-nana, ...). data = {collection, wishlist, ..., savedAt}';

-- Sécurité (RLS) : chaque utilisateur ne voit / modifie que ses lignes
alter table public.collections enable row level security;

create policy "collections_select_own" on public.collections
  for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "collections_insert_own" on public.collections
  for insert to authenticated
  with check ((select auth.uid()) = user_id);

create policy "collections_update_own" on public.collections
  for update to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

create policy "collections_delete_own" on public.collections
  for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Accès Data API
revoke all on public.collections from anon;
revoke all on public.collections from authenticated;
grant select, insert, update, delete on public.collections to authenticated;

-- updated_at automatique
create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

create trigger collections_set_updated_at
  before update on public.collections
  for each row execute function public.set_updated_at();
