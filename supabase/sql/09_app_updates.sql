-- ==============================================================================
-- 09_app_updates.sql
-- G.R. BOOK In-App Automatic Updates Schema & Security Policies
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.app_updates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version_name TEXT NOT NULL,                  -- e.g. '1.0.1'
    version_code INT NOT NULL,                   -- e.g. 6 (incrementing build number)
    apk_url TEXT NOT NULL,                       -- Direct download URL for the APK
    apk_size_mb NUMERIC(5, 2) DEFAULT 99.30,     -- e.g. 99.30
    release_notes TEXT,                          -- Human-readable description of what changed
    is_mandatory BOOLEAN DEFAULT FALSE,          -- If true, forces update before using app
    is_active BOOLEAN DEFAULT TRUE,              -- Toggle to activate or disable this release
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.app_updates ENABLE ROW LEVEL SECURITY;

-- 1. Anyone (including unauthenticated or pending users) can read active updates
DROP POLICY IF EXISTS "Allow public read access to active app updates" ON public.app_updates;
CREATE POLICY "Allow public read access to active app updates"
    ON public.app_updates
    FOR SELECT
    USING (is_active = true);

-- 2. Authenticated users / admins can insert or update rows
DROP POLICY IF EXISTS "Allow authenticated management of app updates" ON public.app_updates;
CREATE POLICY "Allow authenticated management of app updates"
    ON public.app_updates
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Insert initial placeholder entry (for version 1.0.0, build 5)
INSERT INTO public.app_updates (version_name, version_code, apk_url, apk_size_mb, release_notes, is_mandatory, is_active)
VALUES (
    '1.0.0',
    5,
    'https://raw.githubusercontent.com/grbook/releases/main/app-release.apk',
    99.29,
    'Initial release of G.R. BOOK School Management System with full offline register & Google Drive backup support.',
    false,
    true
)
ON CONFLICT DO NOTHING;
