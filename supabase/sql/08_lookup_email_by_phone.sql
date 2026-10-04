-- =====================================================================
-- Phase 13: Resolve Login Email by Phone Number
-- Allows users who registered with both Email and Mobile Number to log in
-- using either their Email Address or their Pakistani Mobile Number.
-- =====================================================================

create or replace function public.lookup_email_by_phone(phone_input text)
returns text
security definer
set search_path = public
as $$
declare
    clean_phone text;
    found_email text;
begin
    clean_phone := regexp_replace(phone_input, '[^0-9]', '', 'g');

    -- Search for matching profile by exact or normalized mobile number
    select email into found_email
    from public.profiles
    where email is not null
      and email <> ''
      and (
        mobile_number = clean_phone
        or mobile_number = ('92' || substring(clean_phone from 2))
        or mobile_number = ('0' || substring(clean_phone from 3))
        or mobile_number = replace(clean_phone, '92', '0')
      )
    limit 1;

    return found_email;
end;
$$ language plpgsql;

-- Grant execution to public / anon so users can look up their login email before authentication
grant execute on function public.lookup_email_by_phone(text) to anon, authenticated;
