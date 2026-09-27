# G.R. Book (General Register) — Phase 1 + 2 + 3

Digital General Register for Government Primary Schools in Pakistan.
First deployment target: **Govt Boys Primary School Mehar Ghanghro**.

This build covers **Phase 1 (setup, database, auth)**,
**Phase 2 (School Profile, Classes, full Student CRUD)**, and
**Phase 3 (offline sync engine)**. Real, working code — not a demo.
See "Roadmap" below for what's next.

## What's new in Phase 3

- `SyncEngine` (`lib/services/sync_engine.dart`): drains the local
  outbox (`SyncQueueTable`) against Supabase in creation order.
  - Offline-created students get their serial number allocated safely
    via `next_serial_number()` at replay time, not guessed earlier.
  - Student updates use `.select()` after the conditional `.eq('id',
    ...).eq('version', ...)` update so a **zero-row result is correctly
    detected as a conflict** (Supabase does not throw on that — a bug
    that would have silently swallowed conflicts is fixed in
    `StudentRepository.updateStudent` too, not just the sync engine).
  - On a genuine version conflict, the **server's row wins locally**
    (no destructive auto-overwrite) and the row is flagged
    `SyncState.conflict` plus logged as `STUDENT_UPDATE_CONFLICT` in
    the audit trail — visible to the user as a red warning icon in the
    class list.
  - Gives up retrying a single broken item after 8 attempts so it
    can't block the rest of the queue, while staying visible as
    pending rather than being silently dropped.
  - Also pushes any pending local audit-log rows.
- `SyncCoordinator`: wraps the authenticated app; triggers a drain the
  moment connectivity comes back online, plus every 3 minutes as a
  safety net, plus once on launch.
- `SyncStatusBanner`: the Synced / Syncing / Offline / Pending-changes
  indicator from requirement #27, now showing on the Classes and Class
  Students screens (tap it while "Pending changes" to force a sync).

## What's new in Phase 2

- `SchoolRepository`: bootstraps the logged-in user's school + classes
  from Supabase into the local Drift cache on first login, creates a
  brand-new school (Add School screen) with its 6 default classes and
  promotion chain wired automatically, and updates the school profile
  offline-first.
- `ClassRepository`: live (`Stream`) class list with **active student
  counts per class**, all read from the local cache.
- `StudentRepository`: full offline-first CRUD —
  - Serial numbers are allocated safely via the server's
    `next_serial_number()` RPC when online; offline-created students
    show "Pending" until synced (never guessed/duplicated client-side).
  - GR-number duplicate check that **warns but never blocks** saving.
  - Every create/update writes to the local DB first, then either
    pushes to Supabase immediately or queues it in the sync outbox.
  - Every mutation writes a local audit-log row.
- Screens: **Add School**, **School Profile** (edit), **Classes** (with
  live counts), **Class Students** (search + list + Add Student FAB),
  **Add/Edit Student** (full field set, ECE admission-age validation
  read from the class's configurable rule, GR duplicate warning
  dialog), **Student Profile** (Today / Admission Date / Custom Date
  age views using the calendar-accurate age calculator).
- `main.dart` now routes a signed-in user through a real **School
  Gate**: cached school → Classes; no cache → bootstrap from server;
  no membership at all → Add School — matching requirement #37's flow.

## What's included in Phase 1

- Flutter project scaffold (`lib/core`, `config`, `models`, `database`,
  `features/...`) matching the required clean architecture.
- Android configuration: `minSdk 29`, `compileSdk/targetSdk 35`,
  universal APK, only the permissions actually needed (camera, network,
  scoped media, biometric, notifications) — see `AndroidManifest.xml`.
- **Complete Supabase SQL**: schema (`01_schema.sql`), Row Level
  Security policies with zero "allow-all" rules (`02_rls_policies.sql`),
  private-bucket storage policies for student photos
  (`03_storage_policies.sql`), and a seed script for the first school
  (`04_seed_first_school.sql`).
- **Offline database** (Drift/SQLite) mirroring the server schema, plus
  a `SyncQueueTable` outbox for the offline-first sync engine.
- Calendar-accurate **age calculator** (`lib/core/age_calculator.dart`)
  — years/months/days, not `days/365` — which everything in ECE
  admission and ECE→Class 1 promotion rules will depend on.
- Full **Student** and **School/SchoolClass** models with
  Supabase (`fromMap`/`toMap`) and local sync-state bookkeeping.
- Working **Authentication**: Create Account, Login (mobile number +
  password, Remember Me, Forgot Password), session handling — all via
  Supabase Auth. No manual password storage anywhere.

## Setup

1. Create a Supabase project.
2. Run the SQL files in `supabase/sql/` **in order** (01 → 02 → 03) via
   the Supabase SQL editor or `psql`.
3. Create your first account in the app (Create Account screen), then
   run `04_seed_first_school.sql` with `-v owner_profile_id='<that
   user's auth.users.id>'` to seed the school and its 6 classes with
   promotion rules pre-wired.
4. Get your Project URL and anon/public key from
   Supabase → Settings → API. **Never use the service-role key here.**
