-- =====================================================================
-- Phase 6 addition: pass_out_years
-- Lets a year be added to the Pass Out Years screen before any student
-- has actually passed out into it yet (requirement #20's "Add New
-- Year"). Run this after 01-04.
-- =====================================================================

create table public.pass_out_years (
    id uuid primary key default uuid_generate_v4(),
    school_id uuid not null references public.schools (id) on delete cascade,
    year int not null,
    created_at timestamptz not null default now(),
    unique (school_id, year)
);

create index idx_pass_out_years_school on public.pass_out_years (school_id);

alter table public.pass_out_years enable row level security;

create policy pass_out_years_select on public.pass_out_years
    for select using (public.is_school_member(school_id));
create policy pass_out_years_insert on public.pass_out_years
    for insert with check (public.is_school_member(school_id));
