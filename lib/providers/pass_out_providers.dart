import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../repositories/pass_out_repository.dart';
import '../services/connectivity_service.dart';

final passOutRepositoryProvider = Provider<PassOutRepository>((ref) {
  return PassOutRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final passOutYearsProvider = StreamProvider.family((ref, String schoolId) {
  return ref.watch(passOutRepositoryProvider).watchYears(schoolId);
});

typedef PassOutYearArgs = ({String schoolId, int year});

final passOutStudentsForYearProvider = StreamProvider.family((ref, PassOutYearArgs args) {
  return ref.watch(passOutRepositoryProvider).watchStudentsForYear(args.schoolId, args.year);
});
