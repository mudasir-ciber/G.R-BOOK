-- =====================================================================
-- Phase 11: Master Admin & User Access Control System
-- Allows Founder (Mudasir Ahmed) to approve new accounts, grant access,
-- and suspend/reactivate any school account.
-- =====================================================================

-- 1. Add email, role, status, and school_name to public.profiles
alter table public.profiles add column if not exists email text;
alter table public.profiles add column if not exists role text not null default 'principal';
alter table public.profiles add column if not exists status text not null default 'pending';
alter table public.profiles add column if not exists school_name text;
alter table public.profiles add column if not exists approved_at timestamptz;

-- Index for fast status and role querying
create index if not exists idx_profiles_status on public.profiles (status);
create index if not exists idx_profiles_role on public.profiles (role);

-- 2. Pre-seed / Upgrade Mudasir Ahmed Ghanghro as Super Admin
update public.profiles
set 
    full_name = 'Mudasir Ahmed',
    email = 'mudasirghanghro25@gmail.com',
    role = 'super_admin',
    status = 'active',
    school_name = 'Admin'
where mobile_number in ('923368456907', '03368456907', '+923368456907')
   or email = 'mudasirghanghro25@gmail.com';

-- 3. Helper: check if the authenticated user is super_admin
create or replace function public.is_super_admin()
returns boolean as $$
begin
    return exists (
        select 1 from public.profiles
        where id = auth.uid()
          and (
            role = 'super_admin'
            or mobile_number in ('923368456907', '03368456907', '+923368456907')
            or email = 'mudasirghanghro25@gmail.com'
          )
    );
end;
$$ language plpgsql security definer;

-- 4. RLS policies for Super Admin on profiles
drop policy if exists profiles_super_admin_select on public.profiles;
create policy profiles_super_admin_select on public.profiles
    for select using (public.is_super_admin());

drop policy if exists profiles_super_admin_update on public.profiles;
create policy profiles_super_admin_update on public.profiles
    for update using (public.is_super_admin());

-- 5. Trigger: Ensure any public signup cannot self-assign super_admin role
create or replace function public.handle_new_user_profile()
returns trigger as $$
declare
    user_contact text;
    user_mobile text;
    user_email text;
    is_master boolean;
begin
    user_mobile := coalesce(new.raw_user_meta_data->>'mobile_number', '');
    user_email := coalesce(new.email, '');

    -- Check if this is Founder Mudasir Ahmed
    is_master := (
        user_email = 'mudasirghanghro25@gmail.com'
        or user_mobile in ('923368456907', '03368456907', '+923368456907')
    );

    insert into public.profiles (id, full_name, mobile_number, email, role, status, school_name)
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'full_name', 'Principal'),
        case when user_mobile <> '' then user_mobile else split_part(user_email, '@', 1) end,
        user_email,
        case when is_master then 'super_admin' else 'principal' end,
        case when is_master then 'active' else 'pending' end,
        case when is_master then 'Admin' else coalesce(new.raw_user_meta_data->>'school_name', '') end
    )
    on conflict (id) do update set
        role = case when is_master then 'super_admin' else public.profiles.role end,
        status = case when is_master then 'active' else public.profiles.status end,
        email = coalesce(excluded.email, public.profiles.email);

    return new;
end;
$$ language plpgsql security definer;

-- Attach trigger to auth.users for automatic profile creation on signup
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user_profile();

