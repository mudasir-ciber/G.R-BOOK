import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/excel_export_service.dart';
import '../services/excel_import_service.dart';
import '../services/pdf_export_service.dart';

final excelExportServiceProvider = Provider<ExcelExportService>((ref) => ExcelExportService());
final excelImportServiceProvider = Provider<ExcelImportService>((ref) => ExcelImportService());
final pdfExportServiceProvider = Provider<PdfExportService>((ref) => PdfExportService());
