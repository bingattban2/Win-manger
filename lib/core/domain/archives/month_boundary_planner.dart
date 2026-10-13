import 'package:adwas_personnel/core/dates/business_date.dart';

/// A side-effect-free catch-up plan; a later encrypted persistence adapter must
/// execute each archive+seal in ONE transaction before enabling writes.
class MonthBoundaryPlan {
  const MonthBoundaryPlan(this.monthsToSeal, this.activeMonth);
  final List<BusinessMonth> monthsToSeal;
  final BusinessMonth activeMonth;
  bool get requiresCatchUp => monthsToSeal.isNotEmpty;
}

abstract final class MonthBoundaryPlanner {
  static MonthBoundaryPlan plan({
    required BusinessMonth firstOperationalMonth,
    required BusinessDate launchDate,
    required Set<BusinessMonth> sealedMonths,
  }) {
    final activeMonth = BusinessMonth(launchDate.year, launchDate.month);
    if (firstOperationalMonth.compareTo(activeMonth) > 0) {
      throw StateError('First operational month cannot be in the future');
    }
    for (final sealed in sealedMonths) {
      if (sealed.compareTo(activeMonth) >= 0) {
        throw StateError('Current/future month must not be sealed');
      }
    }
    final missing = <BusinessMonth>[];
    var cursor = firstOperationalMonth;
    while (cursor.compareTo(activeMonth) < 0) {
      if (!sealedMonths.contains(cursor)) missing.add(cursor);
      cursor = cursor.next;
    }
    return MonthBoundaryPlan(List<BusinessMonth>.unmodifiable(missing), activeMonth);
  }

  static bool canWriteDate({
    required BusinessDate date,
    required BusinessDate today,
    required Set<BusinessMonth> sealedMonths,
  }) {
    final month = BusinessMonth(date.year, date.month);
    return month == BusinessMonth(today.year, today.month) &&
        !sealedMonths.contains(month) && !date.isOnOrAfter(today.shiftDays(1));
  }
}
