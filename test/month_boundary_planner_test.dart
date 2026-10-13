import 'package:adwas_personnel/core/dates/business_date.dart';
import 'package:adwas_personnel/core/domain/archives/month_boundary_planner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new month catches up each missing completed month exactly once', () {
    final plan = MonthBoundaryPlanner.plan(
      firstOperationalMonth: BusinessMonth(2026, 7),
      launchDate: BusinessDate(2026, 10, 13),
      sealedMonths: <BusinessMonth>{BusinessMonth(2026, 7)},
    );
    expect(plan.monthsToSeal.map((m) => m.toString()).toList(),
        <String>['2026-08', '2026-09']);
    expect(plan.activeMonth.toString(), '2026-10');
  });

  test('launch inside active month never archives active month', () {
    final plan = MonthBoundaryPlanner.plan(
      firstOperationalMonth: BusinessMonth(2026, 10),
      launchDate: BusinessDate(2026, 10, 1),
      sealedMonths: <BusinessMonth>{},
    );
    expect(plan.monthsToSeal, isEmpty);
  });

  test('sealed month and future dates cannot be modified', () {
    final today = BusinessDate(2026, 10, 13);
    expect(MonthBoundaryPlanner.canWriteDate(
      date: BusinessDate(2026, 9, 30), today: today,
      sealedMonths: <BusinessMonth>{BusinessMonth(2026, 9)}), isFalse);
    expect(MonthBoundaryPlanner.canWriteDate(
      date: BusinessDate(2026, 10, 14), today: today,
      sealedMonths: <BusinessMonth>{}), isFalse);
    expect(MonthBoundaryPlanner.canWriteDate(
      date: BusinessDate(2026, 10, 1), today: today,
      sealedMonths: <BusinessMonth>{}), isTrue);
  });

  test('future or current sealed month is rejected', () {
    expect(() => MonthBoundaryPlanner.plan(
      firstOperationalMonth: BusinessMonth(2026, 9),
      launchDate: BusinessDate(2026, 10, 13),
      sealedMonths: <BusinessMonth>{BusinessMonth(2026, 10)}), throwsStateError);
  });
}
