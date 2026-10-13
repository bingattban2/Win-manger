# Verification Strategy — Phases 00–42

## Acceptance gates and evidence levels

- **Prepared:** source artifacts and tests exist, but no external compilation has run.
- **Executed locally:** real command run with captured exit status and environment.
- **Verified on CI:** link and commit SHA of actual GitHub Actions run, full Windows build log and downloadable artifact.
- **Verified on Windows:** user or tester runs the executable and observes expected behavior on an actual Windows installation.

None of these levels may be presented as 'passed' without recorded evidence. On a failing phase, fix the cause in the **same repository**, rerun, and do not advance.

## Phase 00 — contract baseline verification

- `python scripts/build_traceability.py`: capture source-phase, line and ID mapping.
- `python scripts/validate_contract.py`: verify 43 phases, required documents, 400+ atomic entries, no false `VERIFIED` states and no plaintext bootstrap password in shipping source.
- Inspect all acceptance scenarios and confirm none are omitted.
- Human review of any policy ambiguity, especially effective dates, initial password provisioning, portable key recovery.
- Project owner accepts this requirements baseline before moving to phase 01.

## Early GitHub Windows smoke test (pre-phase-01 bootstrap)

1. Install stable Flutter on `windows-latest` and show `flutter doctor -v`.
2. Generate the native Windows runner in a separate temporary Flutter project; copy only `windows/` into the CI working tree (no overwriting authored source).
3. `flutter pub get`.
4. `dart format lib test` (format working copy in CI; strict format gate can follow after local toolchain is established).
5. `flutter analyze`.
6. `flutter test`.
7. `python scripts/validate_contract.py`.
8. `flutter build windows --release`.
9. Check actual Release directory contains EXE and package all Windows runtime files, not EXE alone.
10. Upload ZIP and SHA256 file as private-run workflow artifacts.
11. Run bundled executable on Windows; check Arabic bootstrap text, resizing and closed/reopened behavior.
12. **Stop and report outcome before phase 01**.

## Mandatory phase acceptance register

