# Phase 6 — Pass Out + Struck Off (standalone package)

Only files added or changed in Phase 6. Drop into your existing
`grbook/` project at the same relative paths, and run the new SQL
file on Supabase.

## Run this on Supabase
- `supabase/sql/05_pass_out_years.sql` — new `pass_out_years` table +
  RLS. Run it after 01-04 (same SQL editor / psql flow as before).

## New files
- `lib/repositories/pass_out_repository.dart`
- `lib/repositories/struck_off_repository.dart`
- `lib/providers/pass_out_providers.dart`
- `lib/providers/struck_off_providers.dart`
- `lib/features/passout/pass_out_years_screen.dart`
- `lib/features/passout/pass_out_students_screen.dart`
- `lib/features/struck_off/struck_off_screen.dart`
- `lib/features/struck_off/struck_off_dialog.dart`

## Modified files (overwrite the Phase 5 versions)
- `lib/database/app_database.dart` — **schema version bumped to 3**
  with a real migration (`m.createTable` for the two new tables, no
  data loss). Added `StruckOffRecordsTable`, `PassOutYearsTable`,
  `watchPassOutYears()`, `watchPassOutStudentsForYear()`,
  `watchStruckOffStudents()`, `nextStruckOffQueueBatch()`,
  `nextPassOutYearQueueBatch()`; `nextQueueBatch()` now excludes both
  new entity types too (drains via their own methods).
- `lib/services/sync_engine.dart` — added `_drainStruckOffQueue()` and
  `_drainPassOutYearQueue()`, wired into `syncAll()`.
- `lib/features/students/class_students_screen.dart` — each student
  row now has a "⋮" menu with "Mark as Struck Off".
- `lib/features/classes/classes_screen.dart` — added a **STRUCK OFF**
  row alongside the reference's **PASS OUT** row.

## Requires (already in pubspec.yaml)
No new dependencies were introduced in Phase 6.
