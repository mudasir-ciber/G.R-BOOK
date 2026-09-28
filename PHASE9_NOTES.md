# Phase 9 — Backup, Excel Import/Export, PDF, Certificates (standalone package)

Only files added or changed in Phase 9. Drop into your existing
`grbook/` project at the same relative paths.

## New files
- `lib/services/google_drive_backup_service.dart` — backup / list /
  restore via Drive (`drive.file` scope only).
- `lib/services/backup_preferences.dart` — auto-backup toggle + last
  backup time (no secrets).
- `lib/services/excel_export_service.dart`
- `lib/services/excel_import_service.dart` — header-name column
  matching + full per-row validation, preview only (saves nothing).
- `lib/services/pdf_export_service.dart` — register, age report,
  student profile, and the three certificate templates.
- `lib/providers/backup_providers.dart`, `data_tools_providers.dart`
- `lib/features/settings/backup_restore_screen.dart`
- `lib/features/settings/export_print_screen.dart`
- `lib/features/data_tools/excel_import_screen.dart`
- `lib/features/students/certificate_screen.dart`

## Modified files (overwrite the Phase 8 versions)
- `lib/services/sync_coordinator.dart` — foreground-triggered
  automatic backup check on launch.
- `lib/repositories/student_repository.dart` — added `getStudents()`
  (one-shot filtered fetch for exports / import duplicate check).
- `lib/features/settings/settings_screen.dart` — Backup & Restore and
  Export & Print are now real (no longer "coming soon").
- `lib/features/students/student_form_screen.dart` — Certificates
  icon in the AppBar when editing.

## You must do this yourself (cannot be done in code)
1. Google Cloud Console → create/choose a project, enable the
   **Google Drive API**.
2. Create an OAuth client of type **Android**, package name
   `pk.gov.school.grbook`, with your signing certificate's **SHA-1**.
   Debug and release keystores have different SHA-1s — register both.
3. Configure the OAuth consent screen (add your Google account as a
   test user while in testing mode).

## Honest limitations
- **Automatic Backup** runs when the app is opened (if ≥24h since the
  last one, online, silent Google sign-in works) — not an exact
  background daily job.
- **Restore** is last-writer-wins by design (explicit user action).
- Backups do not embed photo bytes; photos stay in Supabase Storage.
- Excel import does not re-apply the ECE minimum-admission-age rule.
- I could not compile or run this here; `excel`, `googleapis` and
  `google_sign_in` APIs shift between versions, so expect to fix a few
  small signature mismatches on the first `flutter analyze`.

## Requires (already in pubspec.yaml since Phase 1)
`google_sign_in`, `googleapis`, `extension_google_sign_in_as_googleapis_auth`,
`excel`, `file_picker`, `pdf`, `printing`, `archive`, `share_plus`.
