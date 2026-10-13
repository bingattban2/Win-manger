import 'package:adwas_personnel/core/dates/business_date.dart';

/// All references use permanent IDs, never displayed Arabic names.
class SiteAssignment {
  const SiteAssignment(this.siteId, this.from, {this.toExclusive});
  final String siteId;
  final BusinessDate from;
  final BusinessDate? toExclusive;

  bool contains(BusinessDate date) => !date.isBefore(from) &&
      (toExclusive == null || date.isBefore(toExclusive!));

  bool intersects(BusinessMonth month) =>
      from.isBefore(month.next.firstDay) &&
      (toExclusive == null || month.firstDay.isBefore(toExclusive!));
}

class AttendanceState {
  const AttendanceState(this.date, this.siteId, this.statusId);
  final BusinessDate date;
  final String siteId;
  final String statusId;
}

class SiteTransfer {
  const SiteTransfer(this.date, this.fromSiteId, this.toSiteId);
  final BusinessDate date;
  final String fromSiteId;
  final String toSiteId;
}

enum DepartureKind { externalTransfer, dismissed }

class ForceDeparture {
  const ForceDeparture(this.date, this.kind, {this.destinationOrReason = ''});
  final BusinessDate date;
  final DepartureKind kind;
  final String destinationOrReason;
}

enum MonthlyMarker { transferOut, transferIn, externallyTransferred, dismissed }

/// Movement and attendance may coexist in one cell; markers are annotations,
/// NOT attendance status replacements.
class MonthlyCell {
  const MonthlyCell({this.statusId, this.marker, this.relatedSiteId});
  final String? statusId;
  final MonthlyMarker? marker;
  final String? relatedSiteId;
  bool get isEmpty => statusId == null && marker == null;
}

class PersonTimeline {
  PersonTimeline({
    required this.personId,
    required List<SiteAssignment> assignments,
    List<AttendanceState> attendance = const <AttendanceState>[],
    List<SiteTransfer> transfers = const <SiteTransfer>[],
    this.departure,
  })  : assignments = List<SiteAssignment>.unmodifiable(
            List<SiteAssignment>.of(assignments)..sort((a, b) => a.from.compareTo(b.from))),
        attendance = List<AttendanceState>.unmodifiable(attendance),
        transfers = List<SiteTransfer>.unmodifiable(
            List<SiteTransfer>.of(transfers)..sort((a, b) => a.date.compareTo(b.date))) {
    _validate();
  }

  final String personId;
  final List<SiteAssignment> assignments;
  final List<AttendanceState> attendance;
  final List<SiteTransfer> transfers;
  final ForceDeparture? departure;

  SiteAssignment? siteAt(BusinessDate date) {
    for (final assignment in assignments) {
      if (assignment.contains(date)) return assignment;
    }
    return null;
  }

  bool eligibleOn(BusinessDate date) =>
      (departure == null || date.isBefore(departure!.date)) && siteAt(date) != null;

  AttendanceState? attendanceAt(BusinessDate date) {
    for (final record in attendance) {
      if (record.date == date) return record;
    }
    return null;
  }

  Set<String> participatingSites(BusinessMonth month) {
    final result = <String>{};
    for (final assignment in assignments) {
      if (assignment.intersects(month)) result.add(assignment.siteId);
    }
    for (final transfer in transfers) {
      if (transfer.date.year == month.year && transfer.date.month == month.month) {
        result.add(transfer.fromSiteId);
        result.add(transfer.toSiteId);
      }
    }
    if (departure != null && departure!.date.year == month.year &&
        departure!.date.month == month.month) {
      final before = siteAt(departure!.date.shiftDays(-1));
      if (before != null) result.add(before.siteId);
    }
    return result;
  }

