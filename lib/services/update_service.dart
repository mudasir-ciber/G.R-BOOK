import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme.dart';

class UpdateService {
  UpdateService._();

  static const int currentVersionCode = 2;
  static const String currentVersionName = '1.0.0+2';

  static const String updateConfigUrl =
      'https://paisrmhvdeevekksewsb.supabase.co/storage/v1/object/public/public-assets/version.json';

  /// Check for update from Supabase public storage
  static Future<void> checkForUpdate(BuildContext context, {bool showToastIfUpToDate = false}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse(updateConfigUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = json.decode(body) as Map<String, dynamic>;
        final remoteVersionCode = data['version_code'] as int? ?? 1;
        final remoteVersionName = data['version_name'] as String? ?? '1.0.0';
        final apkUrl = data['apk_url'] as String? ?? '';
        final releaseNotes = data['release_notes'] as String? ?? 'New improvements and bug fixes.';
        final forceUpdate = data['force_update'] as bool? ?? false;

        if (remoteVersionCode > currentVersionCode && apkUrl.isNotEmpty && context.mounted) {
          _showUpdateDialog(
            context,
            versionName: remoteVersionName,
            releaseNotes: releaseNotes,
            apkUrl: apkUrl,
            forceUpdate: forceUpdate,
          );
          return;
        }
      }

      if (showToastIfUpToDate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF0F9D58),
            content: Text('G.R. BOOK is up to date (Version $currentVersionName)'),
          ),
        );
      }
    } catch (_) {
      if (showToastIfUpToDate && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not check for updates. Please check your internet connection.'),
          ),
        );
      }
    }
  }

  static void _showUpdateDialog(
    BuildContext context, {
    required String versionName,
    required String releaseNotes,
    required String apkUrl,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.system_update_rounded, color: GrBookTheme.primary, size: 28),
            SizedBox(width: 10),
            Text('Update Available', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GrBookTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Version $versionName',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: GrBookTheme.primaryDark,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'A new update is available for G.R. BOOK with important improvements:',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                releaseNotes,
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          if (!forceUpdate)
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: GrBookTheme.primary),
            icon: const Icon(Icons.download_rounded, size: 18),
            label: const Text('Update Now'),
            onPressed: () async {
              Navigator.of(ctx).pop();
              final uri = Uri.parse(apkUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }
}
