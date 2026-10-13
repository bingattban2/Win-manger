import 'package:adwas_personnel/core/dates/business_date.dart';
import 'package:adwas_personnel/core/domain/force/force_engine.dart';
import 'package:flutter_test/flutter_test.dart';

BusinessDate d(int day, {int month = 10}) => BusinessDate(2026, month, day);

PersonTimeline person({
  String id = 'p',
  List<SiteAssignment>? assignments,
  List<AttendanceState> attendance = const <AttendanceState>[],
  List<SiteTransfer> transfers = const <SiteTransfer>[],
  ForceDeparture? departure,
}) => PersonTimeline(
      personId: id,
      assignments: assignments ?? <SiteAssignment>[SiteAssignment('a', d(1))],
      attendance: attendance,
      transfers: transfers,
      departure: departure,
    );

ForceTotals totals(BusinessDate day, Iterable<PersonTimeline> people, {String? site}) =>
    ForceStatistics.onDate(date: day, persons: people,
        configuredStatusIds: const <String>['present', 'absent', 'custom'],
        siteId: site);

void main() {
  test('force = recorded statuses + unprepared; never equate missing with absent', () {
    final people = <PersonTimeline>[
      person(id: 'p', attendance: <AttendanceState>[AttendanceState(d(5), 'a', 'present')]),
      person(id: 'q'),
    ];
    final result = totals(d(5), people);
    expect(result.eligibleForce, 2);
    expect(result.unprepared, 1);
    expect(result.statusCounts['present'], 1);
    expect(result.statusCounts['absent'], 0);
    expect(result.reconciled, isTrue);
  });

  test('transfer day belongs to destination; markers coexist with attendance', () {
    final p = person(
      assignments: <SiteAssignment>[
        SiteAssignment('a', d(1), toExclusive: d(10)),
        SiteAssignment('b', d(10)),
      ],
      attendance: <AttendanceState>[
        AttendanceState(d(9), 'a', 'present'),
        AttendanceState(d(10), 'b', 'absent'),
      ],
      transfers: <SiteTransfer>[SiteTransfer(d(10), 'a', 'b')],
    );
    expect(totals(d(9), <PersonTimeline>[p], site: 'a').eligibleForce, 1);
    expect(totals(d(10), <PersonTimeline>[p], site: 'a').eligibleForce, 0);
    expect(totals(d(10), <PersonTimeline>[p], site: 'b').eligibleForce, 1);
    final from = p.cellAt('a', d(10));
    final to = p.cellAt('b', d(10));
    expect(from.marker, MonthlyMarker.transferOut);
    expect(from.statusId, isNull);
    expect(to.marker, MonthlyMarker.transferIn);
    expect(to.statusId, 'absent');
    expect(p.cellAt('a', d(11)).isEmpty, isTrue);
    expect(p.cellAt('b', d(9)).isEmpty, isTrue);
    expect(p.participatingSites(BusinessMonth(2026, 10)), {'a', 'b'});
  });

  test('multiple transfers in month do not overwrite historical days', () {
    final p = person(
      assignments: <SiteAssignment>[
        SiteAssignment('a', d(1), toExclusive: d(8)),
        SiteAssignment('b', d(8), toExclusive: d(20)),
        SiteAssignment('a', d(20)),
      ],
      transfers: <SiteTransfer>[
        SiteTransfer(d(8), 'a', 'b'),
        SiteTransfer(d(20), 'b', 'a'),
      ],
    );
    expect(p.cellAt('a', d(8)).marker, MonthlyMarker.transferOut);
    expect(p.cellAt('b', d(20)).marker, MonthlyMarker.transferOut);
    expect(p.cellAt('a', d(20)).marker, MonthlyMarker.transferIn);
    expect(totals(d(15), <PersonTimeline>[p], site: 'b').eligibleForce, 1);
    expect(totals(d(25), <PersonTimeline>[p], site: 'a').eligibleForce, 1);
  });

  test('the new month starts unprepared; attendance never carries over', () {
    final p = person(attendance: <AttendanceState>[
      AttendanceState(d(31), 'a', 'present'),
    ]);
    final november = BusinessDate(2026, 11, 1);
    expect(totals(d(31), <PersonTimeline>[p]).statusCounts['present'], 1);
    expect(totals(november, <PersonTimeline>[p]).unprepared, 1);
    expect(p.cellAt('a', november).statusId, isNull);
  });

  test('same-day transfer conflict is a deterministic error', () {
    expect(() => person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1), toExclusive: d(10)), SiteAssignment('b', d(10)),
    ], transfers: <SiteTransfer>[
      SiteTransfer(d(10), 'a', 'b'), SiteTransfer(d(10), 'a', 'b'),
    ]), throwsStateError);
  });

  test('dismissal appears on final site and preserves earlier count', () {
    final p = person(
      assignments: <SiteAssignment>[SiteAssignment('a', d(1), toExclusive: d(10))],
      attendance: <AttendanceState>[AttendanceState(d(9), 'a', 'present')],
      departure: ForceDeparture(d(10), DepartureKind.dismissed,
          destinationOrReason: 'سبب الفصل'),
    );
    expect(p.cellAt('a', d(10)).marker, MonthlyMarker.dismissed);
    expect(totals(d(9), <PersonTimeline>[p]).eligibleForce, 1);
    expect(totals(d(10), <PersonTimeline>[p]).eligibleForce, 0);
    expect(p.cellAt('a', d(11)).isEmpty, isTrue);
  });

  test('external transfer preserves history but is not eligible on departure day', () {
    final p = person(
      assignments: <SiteAssignment>[SiteAssignment('a', d(1), toExclusive: d(12))],
      departure: ForceDeparture(d(12), DepartureKind.externalTransfer,
          destinationOrReason: 'جهة أخرى'),
    );
    expect(p.cellAt('a', d(12)).marker, MonthlyMarker.externallyTransferred);
    expect(totals(d(11), <PersonTimeline>[p]).eligibleForce, 1);
    expect(totals(d(12), <PersonTimeline>[p]).eligibleForce, 0);
  });

  test('no official attendance outside effective site or after departure', () {
    expect(() => person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1), toExclusive: d(10)),
      SiteAssignment('b', d(10)),
    ], attendance: <AttendanceState>[
      AttendanceState(d(10), 'a', 'present'),
    ]), throwsStateError);
    expect(() => person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1), toExclusive: d(10)),
    ], departure: ForceDeparture(d(10), DepartureKind.dismissed),
        attendance: <AttendanceState>[
          AttendanceState(d(10), 'a', 'present'),
        ]), throwsStateError);
  });

  test('overlap, unknown status, and duplicate identity fail closed', () {
    expect(() => person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1), toExclusive: d(10)),
      SiteAssignment('b', d(9)),
    ]), throwsStateError);
    expect(() => totals(d(5), <PersonTimeline>[
      person(attendance: <AttendanceState>[
        AttendanceState(d(5), 'a', 'unrecognized')])]), throwsStateError);
    expect(() => totals(d(5), <PersonTimeline>[person(), person()]),
        throwsStateError);
  });

  test('transfer on last day preserves source history and starts destination', () {
    final p = person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1), toExclusive: d(31)),
      SiteAssignment('b', d(31)),
    ], transfers: <SiteTransfer>[SiteTransfer(d(31), 'a', 'b')]);
    expect(p.cellAt('a', d(30)).isEmpty, isTrue); // Unprepared, not absent.
    expect(totals(d(30), <PersonTimeline>[p], site: 'a').unprepared, 1);
    expect(p.cellAt('a', d(31)).marker, MonthlyMarker.transferOut);
    expect(p.cellAt('b', d(31)).marker, MonthlyMarker.transferIn);
    expect(totals(BusinessDate(2026, 11, 1), <PersonTimeline>[p],
        site: 'b').eligibleForce, 1);
  });

  test('transfer on first day has an outgoing marker in prior site', () {
    final p = person(assignments: <SiteAssignment>[
      SiteAssignment('a', d(1, month: 9), toExclusive: d(1)),
      SiteAssignment('b', d(1)),
    ], transfers: <SiteTransfer>[SiteTransfer(d(1), 'a', 'b')]);
    expect(p.cellAt('a', d(1)).marker, MonthlyMarker.transferOut);
    expect(p.participatingSites(BusinessMonth(2026, 10)), {'a', 'b'});
  });
}