  MonthlyCell cellAt(String siteId, BusinessDate date) {
    if (departure != null && date == departure!.date) {
      final previous = siteAt(date.shiftDays(-1));
      if (previous?.siteId == siteId) {
        return MonthlyCell(marker: departure!.kind == DepartureKind.dismissed
            ? MonthlyMarker.dismissed : MonthlyMarker.externallyTransferred);
      }
    }
    for (final transfer in transfers) {
      if (transfer.date != date) continue;
      if (siteId == transfer.fromSiteId) {
        return MonthlyCell(marker: MonthlyMarker.transferOut,
            relatedSiteId: transfer.toSiteId);
      }
      if (siteId == transfer.toSiteId) {
        return MonthlyCell(marker: MonthlyMarker.transferIn,
            relatedSiteId: transfer.fromSiteId,
            statusId: attendanceAt(date)?.statusId);
      }
    }
    if (!eligibleOn(date) || siteAt(date)?.siteId != siteId) {
      return const MonthlyCell();
    }
    return MonthlyCell(statusId: attendanceAt(date)?.statusId);
  }

  void _validate() {
    if (personId.trim().isEmpty) throw StateError('person_id is required');
    SiteAssignment? previous;
    for (final assignment in assignments) {
      if (assignment.siteId.trim().isEmpty) throw StateError('site_id is required');
      if (assignment.toExclusive != null &&
          !assignment.from.isBefore(assignment.toExclusive!)) {
        throw StateError('Invalid assignment interval');
      }
      if (previous != null &&
          (previous.toExclusive == null || assignment.from.isBefore(previous.toExclusive!))) {
        throw StateError('Overlapping assignment intervals');
      }
      previous = assignment;
    }
    final seenTransferDates = <BusinessDate>{};
    for (final transfer in transfers) {
      if (!seenTransferDates.add(transfer.date)) {
        throw StateError('Same-day transfer conflicts are prohibited');
      }
      if (transfer.fromSiteId == transfer.toSiteId ||
          siteAt(transfer.date.shiftDays(-1))?.siteId != transfer.fromSiteId ||
          siteAt(transfer.date)?.siteId != transfer.toSiteId) {
        throw StateError('Transfer must agree with assignment intervals');
      }
      if (departure != null && !transfer.date.isBefore(departure!.date)) {
        throw StateError('Transfer is forbidden after departure');
      }
    }
    final seenAttendanceDates = <BusinessDate>{};
    for (final record in attendance) {
      if (!seenAttendanceDates.add(record.date)) {
        throw StateError('Duplicate official attendance');
      }
      if (!eligibleOn(record.date) || siteAt(record.date)?.siteId != record.siteId) {
        throw StateError('Attendance outside eligible site/date');
      }
    }
    if (departure != null &&
        siteAt(departure!.date.shiftDays(-1)) == null) {
      throw StateError('Departure requires a prior site');
    }
  }
}

class ForceTotals {
  const ForceTotals({required this.eligibleForce,
    required this.statusCounts, required this.unprepared});
  final int eligibleForce;
  final Map<String, int> statusCounts;
  final int unprepared;
  int get prepared => eligibleForce - unprepared;
  bool get reconciled =>
      eligibleForce == unprepared + statusCounts.values.fold<int>(0, (a, b) => a + b);
}

abstract final class ForceStatistics {
  static ForceTotals onDate({
    required BusinessDate date,
    required Iterable<PersonTimeline> persons,
    required Iterable<String> configuredStatusIds,
    String? siteId,
  }) {
    final counts = <String, int>{for (final id in configuredStatusIds) id: 0};
    final seen = <String>{};
    var force = 0;
    var unprepared = 0;
    for (final person in persons) {
      if (!seen.add(person.personId)) {
        throw StateError('Duplicate person timeline: ${person.personId}');
      }
      if (!person.eligibleOn(date) ||
          (siteId != null && person.siteAt(date)?.siteId != siteId)) {
        continue;
      }
      force++;
      final status = person.attendanceAt(date)?.statusId;
      if (status == null) {
        unprepared++;
      } else if (counts.containsKey(status)) {
        counts[status] = counts[status]! + 1;
      } else {
        throw StateError('Unknown historical attendance status: $status');
      }
    }
    return ForceTotals(eligibleForce: force, unprepared: unprepared,
        statusCounts: Map<String, int>.unmodifiable(counts));
  }
}
