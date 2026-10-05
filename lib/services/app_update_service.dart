import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';

class AppUpdateInfo {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final double apkSizeMb;
  final String releaseNotes;
  final bool isMandatory;

  const AppUpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.apkSizeMb,
    required this.releaseNotes,
    required this.isMandatory,
  });

  factory AppUpdateInfo.fromMap(Map<String, dynamic> map) {
    return AppUpdateInfo(
      versionName: (map['version_name'] as String?) ?? '1.0.1',
      versionCode: (map['version_code'] as num?)?.toInt() ?? 0,
      apkUrl: (map['apk_url'] as String?) ?? '',
      apkSizeMb: (map['apk_size_mb'] as num?)?.toDouble() ?? 99.30,
      releaseNotes: (map['release_notes'] as String?) ?? 'Bug fixes & performance improvements.',
      isMandatory: (map['is_mandatory'] as bool?) ?? false,
    );
  }
}

class AppUpdateService {
  AppUpdateService(this._client);

  final SupabaseClient _client;
  static const MethodChannel _channel = MethodChannel('pk.gov.school.grbook/app_update');

  /// Checks Supabase `app_updates` table to see if a newer APK is available.
  Future<AppUpdateInfo?> checkForUpdate() async {
    try {
      final response = await _client
          .from('app_updates')
          .select()
          .eq('is_active', true)
          .order('version_code', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;

      final update = AppUpdateInfo.fromMap(response);

      // Only prompt if server version_code is strictly greater than current app build
      if (update.versionCode > AppConfig.appBuildNumber && update.apkUrl.isNotEmpty) {
        return update;
      }
      return null;
    } catch (e) {
      debugPrint('AppUpdateService: Error checking for update: $e');
      return null;
    }
  }

  /// Checks if Android allows installing APKs from unknown sources for this app.
  Future<bool> canRequestPackageInstalls() async {
    if (!Platform.isAndroid) return true;
    try {
      final res = await _channel.invokeMethod<bool>('canRequestPackageInstalls');
      return res ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Opens Android Unknown Sources Settings screen.
  Future<void> openInstallPermissionSettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('openInstallPermissionSettings');
    } catch (_) {}
  }

  /// Downloads the APK directly from [apkUrl] with real-time download progress.
  Future<File> downloadApk({
    required String apkUrl,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
  }) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await client.getUrl(Uri.parse(apkUrl));
      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Download failed with server status code: ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final tempDir = await getTemporaryDirectory();
      final apkFile = File('${tempDir.path}/gr_book_update.apk');

      if (await apkFile.exists()) {
        await apkFile.delete();
      }

      final sink = apkFile.openWrite();

      await for (final chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          final progress = receivedBytes / totalBytes;
          onProgress(progress.clamp(0.0, 1.0), receivedBytes, totalBytes);
        } else {
          // If server didn't send content-length header
          onProgress(0.5, receivedBytes, 0);
        }
      }

      await sink.flush();
      await sink.close();

      return apkFile;
    } finally {
      client.close();
    }
  }

  /// Triggers Android's native package installer sheet.
  Future<void> installApk(String filePath) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('installApk', {'filePath': filePath});
    } catch (e) {
      throw Exception('Failed to launch installer: $e');
    }
  }
}

final appUpdateServiceProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService(Supabase.instance.client);
});
