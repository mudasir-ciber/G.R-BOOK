import 'package:flutter_test/flutter_test.dart';
import 'package:gr_book/models/school.dart';
import 'package:gr_book/services/pdf_export_service.dart';

void main() {
  group('PdfExportService.formatSchoolName', () {
    test('expands all 15 school types correctly', () {
      expect(
        PdfExportService.formatSchoolName('GBPS Mehar Ghanghro'),
        'Government Boys Primary School Mehar Ghanghro',
      );
      expect(
        PdfExportService.formatSchoolName('GGPS Dadu'),
        'Government Girls Primary School Dadu',
      );
      expect(
        PdfExportService.formatSchoolName('GPS Village Ali'),
        'Government Primary School Village Ali',
      );
      expect(
        PdfExportService.formatSchoolName('GBELS Kotri'),
        'Government Boys Elementary School Kotri',
      );
      expect(
        PdfExportService.formatSchoolName('GGELS Sukkur'),
        'Government Girls Elementary School Sukkur',
      );
      expect(
        PdfExportService.formatSchoolName('GELS Khairpur'),
        'Government Elementary School Khairpur',
      );
      expect(
        PdfExportService.formatSchoolName('GBLSS Hyderabad'),
        'Government Boys Lower Secondary School Hyderabad',
      );
      expect(
        PdfExportService.formatSchoolName('GGLSS Mirpurkhas'),
        'Government Girls Lower Secondary School Mirpurkhas',
      );
      expect(
        PdfExportService.formatSchoolName('GLSS Badin'),
        'Government Lower Secondary School Badin',
      );
      expect(
        PdfExportService.formatSchoolName('GBHS Mehar'),
        'Government Boys High School Mehar',
      );
      expect(
        PdfExportService.formatSchoolName('GGHS Sehwan'),
        'Government Girls High School Sehwan',
      );
      expect(
        PdfExportService.formatSchoolName('GHS Johi'),
        'Government High School Johi',
      );
      expect(
        PdfExportService.formatSchoolName('GBHSS Larkana'),
        'Government Boys Higher Secondary School Larkana',
      );
      expect(
        PdfExportService.formatSchoolName('GGHSS Moro'),
        'Government Girls Higher Secondary School Moro',
      );
      expect(
        PdfExportService.formatSchoolName('GHSS Nawabshah'),
        'Government Higher Secondary School Nawabshah',
      );
    });

    test('handles dots, hyphens, and casing variations', () {
      expect(
        PdfExportService.formatSchoolName('G.B.P.S. Mehar Ghanghro'),
        'Government Boys Primary School Mehar Ghanghro',
      );
      expect(
        PdfExportService.formatSchoolName('gbps mehar ghanghro'),
        'Government Boys Primary School mehar ghanghro',
      );
      expect(
        PdfExportService.formatSchoolName('GBPS-Mehar Ghanghro'),
        'Government Boys Primary School Mehar Ghanghro',
      );
      expect(
        PdfExportService.formatSchoolName('GBPS: Mehar Ghanghro'),
        'Government Boys Primary School Mehar Ghanghro',
      );
      expect(
        PdfExportService.formatSchoolName('GBPS'),
        'Government Boys Primary School',
      );
    });

    test('handles Govt. and Government prefixes', () {
      expect(
        PdfExportService.formatSchoolName('Govt. Boys Primary School Mehar'),
        'Government Boys Primary School Mehar',
      );
      expect(
        PdfExportService.formatSchoolName('Govt GBPS Mehar'),
        'Government Boys Primary School Mehar',
      );
      expect(
        PdfExportService.formatSchoolName('Government Boys Primary School Mehar Ghanghro'),
        'Government Boys Primary School Mehar Ghanghro',
      );
    });
  });

  group('PdfExportService.buildSchoolSubheader', () {
    test('builds complete subheader with SEMIS, District, City', () {
      final school = School(
        id: '1',
        schoolName: 'GBPS Mehar Ghanghro',
        semisCode: '408010254',
        district: 'Dadu',
        taluka: 'Mehar',
        createdBy: 'user',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(
        PdfExportService.buildSchoolSubheader(school),
        'SEMIS CODE: 408010254   |   DISTRICT: Dadu   |   CITY / TALUKA: Mehar',
      );
    });
  });
}
