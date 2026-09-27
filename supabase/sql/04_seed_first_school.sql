-- =====================================================================
-- Seed: Govt Boys Primary School Mehar Ghanghro
-- Run this ONCE after the first user account is created, replacing
-- :owner_profile_id with that user's auth.users.id (uuid).
-- =====================================================================

do $$
declare
    v_school_id uuid;
    v_owner_id uuid := :'owner_profile_id';  -- pass via psql -v owner_profile_id='...'
    v_ece uuid;
    v_c1 uuid;
    v_c2 uuid;
    v_c3 uuid;
    v_c4 uuid;
    v_c5 uuid;
begin
    insert into public.schools (school_name, semis_code, uc, taluka, district, created_by)
    values ('Govt Boys Primary School Mehar Ghanghro', null, null, null, null, v_owner_id)
    returning id into v_school_id;

    insert into public.school_members (school_id, profile_id, role)
    values (v_school_id, v_owner_id, 'owner');

    insert into public.classes (school_id, class_code, display_name, sort_order, min_admission_age_months)
    values (v_school_id, 'ECE', 'ECE', 0, 36)   -- 3 years minimum admission age
    returning id into v_ece;

    insert into public.classes (school_id, class_code, display_name, sort_order)
    values (v_school_id, '1', 'Class 1', 1) returning id into v_c1;
    insert into public.classes (school_id, class_code, display_name, sort_order)
    values (v_school_id, '2', 'Class 2', 2) returning id into v_c2;
    insert into public.classes (school_id, class_code, display_name, sort_order)
    values (v_school_id, '3', 'Class 3', 3) returning id into v_c3;
    insert into public.classes (school_id, class_code, display_name, sort_order)
    values (v_school_id, '4', 'Class 4', 4) returning id into v_c4;
    insert into public.classes (school_id, class_code, display_name, sort_order, is_terminal)
    values (v_school_id, '5', 'Class 5', 5, true) returning id into v_c5;

    -- Promotion chain + ECE->1 age rule (5 years 1 month = 61 months)
    update public.classes set promotes_to_class_id = v_c1, min_promotion_age_months = 61 where id = v_ece;
    update public.classes set promotes_to_class_id = v_c2 where id = v_c1;
    update public.classes set promotes_to_class_id = v_c3 where id = v_c2;
    update public.classes set promotes_to_class_id = v_c4 where id = v_c3;
    update public.classes set promotes_to_class_id = v_c5 where id = v_c4;
    -- Class 5 has no promotes_to_class_id — its is_terminal flag routes to Pass Out.
end $$;
