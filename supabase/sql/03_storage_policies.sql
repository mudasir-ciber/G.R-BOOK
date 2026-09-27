-- =====================================================================
-- G.R. BOOK — STORAGE (private buckets, signed-URL access only)
-- =====================================================================

-- Create the private bucket for all student-related images. Public
-- access is disabled — the app must fetch images via
-- createSignedUrl(), never a public URL.
insert into storage.buckets (id, name, public)
values ('student-photos', 'student-photos', false)
on conflict (id) do nothing;

-- Object path convention enforced by the app:
--   student-photos/{school_id}/{student_id}/{photo_type}_{version}.jpg
-- Policies below parse school_id out of the path's first folder segment
-- and check it against school_members.

create policy "student_photos_select_member"
on storage.objects for select
using (
    bucket_id = 'student-photos'
    and public.is_school_member((storage.foldername(name))[1]::uuid)
);

create policy "student_photos_insert_member"
on storage.objects for insert
with check (
    bucket_id = 'student-photos'
    and public.is_school_member((storage.foldername(name))[1]::uuid)
);

create policy "student_photos_update_member"
on storage.objects for update
using (
    bucket_id = 'student-photos'
    and public.is_school_member((storage.foldername(name))[1]::uuid)
);

-- No delete policy: old photo versions are retained (versioned via the
-- student_photos.version column) rather than deleted from storage,
-- consistent with "never destroy historical information".
