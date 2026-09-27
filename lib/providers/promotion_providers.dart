import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../repositories/promotion_repository.dart';
import '../services/connectivity_service.dart';
import 'repository_providers.dart';

final promotionRepositoryProvider = Provider<PromotionRepository>((ref) {
  return PromotionRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(connectivityServiceProvider),
    ref.watch(classRepositoryProvider),
    ref.watch(studentRepositoryProvider),
  );
});

/// Whether the current class has a recent promotion batch that can
/// still be undone (requirement #19) — drives the AppBar action.
final hasUndoableBatchProvider = FutureProvider.family<bool, String>((ref, classId) {
  return ref.watch(promotionRepositoryProvider).hasUndoableBatch(classId);
});
