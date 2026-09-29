import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Service that automatically removes paper and solid backgrounds from
/// signature photos, converting them into crisp, transparent PNG signatures.
class SignatureProcessingService {
  /// Processes raw image bytes and returns a transparent PNG with background removed.
  static Uint8List removeBackground(Uint8List inputBytes) {
    try {
      final image = img.decodeImage(inputBytes);
      if (image == null) return inputBytes;

      final rgba = image.numChannels == 4 ? image : image.convert(numChannels: 4);
      final w = rgba.width;
      final h = rgba.height;

      // 1. Check if the image is already predominantly transparent
      int transparentCount = 0;
      for (int y = 0; y < h; y += 4) {
        for (int x = 0; x < w; x += 4) {
          if (rgba.getPixel(x, y).a < 50) {
            transparentCount++;
          }
        }
      }
      final sampledPixels = (w / 4).ceil() * (h / 4).ceil();
      if (transparentCount > (sampledPixels * 0.20)) {
        // Already transparent, just return encoded PNG
        return Uint8List.fromList(img.encodePng(rgba));
      }

      // 2. Gather luminance distribution across pixels
      final lums = <double>[];
      for (int y = 0; y < h; y += 2) {
        for (int x = 0; x < w; x += 2) {
          final p = rgba.getPixel(x, y);
          lums.add(0.299 * p.r + 0.587 * p.g + 0.114 * p.b);
        }
      }
      lums.sort();

      // In any paper signature photo, paper brightness sits at ~75th percentile
      final paperBrightness = lums[(lums.length * 0.75).toInt()].clamp(130.0, 255.0);

      // Paper cutoff: pixels with luminance >= paperCutoff become 100% transparent.
      // Ink cutoff: pixels with luminance <= inkCutoff become 100% solid ink.
      final paperCutoff = paperBrightness - 15.0;
      final inkCutoff = paperBrightness - 55.0;
      final range = (paperCutoff - inkCutoff).clamp(1.0, 255.0);

      int minX = w;
      int maxX = 0;
      int minY = h;
      int maxY = 0;
      bool foundInk = false;

      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final p = rgba.getPixel(x, y);
          final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

          if (lum >= paperCutoff) {
            p.a = 0;
          } else if (lum <= inkCutoff) {
            p.a = 255;
            // Rich ink contrast (deepen pen strokes)
            p.r = (p.r * 0.88).round();
            p.g = (p.g * 0.88).round();
            p.b = (p.b * 0.88).round();
            foundInk = true;
            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          } else {
            // Smooth anti-aliased edge falloff
            final t = (paperCutoff - lum) / range;
            p.a = (t.clamp(0.0, 1.0) * 255).round();
            if (p.a > 35) {
              foundInk = true;
              if (x < minX) minX = x;
              if (x > maxX) maxX = x;
              if (y < minY) minY = y;
              if (y > maxY) maxY = y;
            }
          }
        }
      }

      // 3. Trim extra empty borders tightly around the ink stroke
      if (foundInk && minX <= maxX && minY <= maxY) {
        const pad = 8;
        final cropX = max(0, minX - pad);
        final cropY = max(0, minY - pad);
        final cropW = min(w - cropX, (maxX - minX + 1) + pad * 2);
        final cropH = min(h - cropY, (maxY - minY + 1) + pad * 2);

        if (cropW > 6 && cropH > 6) {
          final cropped = img.copyCrop(rgba, x: cropX, y: cropY, width: cropW, height: cropH);
          return Uint8List.fromList(img.encodePng(cropped));
        }
      }

      return Uint8List.fromList(img.encodePng(rgba));
    } catch (e) {
      debugPrint('Error removing signature background: $e');
      return inputBytes;
    }
  }

  /// Process an image file, remove background and save as transparent PNG.
  static Future<File> processSignatureFile(File inputFile, {File? outputFile}) async {
    final rawBytes = await inputFile.readAsBytes();
    final cleanBytes = await compute(removeBackground, rawBytes);
    final target = outputFile ?? inputFile;
    await target.writeAsBytes(cleanBytes, flush: true);
    return target;
  }

  /// Ensures that loaded signature bytes are transparent.
  static Future<Uint8List> ensureTransparentBackground(Uint8List bytes) async {
    return compute(removeBackground, bytes);
  }
}
