-- =====================================================================
-- G.R. BOOK — SUPABASE SCHEMA
-- Multi-school-ready from day one; first deployment is single-school
-- (Govt Boys Primary School Mehar Ghanghro) but every table is scoped
-- by school_id so additional schools can be onboarded without a
-- schema change.
-- =====================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- PROFILES  (1:1 with auth.users)
-- ---------------------------------------------------------------------
create table public.profiles (
    id uuid primary key references auth.users (id) on delete cascade,
    full_name text not null,
    mobile_number text not null unique,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.profiles is 'Extends auth.users with app-specific identity fields. Auth itself (password hashing/session) is fully handled by Supabase Auth — never store passwords here.';

-- ---------------------------------------------------------------------
-- SCHOOLS
-- ---------------------------------------------------------------------
create table public.schools (
    id uuid primary key default uuid_generate_v4(),
    school_name text not null,
    semis_code text,
    uc text,
    taluka text,
    district text,
    created_by uuid not null references public.profiles (id),
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

-- ---------------------------------------------------------------------
-- SCHOOL MEMBERS  (join table: which users can access which school)
-- ---------------------------------------------------------------------
create type public.school_role as enum ('owner', 'admin', 'teacher');

create table public.school_members (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    profile_id uuid not null references public.profiles (id) on delete cascade,
    role public.school_role not null default 'teacher',
    created_at timestamptz not null default now(),
    unique (school_id, profile_id)
);

create index idx_school_members_profile on public.school_members (profile_id);
create index idx_school_members_school on public.school_members (school_id);

-- ---------------------------------------------------------------------
-- CLASSES  (configurable per school — not hard-coded)
-- ---------------------------------------------------------------------
create table public.classes (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    class_code text not null,        -- e.g. 'ECE','1','2','3','4','5'
    display_name text not null,      -- e.g. 'ECE','Class 1'
    sort_order int not null default 0,
    -- Configurable promotion/admission rules per class, editable via Settings
    -- rather than hard-coded in application logic.
    min_admission_age_months int,        -- e.g. ECE = 36 months (3 years)
    min_promotion_age_months int,        -- e.g. ECE->1 = 61 months (5y1m)
    promotes_to_class_id uuid references public.classes (id),
    is_terminal boolean not null default false, -- true for Class 5 (-> pass out)
    is_active boolean not null default true,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    unique (school_id, class_code)
);

create index idx_classes_school on public.classes (school_id);

-- ---------------------------------------------------------------------
-- STUDENTS
-- ---------------------------------------------------------------------
create type public.student_status as enum ('ACTIVE', 'STRUCK_OFF', 'PASSED_OUT');
create type public.promotion_status as enum ('NONE', 'PROMOTED', 'FAILED');

create table public.students (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    class_id uuid not null references public.classes (id),

    gr_number text not null,             -- user-entered, duplicates allowed w/ warning
    serial_number bigint not null,       -- auto, generated via sequence-per-school (see below)

    student_name text not null,
    father_name text,
    mother_name text,
    date_of_birth date not null,
    date_of_admission date not null,
    father_cnic text,
    b_form_number text,
    phone_number text,
    address text,
    previous_school text,
    remarks text,

    status public.student_status not null default 'ACTIVE',
    promotion_status public.promotion_status not null default 'NONE',

    struck_off_date date,
    struck_off_reason text,

    pass_out_year int,

    -- sync / conflict metadata
    client_generated_id uuid not null,   -- id assigned offline before first sync
    version int not null default 1,
    updated_at timestamptz not null default now(),
    created_at timestamptz not null default now(),
    created_by uuid references public.profiles (id),
    updated_by uuid references public.profiles (id),

    is_deleted boolean not null default false  -- soft-delete only; never hard delete
);

create index idx_students_school on public.students (school_id);
create index idx_students_class on public.students (class_id);
create index idx_students_gr on public.students (school_id, gr_number);
create index idx_students_name on public.students using gin (to_tsvector('simple', student_name));
create index idx_students_status on public.students (status);
create index idx_students_dob on public.students (date_of_birth);
create index idx_students_updated on public.students (updated_at);
create unique index idx_students_client_id on public.students (school_id, client_generated_id);

-- Per-school serial number sequence, allocated safely to avoid
-- offline-sync collisions: serial numbers are reserved server-side
-- via the next_serial_number() function below rather than computed
-- client-side from "count of existing rows".
create table public.school_serial_counters (
    school_id uuid primary key references public.schools (id) on delete cascade,
    last_serial bigint not null default 0
);

create or replace function public.next_serial_number(p_school_id uuid)
returns bigint
language plpgsql
security definer
as $$
declare
    v_next bigint;
begin
    insert into public.school_serial_counters (school_id, last_serial)
    values (p_school_id, 1)
    on conflict (school_id) do update
        set last_serial = public.school_serial_counters.last_serial + 1
    returning last_serial into v_next;
    return v_next;
end;
$$;

-- ---------------------------------------------------------------------
-- STUDENT PHOTOS (4 categories per student)
-- ---------------------------------------------------------------------
create type public.photo_type as enum ('STUDENT', 'B_FORM', 'FATHER_CNIC', 'TOKEN');

create table public.student_photos (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    student_id uuid not null references public.students (id) on delete cascade,
    photo_type public.photo_type not null,
    storage_path text not null,         -- path within private 'student-photos' bucket
    version int not null default 1,
    uploaded_by uuid references public.profiles (id),
    created_at timestamptz not null default now(),
    is_deleted boolean not null default false,
    unique (student_id, photo_type, version)
);

create index idx_student_photos_student on public.student_photos (student_id);

-- ---------------------------------------------------------------------
-- PROMOTION BATCHES + RECORDS  (undo-able, fully audited)
-- ---------------------------------------------------------------------
create table public.promotion_batches (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    from_class_id uuid not null references public.classes (id),
    to_class_id uuid references public.classes (id),  -- null when result is PASSED_OUT
    promotion_date date not null,
    academic_year int not null,
    performed_by uuid references public.profiles (id),
    is_undone boolean not null default false,
    undone_at timestamptz,
    undone_by uuid references public.profiles (id),
    created_at timestamptz not null default now()
);

create index idx_promo_batch_school on public.promotion_batches (school_id);

create table public.promotion_records (
    id uuid primary key default uuid_generate_v4(),
    batch_id uuid not null references public.promotion_batches (id) on delete cascade,
    student_id uuid not null references public.students (id),
    previous_class_id uuid not null references public.classes (id),
    new_class_id uuid references public.classes (id),
    previous_status public.student_status not null,
    new_status public.student_status not null,
    result public.promotion_status not null,  -- PROMOTED or FAILED
    academic_year int not null,
    created_at timestamptz not null default now()
);

create index idx_promo_record_batch on public.promotion_records (batch_id);
create index idx_promo_record_student on public.promotion_records (student_id);

-- ---------------------------------------------------------------------
-- PASS OUT RECORDS
-- ---------------------------------------------------------------------
create table public.pass_out_records (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    student_id uuid not null references public.students (id),
    pass_out_year int not null,
    pass_out_date date not null,
    promotion_batch_id uuid references public.promotion_batches (id),
    created_at timestamptz not null default now()
);

create index idx_passout_school_year on public.pass_out_records (school_id, pass_out_year);

-- ---------------------------------------------------------------------
-- STRUCK OFF RECORDS  (re-admission preserves history, never deletes it)
-- ---------------------------------------------------------------------
create table public.struck_off_records (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    student_id uuid not null references public.students (id),
    struck_off_date date not null,
    reason text not null,
    re_admitted boolean not null default false,
    re_admitted_date date,
    re_admitted_by uuid references public.profiles (id),
    created_by uuid references public.profiles (id),
    created_at timestamptz not null default now()
);

create index idx_struckoff_school on public.struck_off_records (school_id);
create index idx_struckoff_student on public.struck_off_records (student_id);

-- ---------------------------------------------------------------------
-- AUDIT LOGS  (append-only; users cannot edit or delete)
-- ---------------------------------------------------------------------
create table public.audit_logs (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    user_id uuid references public.profiles (id),
    student_id uuid references public.students (id),
    action text not null,          -- e.g. 'STUDENT_CREATED','PROMOTION_UNDONE'
    old_value jsonb,
    new_value jsonb,
    device_info text,
    created_at timestamptz not null default now()
);

create index idx_audit_school on public.audit_logs (school_id);
create index idx_audit_student on public.audit_logs (student_id);
create index idx_audit_created on public.audit_logs (created_at);

-- ---------------------------------------------------------------------
-- BACKUP METADATA  (tracks Google-Drive backups; never stores secrets)
-- ---------------------------------------------------------------------
create table public.backup_metadata (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    drive_file_id text not null,
    backup_type text not null default 'FULL',  -- FULL | INCREMENTAL
    size_bytes bigint,
    created_by uuid references public.profiles (id),
    created_at timestamptz not null default now()
);

create index idx_backup_school on public.backup_metadata (school_id);

-- ---------------------------------------------------------------------
-- updated_at auto-touch trigger (used for optimistic concurrency)
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
    new.updated_at = now();
    if TG_TABLE_NAME = 'students' then
        new.version = coalesce(old.version, 1) + 1;
    end if;
    return new;
end;
$$;

create trigger trg_students_touch before update on public.students
    for each row execute function public.touch_updated_at();
create trigger trg_schools_touch before update on public.schools
    for each row execute function public.touch_updated_at();
create trigger trg_classes_touch before update on public.classes
    for each row execute function public.touch_updated_at();
