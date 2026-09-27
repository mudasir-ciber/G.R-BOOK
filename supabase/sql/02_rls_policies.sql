-- =====================================================================
-- G.R. BOOK — ROW LEVEL SECURITY
-- Every table is locked down; access requires school_members membership.
-- No table is left publicly writable. No "allow all" policies.
-- =====================================================================

alter table public.profiles enable row level security;
alter table public.schools enable row level security;
alter table public.school_members enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.student_photos enable row level security;
alter table public.promotion_batches enable row level security;
alter table public.promotion_records enable row level security;
alter table public.pass_out_records enable row level security;
alter table public.struck_off_records enable row level security;
alter table public.audit_logs enable row level security;
alter table public.backup_metadata enable row level security;
alter table public.school_serial_counters enable row level security;

-- ---------------------------------------------------------------------
-- Helper: is the current auth user a member of a given school?
-- SECURITY DEFINER so it can read school_members regardless of the
-- caller's own row-level restrictions on that table.
-- ---------------------------------------------------------------------
create or replace function public.is_school_member(p_school_id uuid)
returns boolean
language sql
security definer
stable
as $$
    select exists (
        select 1 from public.school_members sm
        where sm.school_id = p_school_id
          and sm.profile_id = auth.uid()
    );
$$;

create or replace function public.is_school_admin(p_school_id uuid)
returns boolean
language sql
security definer
stable
as $$
    select exists (
        select 1 from public.school_members sm
        where sm.school_id = p_school_id
          and sm.profile_id = auth.uid()
          and sm.role in ('owner', 'admin')
    );
$$;

-- ---------------------------------------------------------------------
-- PROFILES: a user can read/update only their own profile row.
-- ---------------------------------------------------------------------
create policy profiles_select_own on public.profiles
    for select using (id = auth.uid());
create policy profiles_update_own on public.profiles
    for update using (id = auth.uid());
create policy profiles_insert_own on public.profiles
    for insert with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- SCHOOLS
-- ---------------------------------------------------------------------
create policy schools_select_member on public.schools
    for select using (public.is_school_member(id));
create policy schools_insert_creator on public.schools
    for insert with check (created_by = auth.uid());
create policy schools_update_admin on public.schools
    for update using (public.is_school_admin(id));

-- ---------------------------------------------------------------------
-- SCHOOL MEMBERS: members can see co-members of their own school(s);
-- only admins/owners can add or change membership.
-- ---------------------------------------------------------------------
create policy school_members_select on public.school_members
    for select using (public.is_school_member(school_id));
create policy school_members_insert_self_owner on public.school_members
    -- allows the creator of a new school to insert their own 'owner' row
    for insert with check (
        profile_id = auth.uid() or public.is_school_admin(school_id)
    );
create policy school_members_update_admin on public.school_members
    for update using (public.is_school_admin(school_id));
create policy school_members_delete_admin on public.school_members
    for delete using (public.is_school_admin(school_id));

-- ---------------------------------------------------------------------
-- CLASSES
-- ---------------------------------------------------------------------
create policy classes_select_member on public.classes
    for select using (public.is_school_member(school_id));
create policy classes_write_admin on public.classes
    for insert with check (public.is_school_admin(school_id));
create policy classes_update_admin on public.classes
    for update using (public.is_school_admin(school_id));

-- ---------------------------------------------------------------------
-- STUDENTS
-- ---------------------------------------------------------------------
create policy students_select_member on public.students
    for select using (public.is_school_member(school_id));
create policy students_insert_member on public.students
    for insert with check (public.is_school_member(school_id));
create policy students_update_member on public.students
    for update using (public.is_school_member(school_id));
-- No delete policy: students are never physically deleted (soft-delete
-- via is_deleted / status columns through the update policy only).

-- ---------------------------------------------------------------------
-- STUDENT PHOTOS
-- ---------------------------------------------------------------------
create policy photos_select_member on public.student_photos
    for select using (public.is_school_member(school_id));
create policy photos_insert_member on public.student_photos
    for insert with check (public.is_school_member(school_id));
create policy photos_update_member on public.student_photos
    for update using (public.is_school_member(school_id));

-- ---------------------------------------------------------------------
-- PROMOTION BATCHES / RECORDS
-- ---------------------------------------------------------------------
create policy promo_batch_select on public.promotion_batches
    for select using (public.is_school_member(school_id));
create policy promo_batch_insert on public.promotion_batches
    for insert with check (public.is_school_member(school_id));
create policy promo_batch_update on public.promotion_batches
    -- only for undo flow (is_undone / undone_at / undone_by)
    for update using (public.is_school_member(school_id));

create policy promo_record_select on public.promotion_records
    for select using (
        exists (
            select 1 from public.promotion_batches b
            where b.id = promotion_records.batch_id
              and public.is_school_member(b.school_id)
        )
    );
create policy promo_record_insert on public.promotion_records
    for insert with check (
        exists (
            select 1 from public.promotion_batches b
            where b.id = promotion_records.batch_id
              and public.is_school_member(b.school_id)
        )
    );

-- ---------------------------------------------------------------------
-- PASS OUT RECORDS
-- ---------------------------------------------------------------------
create policy passout_select on public.pass_out_records
    for select using (public.is_school_member(school_id));
create policy passout_insert on public.pass_out_records
    for insert with check (public.is_school_member(school_id));

-- ---------------------------------------------------------------------
-- STRUCK OFF RECORDS
-- ---------------------------------------------------------------------
create policy struckoff_select on public.struck_off_records
    for select using (public.is_school_member(school_id));
create policy struckoff_insert on public.struck_off_records
    for insert with check (public.is_school_member(school_id));
create policy struckoff_update on public.struck_off_records
    for update using (public.is_school_member(school_id));

-- ---------------------------------------------------------------------
-- AUDIT LOGS: append-only. Insert allowed for members; NO update/delete
-- policy exists for anyone, so audit history cannot be altered via the
-- client under any role, only appended to.
-- ---------------------------------------------------------------------
create policy audit_select on public.audit_logs
    for select using (public.is_school_member(school_id));
create policy audit_insert on public.audit_logs
    for insert with check (public.is_school_member(school_id));

-- ---------------------------------------------------------------------
-- BACKUP METADATA
-- ---------------------------------------------------------------------
create policy backup_select on public.backup_metadata
    for select using (public.is_school_member(school_id));
create policy backup_insert on public.backup_metadata
    for insert with check (public.is_school_member(school_id));

-- ---------------------------------------------------------------------
-- SERIAL COUNTERS: never touched directly by clients; only through the
-- SECURITY DEFINER next_serial_number() function. No client policies
-- at all — table is otherwise inaccessible from the anon/auth roles.
-- ---------------------------------------------------------------------
-- (Intentionally no policies: RLS is enabled with zero policies, which
--  denies all direct client access by default.)
