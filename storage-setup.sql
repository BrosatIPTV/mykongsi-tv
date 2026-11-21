-- MYKONGSI TV STORAGE SETUP
-- Jalankan sekali di Supabase SQL Editor selepas jadual asas siap.

insert into storage.buckets (id, name, public)
values ('channel-logos', 'channel-logos', true)
on conflict (id) do nothing;

drop policy if exists "Public can view channel logos" on storage.objects;
create policy "Public can view channel logos"
on storage.objects for select
to anon, authenticated
using (bucket_id = 'channel-logos');

drop policy if exists "Admins can upload channel logos" on storage.objects;
create policy "Admins can upload channel logos"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'channel-logos'
  and exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  )
);

drop policy if exists "Admins can update channel logos" on storage.objects;
create policy "Admins can update channel logos"
on storage.objects for update
to authenticated
using (
  bucket_id = 'channel-logos'
  and exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  )
)
with check (
  bucket_id = 'channel-logos'
  and exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  )
);

drop policy if exists "Admins can delete channel logos" on storage.objects;
create policy "Admins can delete channel logos"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'channel-logos'
  and exists (
    select 1 from public.admin_users
    where user_id = auth.uid()
  )
);
