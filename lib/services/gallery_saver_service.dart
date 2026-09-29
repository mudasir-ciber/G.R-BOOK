import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class GallerySaverService {
  static const _channel = MethodChannel('pk.gov.school.grbook/gallery');

  /// Saves image bytes to Android Gallery / Pictures/GR_Book folder.
  /// Falls back to saving to application documents directory on other platforms.
  static Future<bool> saveImageToGallery({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (Platform.isAndroid) {
      try {
        final bool? success = await _channel.invokeMethod<bool>('saveImageToGallery', {
          'bytes': bytes,
          'fileName': fileName,
        });
        return success ?? false;
      } catch (e) {
        // Fallback to manual file write if channel fails
        return _fallbackSave(bytes, fileName);
      }
    } else {
      return _fallbackSave(bytes, fileName);
    }
  }

  static Future<bool> _fallbackSave(Uint8List bytes, String fileName) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      return true;
    } catch (_) {
      return false;
    }
  }
}
