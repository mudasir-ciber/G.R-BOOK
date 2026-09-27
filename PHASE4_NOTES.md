# Phase 4 — Student Photos + UI-Matched Student Form (standalone package)

Only files added or changed in Phase 4. Drop into your existing
`grbook/` project at the same relative paths.

## New files
- `lib/services/image_compression_service.dart` — resize/compress
  before any photo is stored (1080px/q78 upload, 240px/q70 thumbnail,
  EXIF stripped).
- `lib/services/photo_storage_service.dart` — uploads to the private
  `student-photos` bucket, issues signed URLs only (never public).
- `lib/repositories/student_photo_repository.dart` — offline-first
  capture/compress/save/upload-or-queue, versioned (replace = new
  version, history preserved).
- `lib/providers/photo_providers.dart` — Riverpod wiring for the above.
- `lib/features/students/widgets/photo_picker_sheet.dart` — Camera /
  Gallery bottom sheet.
- `lib/features/students/widgets/profile_photo_avatar.dart` — circular
  photo with camera badge (main student photo).
- `lib/features/students/widgets/document_photo_tile.dart` — square
  tile with "Add Photo" button (B-Form / CNIC / Token).
- `lib/features/students/student_form_screen.dart` — **new unified
  screen**, replacing the old `add_edit_student_screen.dart` and
  `student_profile_screen.dart`, matching the UI reference layout
  exactly.

## Deleted files (remove these from your project)
- `lib/features/students/add_edit_student_screen.dart`
- `lib/features/students/student_profile_screen.dart`

## Modified files (overwrite the Phase 3 versions)
- `lib/database/app_database.dart` — added `watchStudentPhotos()`,
  `nextPhotoQueueBatch()`.
- `lib/services/sync_engine.dart` — added `_drainPhotoQueue()`, wired
  into `syncAll()`; `nextQueueBatch()` in app_database.dart now
  excludes `entityType: 'photo'` so the two queues drain independently.
- `lib/providers/repository_providers.dart` — added
  `classesStreamProvider` (plain class list, for the Class dropdown).
- `lib/features/students/class_students_screen.dart` — now navigates
  to `StudentFormScreen` (both Add and tap-to-view/edit), and list rows
  show the real compressed student photo instead of initials.

## Requires (already in pubspec.yaml from Phase 1)
`image_picker`, `flutter_image_compress`, `cached_network_image` — no
new dependencies were introduced in Phase 4.

Full project README included alongside for reference.
