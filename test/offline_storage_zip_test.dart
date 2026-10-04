import 'dart:convert';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gr_book/services/offline_storage_service.dart';

void main() {
  group('OfflineStorageService ZIP Archive Tests', () {
    test('RestoreSummary has proper defaults and needsPermission flag', () {
      const summary = RestoreSummary(
        success: false,
        schoolName: '',
        classesCount: 0,
        studentsCount: 0,
        photosCount: 0,
        message: 'Permission denied',
        needsPermission: true,
      );

      expect(summary.success, isFalse);
      expect(summary.needsPermission, isTrue);
      expect(summary.message, contains('Permission denied'));
    });

    test('ZIP Archive encoding and decoding retains complete backup and photos', () {
      final archive = Archive();

      final backupData = {
        'backup_version': 2,
        'app_name': 'G.R BOOK',
        'school': {'school_name': 'Government Boys Primary School Mehar Ghanghro'},
        'students': [
          {'id': 'student-1', 'studentName': 'Ali Ahmed', 'grNumber': '101'},
        ],
      };

      final jsonBytes = utf8.encode(jsonEncode(backupData));
      archive.addFile(ArchiveFile('gr_book_complete_backup.json', jsonBytes.length, jsonBytes));

      final fakePhotoBytes = utf8.encode('FAKE_PHOTO_BYTES_PNG');
      archive.addFile(ArchiveFile('photos/photo_student-1_STUDENT.jpg', fakePhotoBytes.length, fakePhotoBytes));

      final zipEncoder = ZipEncoder();
      final encodedBytes = zipEncoder.encode(archive);
      expect(encodedBytes, isNotNull);
      expect(encodedBytes!.isNotEmpty, isTrue);

      final decodedArchive = ZipDecoder().decodeBytes(encodedBytes);
      expect(decodedArchive.length, equals(2));

      ArchiveFile? decodedJsonFile;
      ArchiveFile? decodedPhotoFile;

      for (final file in decodedArchive) {
        if (file.name == 'gr_book_complete_backup.json') {
          decodedJsonFile = file;
        } else if (file.name == 'photos/photo_student-1_STUDENT.jpg') {
          decodedPhotoFile = file;
        }
      }

      expect(decodedJsonFile, isNotNull);
      expect(decodedPhotoFile, isNotNull);

      final decodedJsonContent = utf8.decode(decodedJsonFile!.content as List<int>);
      final decodedMap = jsonDecode(decodedJsonContent) as Map<String, dynamic>;
      expect(decodedMap['app_name'], equals('G.R BOOK'));
      expect(decodedMap['school']['school_name'], equals('Government Boys Primary School Mehar Ghanghro'));
    });
  });
}
