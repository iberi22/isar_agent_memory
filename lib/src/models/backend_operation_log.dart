import 'package:isar/isar.dart';

part 'backend_operation_log.g.dart';

/// Operational logs for backend synchronization and database operations.
@collection
class BackendOperationLog {
  /// Unique identifier managed by Isar.
  Id id = Isar.autoIncrement;

  /// Timestamp of the operation.
  @Index()
  late DateTime timestamp;

  /// Type of operation (e.g., 'sync', 'db_query', 'api_call', 'error').
  late String operationType;

  /// Status of the operation ('success', 'failed', 'pending').
  late String status;

  /// Error message if the operation failed.
  String? errorMessage;

  /// Duration of the operation in milliseconds.
  int? durationMs;

  /// ID of the affected node, if any.
  String? nodeId;

  /// ID of the associated patient, if any.
  String? patientId;

  /// Tenant identifier for multi-tenancy.
  @Index(composite: [CompositeIndex('status')])
  late String tenantId;

  BackendOperationLog({
    DateTime? timestamp,
    required this.operationType,
    required this.status,
    this.errorMessage,
    this.durationMs,
    this.nodeId,
    this.patientId,
    required this.tenantId,
  }) : timestamp = timestamp ?? DateTime.now();
}
