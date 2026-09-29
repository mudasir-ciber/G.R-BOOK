class StudentComplaint {
  const StudentComplaint({
    required this.id,
    required this.schoolId,
    required this.studentId,
    required this.studentName,
    required this.grNumber,
    required this.className,
    required this.parentName,
    required this.parentMobile,
    required this.complaintText,
    this.localPhotoPath,
    this.remotePhotoUrl,
    required this.communicationMethod,
    required this.communicationStatus,
    required this.createdAt,
    this.syncState = 'pendingCreate',
  });

  final String id;
  final String schoolId;
  final String studentId;
  final String studentName;
  final String grNumber;
  final String className;
  final String parentName;
  final String parentMobile;
  final String complaintText;
  final String? localPhotoPath;
  final String? remotePhotoUrl;
  final String communicationMethod; // 'Shared via WhatsApp', 'Shared via SMS', 'Shared via Share'
  final String communicationStatus; // 'SENT', 'SAVED'
  final DateTime createdAt;
  final String syncState;

  Map<String, dynamic> toMap() => {
        'id': id,
        'school_id': schoolId,
        'student_id': studentId,
        'student_name': studentName,
        'gr_number': grNumber,
        'class_name': className,
        'parent_name': parentName,
        'parent_mobile': parentMobile,
        'complaint_text': complaintText,
        'local_photo_path': localPhotoPath,
        'remote_photo_url': remotePhotoUrl,
        'communication_method': communicationMethod,
        'communication_status': communicationStatus,
        'created_at': createdAt.toIso8601String(),
        'sync_state': syncState,
      };

  factory StudentComplaint.fromMap(Map<String, dynamic> map) => StudentComplaint(
        id: map['id'] as String,
        schoolId: map['school_id'] as String,
        studentId: map['student_id'] as String,
        studentName: map['student_name'] as String? ?? '',
        grNumber: map['gr_number'] as String? ?? '',
        className: map['class_name'] as String? ?? '',
        parentName: map['parent_name'] as String? ?? '',
        parentMobile: map['parent_mobile'] as String? ?? '',
        complaintText: map['complaint_text'] as String,
        localPhotoPath: map['local_photo_path'] as String?,
        remotePhotoUrl: map['remote_photo_url'] as String?,
        communicationMethod: map['communication_method'] as String? ?? 'Shared via Share',
        communicationStatus: map['communication_status'] as String? ?? 'SENT',
        createdAt: DateTime.parse(map['created_at'] as String),
        syncState: map['sync_state'] as String? ?? 'synced',
      );
}
