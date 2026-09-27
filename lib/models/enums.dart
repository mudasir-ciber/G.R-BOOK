enum StudentStatus { active, struckOff, passedOut }

extension StudentStatusX on StudentStatus {
  String get dbValue => switch (this) {
        StudentStatus.active => 'ACTIVE',
        StudentStatus.struckOff => 'STRUCK_OFF',
        StudentStatus.passedOut => 'PASSED_OUT',
      };

  static StudentStatus fromDb(String value) => switch (value) {
        'ACTIVE' => StudentStatus.active,
        'STRUCK_OFF' => StudentStatus.struckOff,
        'PASSED_OUT' => StudentStatus.passedOut,
        _ => throw ArgumentError('Unknown student status: $value'),
      };
}

enum PromotionStatus { none, promoted, failed }

extension PromotionStatusX on PromotionStatus {
  String get dbValue => switch (this) {
        PromotionStatus.none => 'NONE',
        PromotionStatus.promoted => 'PROMOTED',
        PromotionStatus.failed => 'FAILED',
      };

  static PromotionStatus fromDb(String value) => switch (value) {
        'NONE' => PromotionStatus.none,
        'PROMOTED' => PromotionStatus.promoted,
        'FAILED' => PromotionStatus.failed,
        _ => throw ArgumentError('Unknown promotion status: $value'),
      };
}

enum PhotoType { student, bForm, fatherCnic, token }

extension PhotoTypeX on PhotoType {
  String get dbValue => switch (this) {
        PhotoType.student => 'STUDENT',
        PhotoType.bForm => 'B_FORM',
        PhotoType.fatherCnic => 'FATHER_CNIC',
        PhotoType.token => 'TOKEN',
      };

  static PhotoType fromDb(String value) => switch (value) {
        'STUDENT' => PhotoType.student,
        'B_FORM' => PhotoType.bForm,
        'FATHER_CNIC' => PhotoType.fatherCnic,
        'TOKEN' => PhotoType.token,
        _ => throw ArgumentError('Unknown photo type: $value'),
      };
}

enum SchoolRole { owner, admin, teacher }

extension SchoolRoleX on SchoolRole {
  String get dbValue => switch (this) {
        SchoolRole.owner => 'owner',
        SchoolRole.admin => 'admin',
        SchoolRole.teacher => 'teacher',
      };

  static SchoolRole fromDb(String value) => switch (value) {
        'owner' => SchoolRole.owner,
        'admin' => SchoolRole.admin,
        'teacher' => SchoolRole.teacher,
        _ => throw ArgumentError('Unknown school role: $value'),
      };
}

/// Sync lifecycle for any locally-mutated row awaiting upload.
enum SyncState { synced, pendingCreate, pendingUpdate, pendingDelete, conflict }

/// App-wide connectivity/sync banner state (see requirement #27).
enum SyncBannerState { synced, syncing, offline, pendingChanges }
