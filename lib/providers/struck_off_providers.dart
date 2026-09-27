import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../repositories/struck_off_repository.dart';
import '../services/connectivity_service.dart';
import 'repository_providers.dart';

final struckOffRepositoryProvider = Provider<StruckOffRepository>((ref) {
  return StruckOffRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(studentRepositoryProvider),
  );
});

final struckOffStudentsProvider = StreamProvider.family((ref, String schoolId) {
  return ref.watch(struckOffRepositoryProvider).watchStruckOffStudents(schoolId);
});
