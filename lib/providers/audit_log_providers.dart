import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import '../repositories/audit_log_repository.dart';

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(ref.watch(appDatabaseProvider));
});

typedef AuditLogArgs = ({String schoolId, String? studentId});

final auditLogsProvider = StreamProvider.family((ref, AuditLogArgs args) {
  return ref.watch(auditLogRepositoryProvider).watchLogs(schoolId: args.schoolId, studentId: args.studentId);
});
