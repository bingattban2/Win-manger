/// One authoritative Gregorian civil-date model. No UTC timestamp is used to
/// represent an attendance *date*; timestamps are UTC instants separately.
class BusinessDate implements Comparable<BusinessDate> {
  const BusinessDate._(this.year, this.month, this.day);

  factory BusinessDate(int year, int month, int day) {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      throw const FormatException('تاريخ ميلادي غير صالح');
    }
    final value = DateTime.utc(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      throw const FormatException('تاريخ ميلادي غير صالح');
    }
    return BusinessDate._(year, month, day);
  }

  factory BusinessDate.parse(String source) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(source)) {
      throw const FormatException('صيغة التاريخ المطلوبة YYYY-MM-DD');
    }
    return BusinessDate(
      int.parse(source.substring(0, 4)),
      int.parse(source.substring(5, 7)),
      int.parse(source.substring(8, 10)),
    );
  }

  factory BusinessDate.fromLocalDateTime(DateTime localDateTime) =>
      BusinessDate(localDateTime.year, localDateTime.month, localDateTime.day);

  final int year;
  final int month;
  final int day;

  DateTime get _utcCivil => DateTime.utc(year, month, day);
  int get weekday => _utcCivil.weekday;
  String get arabicWeekday => const <String>[
        'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'
      ][weekday - 1];
  String get weekdayAbbreviation => const <String>[
        'إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'
      ][weekday - 1];

  BusinessDate shiftDays(int offset) {
    final date = _utcCivil.add(Duration(days: offset));
    return BusinessDate(date.year, date.month, date.day);
  }

  @override
  int compareTo(BusinessDate other) => toString().compareTo(other.toString());
  bool isBefore(BusinessDate other) => compareTo(other) < 0;
  bool isOnOrAfter(BusinessDate other) => compareTo(other) >= 0;

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) => other is BusinessDate &&
      year == other.year && month == other.month && day == other.day;
  @override
  int get hashCode => Object.hash(year, month, day);
}

class BusinessMonth implements Comparable<BusinessMonth> {
  const BusinessMonth._(this.year, this.month);

  factory BusinessMonth(int year, int month) {
    if (year < 1 || year > 9999 || month < 1 || month > 12) {
      throw const FormatException('شهر ميلادي غير صالح');
    }
    return BusinessMonth._(year, month);
  }

  final int year;
  final int month;
  BusinessDate get firstDay => BusinessDate(year, month, 1);
  BusinessDate get lastDay => BusinessDate(year, month, daysInMonth);
  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;
  BusinessMonth get next => month == 12
      ? BusinessMonth(year + 1, 1)
      : BusinessMonth(year, month + 1);
  BusinessMonth get previous => month == 1
      ? BusinessMonth(year - 1, 12)
      : BusinessMonth(year, month - 1);
  List<BusinessDate> get dates => List<BusinessDate>.generate(
        daysInMonth, (index) => BusinessDate(year, month, index + 1));

  @override
  int compareTo(BusinessMonth other) =>
      year != other.year ? year.compareTo(other.year) : month.compareTo(other.month);
  @override
  bool operator ==(Object other) => other is BusinessMonth &&
      year == other.year && month == other.month;
  @override
  int get hashCode => Object.hash(year, month);
  @override
  String toString() => '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}';
}

/// Platform adapter receives UTC instants for audit and uses OS-local time for
/// business-date boundaries. Pure for deterministic tests.
abstract final class DateService {
  static BusinessDate todayAt(DateTime instant) =>
      BusinessDate.fromLocalDateTime(instant.toLocal());
  static String utcTimestamp(DateTime instant) => instant.toUtc().toIso8601String();
  static DateTime displayLocalTime(DateTime utcInstant) => utcInstant.toLocal();
}
