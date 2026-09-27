# Phase 5 — Promotion Workflow (standalone package)

Only files added or changed in Phase 5. Drop into your existing
`grbook/` project at the same relative paths.

## New files
- `lib/repositories/promotion_repository.dart` — eligibility
  computation, promote/fail/undo, all offline-first.
- `lib/providers/promotion_providers.dart` — Riverpod wiring.
- `lib/features/promotion/promote_students_screen.dart` — Current/
  Promote To, promotion date, search, Select All + checkboxes,
  per-row "Mark as Failed", Undo-last-promotion.
- `lib/features/promotion/promotion_preview_screen.dart` — the
  required confirmation step before the database transaction.

## Modified files (overwrite the Phase 4 versions)
- `lib/database/app_database.dart` — **schema version bumped to 2**
  with a real migration (`m.createTable` for the two new tables) —
  existing installs keep their local data, nothing is dropped. Added
  `PromotionBatchesTable`, `PromotionRecordsTable`,
  `nextPromotionQueueBatch()`, `latestActiveBatchForClass()`,
  `recordsForBatch()`; `nextQueueBatch()` now also excludes
  `entityType: 'promotion_batch'` (drains via its own method).
- `lib/services/sync_engine.dart` — added `_drainPromotionQueue()` /
  `_replayPromotionBatch()`, run after the student queue (so promoted
  students' server rows exist first for the FK) and before photos.
- `lib/features/students/class_students_screen.dart` — replaced the
  single "Add Student" FAB with a stacked "Add Student" + "Promote"
  button pair (matches the UI reference), navigating to the new
  Promote Students screen.

## Data model note
Passing a student out (Class 5 → Passed Out) sets `status =
PASSED_OUT` and `pass_out_year` directly on the student row — a
dedicated Pass Out **browsing** screen (by year) lands in Phase 6, but
the underlying data is already correct and synced from this phase.

A year-by-year promotion **history viewer** (past batches/records) is
deferred to Phase 8 with the audit log viewer — the data model already
supports it.

## Requires (already in pubspec.yaml)
No new dependencies were introduced in Phase 5.
