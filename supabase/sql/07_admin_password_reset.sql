-- =====================================================================
-- Phase 12: Master Admin Password Reset Function
-- Allows Super Admin (Mudasir Ahmed) to reset password for any user account
-- =====================================================================

create extension if not exists pgcrypto with schema extensions;

create or replace function public.admin_reset_user_password(
    target_user_id uuid,
    new_password text
)
returns boolean
security definer
set search_path = public, auth, extensions
as $$
declare
    caller_is_super boolean;
begin
    -- 1. Verify that the caller is Super Admin
    select (
        role = 'super_admin'
        or mobile_number in ('923368456907', '03368456907', '+923368456907')
        or email = 'mudasirghanghro25@gmail.com'
    ) into caller_is_super
    from public.profiles
    where id = auth.uid();

    if coalesce(caller_is_super, false) is false then
        raise exception 'Unauthorized: Only Super Admin can reset user passwords.';
    end if;

    -- 2. Validate password length
    if length(new_password) < 6 then
        raise exception 'Password must be at least 6 characters long.';
    end if;

    -- 3. Update encrypted_password in auth.users using bcrypt (pgcrypto)
    update auth.users
    set encrypted_password = extensions.crypt(new_password, extensions.gen_salt('bf')),
        updated_at = now()
    where id = target_user_id;

    return true;
end;
$$ language plpgsql;

-- Grant execution to authenticated users (function self-checks super_admin role)
grant execute on function public.admin_reset_user_password(uuid, text) to authenticated;

notify pgrst, 'reload schema';
