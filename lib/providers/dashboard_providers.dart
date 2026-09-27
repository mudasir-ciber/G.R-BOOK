import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(appDatabaseProvider));
});

final totalActiveStudentsProvider = StreamProvider.family((ref, String schoolId) {
  return ref.watch(dashboardRepositoryProvider).watchTotalActiveStudents(schoolId);
});

/// Shared age-reference selection (Today / Admission Date / Custom) so
/// the Dashboard and its class-detail screens stay in sync with
/// whichever the user picked (requirement #23's default is Today).
final ageReferenceProvider = StateProvider<AgeReference>((ref) => AgeReference.today);
final customAgeDateProvider = StateProvider<DateTime?>((ref) => null);

typedef ClassAgeStatsArgs = ({String classId, AgeReference reference, DateTime? customDate});

final classAgeStatsProvider = StreamProvider.family((ref, ClassAgeStatsArgs args) {
  return ref
      .watch(dashboardRepositoryProvider)
      .watchAgeStatsForClass(args.classId, args.reference, customDate: args.customDate);
});
