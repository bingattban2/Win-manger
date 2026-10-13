import 'package:adwas_personnel/core/dates/business_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Gregorian dates preserve YYYY-MM-DD and reject impossible dates', () {
    expect(BusinessDate.parse('2026-10-13').toString(), '2026-10-13');
    expect(() => BusinessDate.parse('2026-02-29'), throwsFormatException);
    expect(() => BusinessDate.parse('2026-2-9'), throwsFormatException);
    expect(() => BusinessDate(2026, 13, 1), throwsFormatException);
  });

  test('leap year and lengths of all four month types', () {
    expect(BusinessMonth(2024, 2).daysInMonth, 29);
    expect(BusinessMonth(2026, 2).daysInMonth, 28);
    expect(BusinessMonth(2026, 4).daysInMonth, 30);
    expect(BusinessMonth(2026, 10).daysInMonth, 31);
    expect(BusinessMonth(2026, 10).dates.length, 31);
  });

  test('date and month crossings use civil dates, never UTC clock shifts', () {
    expect(BusinessDate.parse('2026-12-31').shiftDays(1).toString(), '2027-01-01');
    expect(BusinessMonth(2026, 12).next.toString(), '2027-01');
    expect(BusinessMonth(2026, 1).previous.toString(), '2025-12');
  });

  test('Arabic weekday labels come from the correct Gregorian weekday', () {
    expect(BusinessDate.parse('2026-10-13').arabicWeekday, 'الثلاثاء');
    expect(BusinessDate.parse('2026-10-16').weekdayAbbreviation, 'جم');
  });

  test('UTC operation timestamps are separate from business dates', () {
    expect(DateService.utcTimestamp(DateTime.utc(2026, 10, 13)),
        contains('2026-10-13T00:00:00'));
  });
}
