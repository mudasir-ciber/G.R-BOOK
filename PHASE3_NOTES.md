# Phase 3 — Sync Engine (standalone package)

This zip contains **only** the files added or changed in Phase 3. Drop
them into your existing `grbook/` project at the same relative paths —
they will create new files and overwrite the modified ones.

## New files
- `lib/services/sync_engine.dart` — drains the offline outbox against
  Supabase (student create/update replay, safe serial allocation,
  conflict handling, audit log push).
- `lib/services/sync_coordinator.dart` — auto-triggers a sync on
  connectivity restore + every 3 minutes + once on launch.
- `lib/providers/sync_providers.dart` — Riverpod wiring: pending count
  stream, combined banner state, manual `triggerSync()`.
- `lib/widgets/sync_status_banner.dart` — the Synced / Syncing /
  Offline / Pending-changes strip.

## Modified files (overwrite the Phase 2 versions)
- `lib/database/app_database.dart` — added `watchPendingSyncCount()`,
  `nextQueueBatch()`, `deleteQueueItem()`, `markQueueItemFailed()`
  (now correctly increments `attemptCount`), `pendingAuditLogs()`,
  `markAuditLogSynced()`.
- `lib/repositories/student_repository.dart` — fixed `updateStudent()`
  to actually detect a version conflict via `.select()` (Supabase does
  not throw on a 0-row conditional update) instead of silently
  "succeeding" against zero rows.
- `lib/main.dart` — wraps the authenticated app in `SyncCoordinator`.
- `lib/features/classes/classes_screen.dart` — shows `SyncStatusBanner`.
- `lib/features/students/class_students_screen.dart` — shows
  `SyncStatusBanner`; student rows now show a red conflict icon
  (`SyncState.conflict`) distinct from the orange pending-upload icon.

## Requires (already in pubspec.yaml from Phase 1)
`connectivity_plus`, `drift`, `supabase_flutter` — no new dependencies
were introduced in Phase 3.

Full project README (setup, build steps, full roadmap) is included
alongside this file for reference.
