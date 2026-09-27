# Phase 8 — Search + Audit Log + Settings Hub (standalone package)

Only files added or changed in Phase 8. Drop into your existing
`grbook/` project at the same relative paths.

## New files
- `lib/repositories/audit_log_repository.dart` — read-only, joins
  `AuditLogsTable` with `StudentsTable` to resolve names; no
  update/delete method exists anywhere.
- `lib/providers/audit_log_providers.dart`
- `lib/features/audit/audit_log_screen.dart` — school-wide or
  per-student log, newest first, expandable before/after values.
- `lib/features/search/global_search_screen.dart` — school-wide search
  by Name/GR/Class.
- `lib/features/settings/settings_screen.dart` — navigational home;
  see notes below on which entries are real vs. honestly stubbed.
- `lib/features/settings/my_account_screen.dart` — read-only, from the
  local auth session (works offline).
- `lib/features/settings/about_screen.dart` — static app info.

## Modified files (overwrite the Phase 7 versions)
- `lib/repositories/student_repository.dart` — added
  `watchGlobalSearch()` (school-scoped, also matches by class
  name/code, unlike the existing per-class `watchSearch()`).
- `lib/providers/repository_providers.dart` — added
  `globalSearchProvider`.
- `lib/features/students/student_form_screen.dart` — added a History
  icon (opens the Audit Log scoped to that student) when editing.
- `lib/features/classes/classes_screen.dart` — added a Settings
  (leading, gear icon) and Search action to the AppBar.

## Honesty note on Settings entries
Per the project's "no fake buttons" rule, entries for features not yet
built (Manage Classes, Backup & Restore, Export & Print, App Security)
show a plain "coming in a later phase" SnackBar instead of pretending
to do something. My Account, School Profile, Pass Out Years, Audit
Log, About, and Logout are all fully real.

## Requires (already in pubspec.yaml)
No new dependencies were introduced in Phase 8.
