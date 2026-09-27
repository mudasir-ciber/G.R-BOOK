# Phase 7 — Dashboard (standalone package)

Only files added or changed in Phase 7. Drop into your existing
`grbook/` project at the same relative paths.

## New files
- `lib/repositories/dashboard_repository.dart` — total active count,
  per-class age distribution (`AgeBucket`), youngest/oldest, all
  computed with the calendar-accurate `AgeCalculator`.
- `lib/providers/dashboard_providers.dart` — wiring + the shared
  `ageReferenceProvider` / `customAgeDateProvider` state used across
  the Dashboard and its sub-screens.
- `lib/features/dashboard/dashboard_screen.dart` — hero total-active
  card, Today/Admission Date/Custom Date selector, per-class grid.
- `lib/features/dashboard/class_age_stats_screen.dart` — age
  distribution bars + Youngest/Oldest cards.
- `lib/features/dashboard/dashboard_class_students_screen.dart` —
  Name/GR/DOB/full-Age list (requirement #24), separate from the
  regular Class Students CRUD screen.

## Modified files (overwrite the Phase 6 version)
- `lib/features/classes/classes_screen.dart` — added a Dashboard icon
  button to the AppBar.

## Requires (already in pubspec.yaml)
`collection` (for `groupBy`/`sorted`) — already present since Phase 1.
No new dependencies were introduced in Phase 7.
