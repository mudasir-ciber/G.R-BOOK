import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/enums.dart';

/// Wraps access to the private `student-photos` Supabase Storage bucket.
/// The bucket has `public: false` (see supabase/sql/03_storage_policies.sql)
/// — every read MUST go through [signedUrlFor] rather than a public URL,
/// and every write is scoped to a school the uploader belongs to via the
/// storage RLS policies.
class PhotoStorageService {
  PhotoStorageService(this._client);

  final SupabaseClient _client;

  String storagePath({
    required String schoolId,
    required String studentId,
    required PhotoType photoType,
    required int version,
  }) {
    return '$schoolId/$studentId/${photoType.dbValue}_$version.jpg';
  }

  Future<void> upload({required String storagePath, required File file}) async {
    await _client.storage.from(AppConfig.studentPhotosBucket).upload(
          storagePath,
          file,
          fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
        );
  }

  /// Short-lived signed URL — never a public link (requirement #9/#30:
  /// "do not expose sensitive images publicly").
  Future<String> signedUrlFor(String storagePath) async {
    return _client.storage
        .from(AppConfig.studentPhotosBucket)
        .createSignedUrl(storagePath, AppConfig.signedUrlExpirySeconds);
  }
}