5. Run the app with those values injected at build time:

   ```bash
   flutter pub get
   flutter pub run build_runner build --delete-conflicting-outputs
   flutter run \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

6. To build the release APK:

   ```bash
   flutter build apk --release \
     --dart-define=SUPABASE_URL=https://YOUR-PROJECT-REF.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
   ```

   For a signed release, create `android/key.properties` (see comments
   in `android/app/build.gradle.kts`) — without it, release builds fall
   back to debug signing so the build still succeeds during development.

## What's new in Phase 4

- **Photo pipeline** (requirement #9): `ImageCompressionService` resizes
  + compresses every photo before it's stored (1080px/quality 78 for
  uploads, 240px/quality 70 for list thumbnails; EXIF metadata
  stripped). `PhotoStorageService` uploads to the private
  `student-photos` bucket and only ever issues short-lived signed URLs
  — never a public link. `StudentPhotoRepository` is fully
  offline-first: capture → compress → save locally instantly → upload
  now if online, else queue (`entityType: 'photo'`) for the sync
  engine, which now drains that queue too (uploads the compressed file
  once connectivity returns).
- Replacing a photo creates a **new version** rather than overwriting —
  history is preserved per requirement #11.
- **Student Profile / Add Student rebuilt** as a single
  `StudentFormScreen` matching the provided UI reference exactly:
  circular photo with camera badge, Student Name field, G.R No/Class
  row, Father Name/Mobile No. row, Mother Name/Last School row, Date of
  Birth + a live read-only "Age Here" (Year/Month/Days) display, Date
  of Admission, Address, then B-Form/Father-CNIC/Student-Token photo
  tiles, and a single bottom button ("Add Student" / "Edit Data"). CNIC
  number, B-Form number, and Remarks (required by the data model but
  not shown in the reference) are tucked behind an "Additional Details"
  toggle so the primary layout stays visually identical to the
  reference.
- Class Students list rows now show the **real compressed student
  photo** (local file first, falling back to a signed URL) instead of
  an initials placeholder.

## What's new in Phase 5

- **Fully offline promotion workflow** (requirements #14-#19). New local
  tables `PromotionBatchesTable` / `PromotionRecordsTable` mirror the
  server schema (schema bumped to v2 with a real migration — no data
  loss for anyone already on a Phase 1-4 build).
- `PromotionRepository`:
  - `getCandidates()` — active students in a class, with an
    `isAgeEligible` flag computed via the calendar-accurate age
    calculator against the class's configured
    `minPromotionAgeMonths` (ECE → Class 1's 5y1m rule). Non-gated
    classes mark everyone eligible but nothing is pre-selected in the
    UI — the teacher chooses, matching the reference screen.
  - `promoteStudents()` — writes a batch + one record per student
    locally first (works with no network), moves each student to the
    target class (or to `PASSED_OUT` + `passOutYear` when the class is
    terminal), then pushes to Supabase or queues for the sync engine.
  - `markStudentFailed()` — keeps the student in the same class, still
    logged as a `FAILED` record in promotion history.
  - `undoLastPromotion()` — restores every affected student's previous
    class/status from the batch's records; the batch itself is marked
    `isUndone` rather than deleted, so history is never destroyed.
  - Passing out a student also inserts `pass_out_records` server-side
    (both on immediate push and on queued replay).
- `SyncEngine` now drains a **third independent queue**
  (`entityType: 'promotion_batch'`) — after the student queue (so
  foreign keys resolve) and before photos.
- Screens: **Promote Students** (Current/Promote To, promotion date
  picker, search, Select All + per-student checkboxes, an inline
  "Mark as Failed" action per row, Undo-last-promotion in the AppBar
  when applicable) and **Confirm Promotion** (the required preview
  step before the actual database transaction).
- `ClassStudentsScreen` now has both "Add Student" and "Promote"
  buttons, matching the UI reference's stacked-button layout.

A dedicated year-by-year **promotion history viewer** (browsing past
batches/records for a student or class) is deferred to Phase 8
alongside the audit log viewer — the data model already fully supports
it; only the screen is pending.

## Roadmap (subsequent phases, same architecture)

- ~~**Phase 2**: School Profile screen, Classes management, Student CRUD,
  offline repository + Drift wiring, serial-number allocation, GR-number
  duplicate warning.~~ ✅ Done.
- ~~**Phase 3**: Sync engine (outbox drain, connectivity listener, sync
  status banner), conflict handling via `version`/`updated_at`.~~ ✅ Done.
- ~~**Phase 4**: Student photos (camera/gallery, compression, Supabase
  Storage signed URLs, local caching), Student Profile/Add Student
  rebuilt to match the UI references exactly.~~ ✅ Done.
- ~~**Phase 5**: Promotion workflow (select/preview/confirm/undo), ECE→1
  age-gated promotion, fail-in-place, promotion history.~~ ✅ Done.
- **Phase 6**: Pass Out (by year) and Struck Off (+ re-admission) flows.
- **Phase 7**: Dashboard (active counts, per-class counts, age
  distribution, youngest/oldest).
- **Phase 8**: Search/filter (offline-capable), Audit log viewer.
- **Phase 9**: Google Drive backup/restore, Excel import/export, PDF
  export + certificate generation (School Leaving / Character / Birth).
- **Phase 10**: App lock (PIN + biometric), final UI polish against the
  10 reference screens, release build hardening.

Each phase will land as complete, working files — never pseudocode or
placeholder buttons — following the same `FILE PATH` / `CODE` delivery
style, continuing directly in this conversation.
