import 'package:adwas_personnel/core/audit/operation_audit.dart';
import 'package:adwas_personnel/core/security/operation_authorizer.dart';
import 'package:adwas_personnel/core/transactions/operation_pipeline.dart';
import 'package:adwas_personnel/features/sites/application/rename_site_operation.dart';
import 'package:adwas_personnel/features/sites/domain/site_record.dart';
import 'package:adwas_personnel/features/sites/repositories/site_repository.dart';

/// Composition root: dependencies are supplied explicitly by the bootstrap.
/// No feature widget creates its own database connection or authorization.
class ApplicationServices {
  const ApplicationServices({
    required this.authorizer,
    required this.transactions,
    required this.audit,
    required this.invalidator,
    required this.sites,
  });

  final OperationAuthorizer authorizer;
  final TransactionExecutor transactions;
  final OperationAuditWriter audit;
  final OperationStateInvalidator invalidator;
  final SiteRepository sites;

  OperationCoordinator<RenameSiteCommand, SiteRecord, SiteRecord>
      createRenameSiteCoordinator() => OperationCoordinator(
        operation: RenameSiteOperation(sites),
        authorizer: authorizer,
        transactions: transactions,
        audit: audit,
        invalidator: invalidator,
      );
}
