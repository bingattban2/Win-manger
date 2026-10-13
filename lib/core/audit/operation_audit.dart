import 'package:adwas_personnel/core/security/account_policy.dart';

/// Immutable description of an operation, never includes password/token data.
class OperationDescription {
  const OperationDescription({
    required this.title,
    required this.targetType,
    required this.targetId,
    required this.oldValues,
    required this.newValues,
  });

  final String title;
  final String targetType;
  final String targetId;
  final Map<String, String> oldValues;
  final Map<String, String> newValues;
}

/// Write this record on the SAME database transaction as the mutation.
class OperationAuditEvent {
  const OperationAuditEvent({
    required this.id,
    required this.operationType,
    required this.description,
    required this.actorId,
    required this.actorRole,
    required this.executedAtUtc,
  });

  final String id;
  final String operationType;
  final OperationDescription description;
  final String actorId;
  final AppRole actorRole;
  final DateTime executedAtUtc;
}

abstract interface class OperationAuditWriter {
  Future<void> append(OperationAuditEvent event);
}
