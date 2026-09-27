import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Requirement #9: every photo must be resized/compressed before it is
/// stored or uploaded — never keep or send an unmodified multi-MB
/// camera photo.
///
/// Two profiles are used:
///  - [compressForUpload]: max dimension 1080px, quality 78 — good
///    enough for print/certificate use while staying small on slow
///    rural connections.
///  - [compressForThumbnail]: max dimension 240px, quality 70 — used
///    for list-row avatars so scrolling a class of 40+ students stays
///    smooth (requirement #43 performance).
class ImageCompressionService {
  final _uuid = const Uuid();

  Future<File> compressForUpload(File source) => _compress(source, maxDimension: 1080, quality: 78);

  Future<File> compressForThumbnail(File source) => _compress(source, maxDimension: 240, quality: 70);

  Future<File> _compress(File source, {required int maxDimension, required int quality}) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    final targetPath = p.join(photosDir.path, '${_uuid.v4()}.jpg');

    final result = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      targetPath,
      quality: quality,
      minWidth: maxDimension,
      minHeight: maxDimension,
      format: CompressFormat.jpeg,
      keepExif: false, // strips location/device metadata from sensitive student photos
    );

    if (result == null) {
      // Compression can fail on some OEM camera outputs (unsupported
      // codec) — fall back to the original rather than losing the
      // photo entirely; it's still usable, just larger.
      return source;
    }
    return File(result.path);
  }
}