| Test ID | Phase | Completion check | Evidence status |
|---|---|---|---|
| P00-ACCEPT | 00 — Requirements Analysis And Traceability | Every requested function has a requirement ID and measurable acceptance criteria. | NOT RUN |
| P01-ACCEPT | 01 — Windows Development Environment | The initial desktop application launches successfully. | NOT RUN |
| P02-ACCEPT | 02 — Architecture, Dependency Injection, And State Management | A demonstration flow runs through UI, controller, service, and repository boundaries without architectural violations. | NOT RUN |
| P03-ACCEPT | 03 — Windows Storage, Process Lifecycle, And File Paths | Storage works for both an installed application and a portable application. | NOT RUN |
| P04-ACCEPT | 04 — Encrypted Sqlite Engine | The database persists encrypted records and cannot be read by an ordinary unencrypted SQLite connection. | NOT RUN |
| P05-ACCEPT | 05 — Complete Drift Database Schema | All core tables exist and all relationship constraints pass. | NOT RUN |
| P06-ACCEPT | 06 — Database Migration System | Older supported databases can be upgraded without losing personnel records. | NOT RUN |
| P07-ACCEPT | 07 — Temporal Engine And Force Calculation Services | Domain calculations remain correct without any UI. | NOT RUN |
| P08-ACCEPT | 08 — Audit Engine | No successful business mutation can bypass audit recording. | NOT RUN |
| P09-ACCEPT | 09 — Login, Authentication, And Session Security | Authentication and session security work completely offline. | NOT RUN |
| P10-ACCEPT | 10 — Arabic Rtl Design System | All shared components display correctly on Windows without using online assets. | NOT RUN |
| P11-ACCEPT | 11 — Site Management | Deleting a site never leaves current personnel without an assignment or destroys historical site records. | NOT RUN |
| P12-ACCEPT | 12 — Attendance Status Management | Adding a new status requires no code modifications to dashboard counters or reporting logic. | NOT RUN |
| P13-ACCEPT | 13 — Personnel Registry | Every person has one authoritative internal identity regardless of later site transfers. | NOT RUN |
| P14-ACCEPT | 14 — Automatic Excel Import | Repeated imports never create duplicate person identities. | NOT RUN |
| P15-ACCEPT | 15 — Smart Excel Import | Custom Excel columns become usable without editing the database schema. | NOT RUN |
| P16-ACCEPT | 16 — Dynamic Personnel Attributes And Column Layout | Adding, renaming, removing, or reordering displayed columns cannot break imports, reports, or monthly calculations. | NOT RUN |
| P17-ACCEPT | 17 — Shared Search And Filter Engine | Search behavior is consistent and performant across the entire application. | NOT RUN |
| P18-ACCEPT | 18 — Daily Preparation Workflow | Preparation updates all related screens without duplicate daily records. | NOT RUN |
| P19-ACCEPT | 19 — Attendance Completion Indicators | The indicator never confuses absence with missing preparation. | NOT RUN |
| P20-ACCEPT | 20 — Main Dashboard | Every dashboard number agrees with the corresponding authoritative daily attendance calculations. | NOT RUN |
| P21-ACCEPT | 21 — Monthly Accountability Grid | The grid displays accurate attendance and historical movements without freezing under tested workloads. | NOT RUN |
| P22-ACCEPT | 22 — Internal Transfer Screen And Transaction Engine | Several transfers in one month produce a correct and nonduplicated monthly history. | NOT RUN |
| P23-ACCEPT | 23 — Personnel Identity Correction | Historical reports still refer to the same person after identity correction. | NOT RUN |
| P24-ACCEPT | 24 — External Transfer | The person no longer counts toward active strength but remains fully available historically. | NOT RUN |
| P25-ACCEPT | 25 — Dismissal | Dismissal removes the individual from the active force without deleting historical service records. | NOT RUN |
| P26-ACCEPT | 26 — Monthly Archive Engine | Later changes to names, sites, statuses, or personnel lifecycle do not alter sealed archive values. | NOT RUN |
| P27-ACCEPT | 27 — Individual Reporting Engine | Individual totals match underlying attendance records and monthly historical data. | NOT RUN |
| P28-ACCEPT | 28 — Personnel List Export | Every named export option produces exactly the required files. | NOT RUN |
| P29-ACCEPT | 29 — Monthly Excel Export | Generated workbooks are tested for styling, frozen panes, RTL behavior, and correct historical data. | NOT RUN |
| P30-ACCEPT | 30 — Archive Export And Printing | Printing or exporting a previous month reproduces the same official archived values consistently. | NOT RUN |
| P31-ACCEPT | 31 — User Management Screen | Ordinary administrators cannot create or manage other ordinary administrators, and supervisors cannot access user management. | NOT RUN |
| P32-ACCEPT | 32 — Audit Log Screen | Audit records remain readable and filterable even when personnel identities or user accounts have subsequently changed. | NOT RUN |
| P33-ACCEPT | 33 — Manual Encrypted Backup | A backup created during normal application activity restores consistently. | NOT RUN |
| P34-ACCEPT | 34 — Encrypted Backup Restoration | An invalid or corrupted backup cannot destroy the currently working database. | NOT RUN |
| P35-ACCEPT | 35 — Automatic Daily Backup Scheduler | Scheduling works under documented Windows conditions, and missed backups are handled explicitly. | NOT RUN |
| P36-ACCEPT | 36 — Settings And Application Data Reset | Reset behavior is deliberate, authenticated, and accurately reported. | NOT RUN |
| P37-ACCEPT | 37 — Error Handling And Concurrency Hardening | Recoverable errors never leave business data partially committed. | NOT RUN |
| P38-ACCEPT | 38 — Performance Optimization | Performance is measured and optimized, not assumed. | NOT RUN |
| P39-ACCEPT | 39 — Security Verification | No identified critical security defect remains unresolved. | NOT RUN |
| P40-ACCEPT | 40 — Automated Functional And Integration Testing | All mandatory functional and integration tests pass. | NOT RUN |
| P41-ACCEPT | 41 — Github Actions Continuous Integration | A clean Windows CI runner can validate and build the project reproducibly. | NOT RUN |
| P42-ACCEPT | 42 — Windows Installer, Portable Package, And Final Acceptance | All original phase-specific checks and acceptance assertions are verified. | NOT RUN |

## Real-world scenarios from the source specification

| Scenario | Test fixture | Essential assertion |
|---|---|---|
| A — Initial Setup | New encrypted DB | Offline admin login, three sites, protected undefined site, four system statuses and custom status |
| B — Import Personnel | 500 synthetic persons, duplicate numbers, mixed digits/names, missing sites | Valid rows imported, each conflict rejected with reason, re-import idempotent |
| C — Daily Attendance | Site A with selected statuses plus unprepared | Prepared totals reconcile; corrections audited and reflected in monthly grid |
| D — Internal Transfer | Site A → B on day 13, B → C on day 20 | Correct daily ownership, markers, historical continuity, zero duplication |
| E — Dismissal | Person with prior attendance and site history | Required reason and countdown; leave active count, monthly marker and archive retained |
| F — Month Closure | Month containing attendance and transfers, then rename identity and site | Auto seal exactly once; historical snapshots unchanged; edit refused |
| G — Backup Recovery | Encrypted DB copied to a second Windows machine | Correct recovery succeeds, wrong key/tamper fails without destroying working DB |

## Performance and security suites

- Execute query/frame/memory tests with **1k, 5k, 10k, 20k** synthetic persons.
- Verify invalid/contradictory movement, unsupported Excel formats, disk-full, inaccessible drive, interrupted backup/restore and unauthorized service-level invocation.
- Inspect release packages for lack of plaintext DB, keys or sensitive inputs and verify full offline use.
- End-to-end and regression cases record seed state, acting user, action, database mutation, UI change, audit event, historical projection and post-restart outcome.

## Evidence log template (one entry per test run)

- Date/time and timezone:
- Phase / test ID / commit SHA:
- Machine or CI runner:
- Command or user steps:
- Expected result:
- Actual result:
- PASS/FAIL/BLOCKED:
- Logs/screenshot/artifact URL:
- Defects and fixes:
- Reviewer confirmation:
