import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single shared instance for the app's lifetime. Repositories read
/// this instead of constructing their own AppDatabase, so every screen
/// sees the same local data and the same live `.watch()` streams.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});
