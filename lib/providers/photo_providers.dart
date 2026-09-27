import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../features/auth/auth_providers.dart';
import '../models/enums.dart';
import '../repositories/student_photo_repository.dart';
import '../services/connectivity_service.dart';
import '../services/image_compression_service.dart';
import '../services/photo_storage_service.dart';

final imageCompressionServiceProvider = Provider<ImageCompressionService>((ref) {
  return ImageCompressionService();
});

final photoStorageServiceProvider = Provider<PhotoStorageService>((ref) {
  return PhotoStorageService(ref.watch(supabaseClientProvider));
});

final studentPhotoRepositoryProvider = Provider<StudentPhotoRepository>((ref) {
  return StudentPhotoRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(imageCompressionServiceProvider),
    ref.watch(photoStorageServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
});

final studentPhotosProvider = StreamProvider.family<Map<PhotoType, StudentPhoto>, String>((ref, studentId) {
  return ref.watch(studentPhotoRepositoryProvider).watchLatestPhotosByType(studentId);
});
