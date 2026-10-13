# PART IV — Implementation and verification report (0.0.4)

## Scope delivered

PART IV sections **6, 7, 8, 9, 10**, grounded in the specification, while keeping all PART III definitions and tests unchanged.

| Requirement | Implemented element | Verification |
|---|---|---|
| No physical deletion of historical persons | Existing `trg_persons_no_delete` and immutable event triggers; lifecycle transition trigger linked to formal departure event | Python 14–19,25,27 |
| Date/site specific eligible force | `ForceStatistics.onDate`, parameterized `part_iv_statistics.sql`, no current-status shortcut | Python 01–06,27,32; Dart `force_engine_test.dart` |
| Sum of statuses + unprepared = eligible | `ForceTotals.reconciled` and `__UNPREPARED__` SQL grouping | Python 02–04,32; Dart tests |
| Transfer day belongs to new site | half-open assignment resolution and event validation | Python 06–13,22,28,31; Dart tests |
| Departure day retains a marker but excludes from active force | `MonthlyMarker.dismissed/externallyTransferred`, two departure SQL guards | Python 15–19,26–27; Dart tests |
| Prior days/history remain unchanged | event append-only, immutable archive checks, date effective filtering | Python 15–16,20–23,25–27 |
| Gregorian business date & Arabic weekdays | `BusinessDate`, `BusinessMonth`, `DateService` | `business_date_test.dart` |
| Months missed while app closed | pure `MonthBoundaryPlanner`, ordered fail-closed `MonthTransitionService` | `month_boundary_planner_test.dart`, `month_transition_service_test.dart` |
| Post-seal mutation prohibited | Base snapshot triggers + overlay guards for attendance and assignments | Python 20–23,26 |
| Failure atomicity | SQLite transactions rollback invalid transfers | Python test 29 |

## Binding operational decisions

1. **A transfer date is destination-owned**. Former site displays `transferOut`; destination displays `transferIn` and can simultaneously show that day's attendance. Transfer annotations are never official attendance statuses.
2. A person can have **at most one transfer per civil date**. Attempts to enter multiple movements on one date fail deterministically, rather than silently choosing a winning site.
3. The archival operator must process missing months **oldest to newest**, seal only a complete month, and **verify sealing before allowing current-month writes**. It must never copy prior-month daily statuses into a new month.
4. Current `persons.lifecycle_status` is not used to compute historical eligibility; the event `effective_date` and assignment intervals determine historical status.
5. `attendance_date` represents an ISO-formatted Gregorian date without time; mutation/diagnostic timestamps use UTC; dates are derived from the configured OS local clock.
6. The SQL overlay is an additive constraint extension to `schema_v1.sql`, **not** a working persistent migration. Versioned migration registration occurs in the designated encrypted persistence/migration phases.

## Verified now versus future integration

**Verified here:** 58 Python tests on actual in-memory SQLite, including 33 PART IV cases. Dart pure-domain and widget tests are authored but **Flutter/Dart toolchains are not installed in this local working environment**. GitHub Actions provides the authoritative Windows compile/Flutter-test result.

**Not yet enabled:** persistent disk-backed encrypted SQLite, UI mutations or login, production event-command transaction handlers, clock-driven scheduling, and real month snapshot/archive writing. `MonthTransitionService` defines the interface and fail-closed sequencing but cannot run from app startup without the encrypted archive store. The archival snapshot engine with full name/site/status history, hashes and transaction rollback belongs in the later dedicated archival phase; claiming an automatic archival production feature now would be misleading.

## Regression safeguards

The CI workflow still performs all earlier test suites and contract traceability verification (43 phases, 1021 traceable source items). Flutter/Dart dependency caches are retained. No network service was introduced into runtime and the Windows app name remains `التمام اليومي`.

## GitHub acceptance checklist

- [ ] `Validate Part III + Part IV SQLite business integrity` succeeds.
- [ ] `flutter analyze` succeeds.
- [ ] `flutter test` succeeds.
- [ ] Windows release build succeeds.
- [ ] Portable artifact is downloadable and the Arabic executable launches.
- [ ] Further features are paused until verification.
