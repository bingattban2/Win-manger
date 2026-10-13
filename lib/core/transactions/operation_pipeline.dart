import 'dart:math';

import 'package:adwas_personnel/core/audit/operation_audit.dart';
import 'package:adwas_personnel/core/errors/operation_failures.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/authentication_service.dart';
import 'package:adwas_personnel/core/security/operation_authorizer.dart';

/// The native SQLite implementation MUST bind every repository/audit call to
/// the same exclusive transaction/connection. It owns commit and rollback.
abstract interface class TransactionExecutor {
  Future<T> runInTransaction<T>(Future<T> Function() transactionBody);
}

/// Refresh only after commit. A refresh problem does NOT undo committed data.
abstract interface class OperationStateInvalidator {
  Future<void> invalidate(String operationType, String targetId);
}

/// A handler supplies the domain-specific steps, never SQL from a widget.
/// Every operation MUST provide history, audit description, and invariants.
abstract class BusinessOperation<Command, Snapshot, Result> {
  String get operationType;
  AppPermission get permission;

  Command normalize(Command input);
  void validate(Command input);
  Future<Snapshot> readCurrent(Command normalized);
  void checkPreconditions(Command normalized, Snapshot current);
  String revisionOf(Snapshot current);
  OperationDescription describe(Command normalized, Snapshot current);
  Future<Result> apply(
    Command normalized,
    Snapshot current,
    AuthorizedOperator actor,
  );
  Future<void> recordHistory(
    Command normalized,
    Snapshot previous,
    Result result,
    AuthorizedOperator actor,
    String auditEventId,
  );
  Future<void> checkInvariants(Command normalized, Result result);
}

/// A preview can only be consumed once by its issuing coordinator instance.
class PreparedOperation<Command> {
  const PreparedOperation._({
    required this.id,
    required this.actorId,
    required this.normalized,
    required this.expectedRevision,
    required this.description,
  });

  final String id;
  final String actorId;
  final Command normalized;
  final String expectedRevision;
  final OperationDescription description;
}

class OperationReceipt<Result> {
  const OperationReceipt({
    required this.result,
    required this.auditEventId,
    required this.committedAtUtc,
    required this.projectionUpdated,
  });

  final Result result;
  final String auditEventId;
  final DateTime committedAtUtc;
  final bool projectionUpdated;
}

/// 18-stage audited mutation pipeline. There is no production transaction
/// adapter until encrypted SQLite is implemented, so this is fail-closed by
/// dependency injection rather than using an unencrypted fallback.
class OperationCoordinator<Command, Snapshot, Result> {
  OperationCoordinator({
    required this.operation,
    required this.authorizer,
    required this.transactions,
    required this.audit,
    required this.invalidator,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final BusinessOperation<Command, Snapshot, Result> operation;
  final OperationAuthorizer authorizer;
  final TransactionExecutor transactions;
  final OperationAuditWriter audit;
  final OperationStateInvalidator invalidator;
  final DateTime Function() _clock;

  final Map<String, PreparedOperation<Command>> _issued = {};
  final Random _random = Random.secure();

  String _newId() => List<int>.generate(16, (_) => _random.nextInt(256))
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();

  /// Steps 1-9: normalize, validate, verify session and access, inspect,
  /// check business rules and issue an explicit, single-use preview.
  Future<PreparedOperation<Command>> prepare({
    required LocalSession session,
    required Command command,
  }) async {
    final normalized = operation.normalize(command);
    operation.validate(normalized);
    final actor = await authorizer.require(session, operation.permission);
    final current = await operation.readCurrent(normalized);
    operation.checkPreconditions(normalized, current);
    final description = operation.describe(normalized, current);
    final prepared = PreparedOperation<Command>._(
      id: _newId(),
      actorId: actor.accountId,
      normalized: normalized,
      expectedRevision: operation.revisionOf(current),
      description: description,
    );
    _issued[prepared.id] = prepared;
    return prepared;
  }

  /// Steps 10-18. Reauthorize and recheck inside a true transaction.
  /// Any failure in update/history/audit/invariants MUST trigger rollback.
  Future<OperationReceipt<Result>> execute({
    required LocalSession session,
    required PreparedOperation<Command> prepared,
    required bool confirmed,
  }) async {
    if (!identical(_issued[prepared.id], prepared)) {
      throw const OperationFailure(
        OperationFailureCode.alreadySubmitted,
        'Invalid, expired, or already submitted operation preview',
      );
    }
    if (!confirmed) {
      throw const OperationFailure(
        OperationFailureCode.confirmationRequired,
        'Explicit confirmation is required',
      );
    }
    // Invalidate the preview BEFORE execution: retries require new preflight.
    _issued.remove(prepared.id);
    final actor = await authorizer.require(session, operation.permission);
    if (actor.accountId != prepared.actorId) {
      throw const OperationFailure(
        OperationFailureCode.permissionDenied,
        'The original operator must confirm this change',
      );
    }

    final committed = await transactions.runInTransaction(() async {
      final current = await operation.readCurrent(prepared.normalized);
      if (operation.revisionOf(current) != prepared.expectedRevision) {
        throw const OperationFailure(
          OperationFailureCode.stalePreview,
          'Records changed after preview; prepare again',
        );
      }
      operation.checkPreconditions(prepared.normalized, current);
      final freshDescription = operation.describe(prepared.normalized, current);
      final auditId = _newId();
      final result = await operation.apply(prepared.normalized, current, actor);
      await operation.recordHistory(
        prepared.normalized,
        current,
        result,
        actor,
        auditId,
      );
      await audit.append(OperationAuditEvent(
        id: auditId,
        operationType: operation.operationType,
        description: freshDescription,
        actorId: actor.accountId,
        actorRole: actor.role,
        executedAtUtc: _clock().toUtc(),
      ));
      await operation.checkInvariants(prepared.normalized, result);
      return (result: result, auditId: auditId);
    });

    // This point is reached ONLY if the transaction has committed.
    var refreshed = true;
    try {
      await invalidator.invalidate(
        operation.operationType,
        prepared.description.targetId,
      );
    } catch (_) {
      refreshed = false;
    }
    return OperationReceipt<Result>(
      result: committed.result,
      auditEventId: committed.auditId,
      committedAtUtc: _clock().toUtc(),
      projectionUpdated: refreshed,
    );
  }
}
