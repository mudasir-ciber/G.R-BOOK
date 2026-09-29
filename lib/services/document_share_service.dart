import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme.dart';
import '../widgets/gallery_save_success_dialog.dart';
import 'gallery_saver_service.dart';

class DocumentShareService {
  /// Converts the first page of a PDF file to a high-quality JPG image file.
  static Future<File> convertPdfToJpg(
    File pdfFile, {
    double dpi = 200.0,
    String? outputFileName,
  }) async {
    final pdfBytes = await pdfFile.readAsBytes();
    Uint8List? jpgBytes;

    await for (final page in Printing.raster(pdfBytes, pages: [0], dpi: dpi)) {
      final pngBytes = await page.toPng();
      final decoded = img.decodeImage(pngBytes);
      if (decoded != null) {
        // Create a solid white canvas to eliminate transparency turning pitch black in JPG
        final whiteCanvas = img.Image(
          width: decoded.width,
          height: decoded.height,
        );
        img.fill(whiteCanvas, color: img.ColorRgb8(255, 255, 255));
        img.compositeImage(whiteCanvas, decoded);
        jpgBytes = Uint8List.fromList(img.encodeJpg(whiteCanvas, quality: 95));
      }
      break;
    }

    if (jpgBytes == null) {
      throw Exception('Failed to rasterize PDF page to JPG');
    }

    final tempDir = await getTemporaryDirectory();
    final safeName = (outputFileName ?? 'Document').replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final jpgFile = File('${tempDir.path}/${safeName}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await jpgFile.writeAsBytes(jpgBytes);
    return jpgFile;
  }

  /// Directly shares the document as a PDF.
  static Future<void> sharePdf(File pdfFile, {String? text}) async {
    await Share.shareXFiles([XFile(pdfFile.path)], text: text);
  }

  /// Directly shares the document as a JPG Image.
  static Future<void> shareJpg(File pdfFile, {String? text, String? outputFileName}) async {
    final jpgFile = await convertPdfToJpg(pdfFile, outputFileName: outputFileName);
    await Share.shareXFiles([XFile(jpgFile.path)], text: text);
  }

  /// Saves the rasterized JPG page directly to the mobile phone's gallery.
  static Future<bool> saveJpgToGallery(
    BuildContext context,
    File pdfFile, {
    String? fileName,
  }) async {
    try {
      final jpgFile = await convertPdfToJpg(pdfFile, outputFileName: fileName);
      final bytes = await jpgFile.readAsBytes();
      final safeName = '${fileName ?? 'Document'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ok = await GallerySaverService.saveImageToGallery(bytes: bytes, fileName: safeName);

      if (context.mounted) {
        if (ok) {
          GallerySaveSuccessDialog.show(
            context,
            title: 'Saved to Gallery!',
            message: 'Image successfully saved in Pictures/GR_Book',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not save JPG to Gallery.')),
          );
        }
      }
      return ok;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return false;
    }
  }

  /// Shows an interactive bottom sheet presenting PDF and JPG options.
  static Future<void> showShareOptions(
    BuildContext context, {
    File? pdfFile,
    Future<File> Function()? getPdfFile,
    required String title,
    String? studentName,
    String? baseFileName,
  }) async {
    Future<File> obtainPdf() async {
      if (pdfFile != null) return pdfFile;
      if (getPdfFile != null) return await getPdfFile();
      throw Exception('No PDF file provided');
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: GrBookTheme.primaryDark),
                ),
                if (studentName != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    studentName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: GrBookTheme.textSecondary),
                  ),
                ],
                const SizedBox(height: 18),

                // Option 1: Share as PDF
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFEBEE), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F), size: 24),
                  ),
                  title: const Text('Share as PDF Document', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Send standard high-resolution PDF file'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final f = await obtainPdf();
                    await sharePdf(f, text: title);
                  },
                ),
                const Divider(height: 1),

                // Option 2: Share as JPG
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.image_rounded, color: Color(0xFF2E7D32), size: 24),
                  ),
                  title: const Text('Share as JPG Image', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Send crisp JPG photo directly to WhatsApp/Telegram'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final f = await obtainPdf();
                    await shareJpg(f, text: title, outputFileName: baseFileName ?? title);
                  },
                ),
                const Divider(height: 1),

                // Option 3: Save JPG to Gallery
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFE0F2FE), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.save_alt_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  title: const Text('Save JPG to Mobile Gallery', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Store in phone gallery under "Pictures/GR_Book"'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final f = await obtainPdf();
                    if (context.mounted) {
                      await saveJpgToGallery(context, f, fileName: baseFileName ?? title);
                    }
                  },
                ),
                const Divider(height: 1),

                // Option 4: Print
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.print_rounded, color: Color(0xFF7E22CE), size: 24),
                  ),
                  title: const Text('Print Document', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Direct print via Android print service'),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final f = await obtainPdf();
                    Printing.layoutPdf(onLayout: (_) => f.readAsBytes());
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
