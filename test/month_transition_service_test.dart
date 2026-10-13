import 'package:adwas_personnel/core/dates/business_date.dart';
import 'package:adwas_personnel/core/domain/archives/month_transition_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeArchives implements MonthlyArchivePort {
  _FakeArchives([Set<BusinessMonth>? alreadySealed])
      : sealed = alreadySealed ?? <BusinessMonth>{};
  final Set<BusinessMonth> sealed;
  final List<BusinessMonth> processed = <BusinessMonth>[];
  BusinessMonth? failMonth;
  bool falselyReportSuccess = false;

  @override
  Future<Set<BusinessMonth>> readSealedMonths() async =>
      Set<BusinessMonth>.of(sealed);

  @override
  Future<void> snapshotAndSealAtomically(BusinessMonth month) async {
    if (failMonth == month) throw StateError('Simulated archive failure');
    processed.add(month);
    if (!falselyReportSuccess) sealed.add(month);
  }
}

void main() {
  test('catch-up closes missing months once, oldest first', () async {
    final gateway = _FakeArchives(<BusinessMonth>{BusinessMonth(2026, 7)});
    final service = MonthTransitionService(gateway);
    final active = await service.catchUpBeforeWrites(
      firstOperationalMonth: BusinessMonth(2026, 7),
      today: BusinessDate(2026, 10, 13),
    );
    expect(active, BusinessMonth(2026, 10));
    expect(gateway.processed, <BusinessMonth>[
      BusinessMonth(2026, 8), BusinessMonth(2026, 9)]);
    await service.catchUpBeforeWrites(
      firstOperationalMonth: BusinessMonth(2026, 7),
      today: BusinessDate(2026, 10, 13),
    );
    expect(gateway.processed.length, 2);
  });

  test('archive failure propagates and prevents completing next month', () async {
    final gateway = _FakeArchives()..failMonth = BusinessMonth(2026, 9);
    final service = MonthTransitionService(gateway);
    await expectLater(service.catchUpBeforeWrites(
      firstOperationalMonth: BusinessMonth(2026, 8),
      today: BusinessDate(2026, 10, 13),
    ), throwsStateError);
    expect(gateway.processed, <BusinessMonth>[BusinessMonth(2026, 8)]);
  });

  test('false success without a sealed archive fails closed', () async {
    final gateway = _FakeArchives()..falselyReportSuccess = true;
    await expectLater(MonthTransitionService(gateway).catchUpBeforeWrites(
      firstOperationalMonth: BusinessMonth(2026, 9),
      today: BusinessDate(2026, 10, 13),
    ), throwsStateError);
  });
}
