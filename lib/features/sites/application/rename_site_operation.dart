import 'package:adwas_personnel/core/audit/operation_audit.dart';
import 'package:adwas_personnel/core/errors/operation_failures.dart';
import 'package:adwas_personnel/core/security/account_policy.dart';
import 'package:adwas_personnel/core/security/operation_authorizer.dart';
import 'package:adwas_personnel/core/transactions/operation_pipeline.dart';
import 'package:adwas_personnel/features/sites/domain/site_record.dart';
import 'package:adwas_personnel/features/sites/repositories/site_repository.dart';

class RenameSiteCommand {
  const RenameSiteCommand(this.siteId, this.newName);

  final String siteId;
  final String newName;
}

/// Real application/domain operation; no widget executes SQL directly.
/// The repository methods must participate in the enclosing transaction.
class RenameSiteOperation
    extends BusinessOperation<RenameSiteCommand, SiteRecord, SiteRecord> {
  RenameSiteOperation(this.repository, {DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final SiteRepository repository;

  static String normalizeName(String input) =>
      input.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  @override
  String get operationType => 'SITE_RENAME';

  @override
  AppPermission get permission => AppPermission.siteManagement;

  @override
  RenameSiteCommand normalize(RenameSiteCommand input) => RenameSiteCommand(
    input.siteId.trim(),
    input.newName.trim().replaceAll(RegExp(r'\s+'), ' '),
  );

  @override
  void validate(RenameSiteCommand input) {
    if (input.siteId.isEmpty || input.newName.isEmpty ||
        input.newName.length > 120) {
      throw const OperationFailure(
        OperationFailureCode.invalidInput, 'Invalid site name or identifier',
      );
    }
  }

  @override
  Future<SiteRecord> readCurrent(RenameSiteCommand normalized) async {
    final record = await repository.byId(normalized.siteId);
    if (record == null) {
      throw const OperationFailure(
        OperationFailureCode.notFound, 'The selected site no longer exists',
      );
    }
    return record;
  }

  @override
  void checkPreconditions(RenameSiteCommand normalized, SiteRecord current) {
    if (current.isSystemSite || !current.isActive ||
        current.normalizedName == normalizeName(normalized.newName)) {
      throw const OperationFailure(
        OperationFailureCode.businessRule,
        'System, inactive, or unchanged sites cannot be renamed',
      );
    }
  }

  @override
  String revisionOf(SiteRecord current) =>
      '${current.id}:${current.updatedAtUtc}:${current.normalizedName}';

  @override
  OperationDescription describe(
    RenameSiteCommand normalized,
    SiteRecord current,
  ) => OperationDescription(
    title: 'تغيير اسم الموقع',
    targetType: 'SITE',
    targetId: current.id,
    oldValues: {'name': current.name},
    newValues: {'name': normalized.newName},
  );

  @override
  Future<SiteRecord> apply(
    RenameSiteCommand normalized,
    SiteRecord current,
    AuthorizedOperator actor,
  ) async {
    if (await repository.nameInUse(normalizeName(normalized.newName), current.id)) {
      throw const OperationFailure(
        OperationFailureCode.businessRule, 'The site name is already in use',
      );
    }
    final result = current.renamed(
      normalized.newName, normalizeName(normalized.newName),
      _clock().toUtc().toIso8601String(),
    );
    await repository.update(result);
    return result;
  }

  @override
  Future<void> recordHistory(
    RenameSiteCommand normalized,
    SiteRecord previous,
    SiteRecord result,
    AuthorizedOperator actor,
    String auditEventId,
  ) => repository.appendRenameHistory(
    siteId: previous.id,
    oldName: previous.name,
    newName: result.name,
    actorId: actor.accountId,
    auditEventId: auditEventId,
  );

  @override
  Future<void> checkInvariants(
    RenameSiteCommand normalized,
    SiteRecord result,
  ) async {
    final stored = await repository.byId(result.id);
    if (stored == null || stored.id != result.id ||
        stored.name != result.name ||
        stored.normalizedName != result.normalizedName ||
        stored.updatedAtUtc != result.updatedAtUtc) {
      throw StateError('Persisted site invariant failed');
    }
  }
}
