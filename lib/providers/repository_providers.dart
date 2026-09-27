import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../repositories/class_repository.dart';
import '../repositories/school_repository.dart';
import '../repositories/student_repository.dart';
import '../services/connectivity_service.dart';

final schoolRepositoryProvider = Provider<SchoolRepository>((ref) {
  return SchoolRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final classRepositoryProvider = Provider<ClassRepository>((ref) {
  return ClassRepository(ref.watch(appDatabaseProvider));
});

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
  );
});

/// The single school this device is currently working with (Phase 1/2
/// scope: one school per install). Screens watch this instead of each
/// re-querying the database directly.
final currentSchoolProvider = StreamProvider((ref) {
  return ref.watch(schoolRepositoryProvider).watchLocalSchool();
});

final classesWithCountsProvider = StreamProvider.family((ref, String schoolId) {
  return ref.watch(classRepositoryProvider).watchClassesWithActiveCounts(schoolId);
});

/// Plain class list (no counts) — used by the Class dropdown in the
/// student form, which just needs id/displayName/rules.
final classesStreamProvider = StreamProvider.family((ref, String schoolId) {
  return ref.watch(classRepositoryProvider).watchClasses(schoolId);
});
