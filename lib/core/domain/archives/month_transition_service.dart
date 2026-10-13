import 'package:adwas_personnel/core/dates/business_date.dart';
import 'package:adwas_personnel/core/domain/archives/month_boundary_planner.dart';

/// Transactional port for a future verified *encrypted* database adapter.
/// Implementations MUST atomically snapshot attendance, assignments, status
/// names/codes/colors and events, compute/verify digest and seal the month.
/// Any failed step MUST roll back, leaving the month unsealed and no writes to
/// the following active month enabled.
abstract interface class MonthlyArchivePort {
  Future<Set<BusinessMonth>> readSealedMonths();
  Future<void> snapshotAndSealAtomically(BusinessMonth month);
}

/// Fail-closed month rollover orchestration. Call before enabling business
/// mutations at startup / on local calendar boundary once storage is ready.
class MonthTransitionService {
  const MonthTransitionService(this.archivePort);
  final MonthlyArchivePort archivePort;

  Future<BusinessMonth> catchUpBeforeWrites({
    required BusinessMonth firstOperationalMonth,
    required BusinessDate today,
  }) async {
    final plan = MonthBoundaryPlanner.plan(
      firstOperationalMonth: firstOperationalMonth,
      launchDate: today,
      sealedMonths: await archivePort.readSealedMonths(),
    );
    for (final month in plan.monthsToSeal) {
      await archivePort.snapshotAndSealAtomically(month);
      final sealed = await archivePort.readSealedMonths();
      if (!sealed.contains(month)) {
        throw StateError('Archive seal could not be verified: $month');
      }
    }
    return plan.activeMonth;
  }
}
