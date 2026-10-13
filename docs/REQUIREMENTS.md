# Requirements Baseline — 2026-10-13

## Authority and interpretation

The complete user-supplied 43-phase specification is preserved as `SOURCE_SPECIFICATION_REDACTED.txt` with the initial administrator password deliberately redacted from the repository copy. Redaction is a repository-hygiene operation, **not a change to the specified credentials**; the password is available from the owner's original instruction, and will be provisioned securely in phase 09. The source remains the functional authority over this digest.

This project follows **phase 00 through phase 42** sequentially and uses phase acceptance gates. Each traceability row refers to an exact source line; no atomic work item is considered implemented merely because it is listed in the matrix.

## Non-negotiable requirements

| ID | Requirement | Phase(s) | Acceptance criterion |
|---|---|---|---|
| CORE-001 | Flutter/Dart desktop for Windows | 01,42 | A Windows build starts and closes normally on a clean test machine |
| CORE-002 | Private GitHub repository | 01,41 | Source repository is Private; actions do not publish publicly |
| CORE-003 | Completely offline runtime | 03,39,42 | Normal operations function with outbound connections blocked |
| CORE-004 | Every production person/site/attendance/account record stays local | 03–06 | No external data services or remote databases |
| CORE-005 | Encrypted local SQLite persistence | 04,39 | Raw file cannot be opened using plain SQLite; release key setup tested |
| CORE-006 | Installer plus Portable | 42 | Both packages run and survive restart/offline test |
| CORE-007 | No omitted legacy contract function | 00–42 | Each atomic contract requirement has traced implementation and evidence |
| CORE-008 | Real workflows, no simulated functional buttons | 02–42 | UI actions drive validated application services; screenshots alone fail |
| CORE-009 | Accurate append-only historical movements | 05,07,22–26 | Repeated transfers/dismissal never rewrite service history |
| CORE-010 | Exact force count conservation | 07,18–22 | Eligible = configured status counts + unprepared, for every site/date |
| CORE-011 | Full Arabic RTL | 10,21,29,42 | Windows RTL visual, keyboard, Excel RTL tests pass |
| CORE-012 | Phase acceptance after real tests | 00–42 | Test and actual execution results recorded; no fabricated successes |
| CORE-013 | Existing features preserved across phases | 00–42 | Regression suite run on each meaningful delivery |
| CORE-014 | Unsupported exceptional paths rejected explicitly | 02–42 | Failure matrix covers invalid input, corruption, access, storage conditions |
| CORE-015 | All personnel data absent from GitHub | 01,39 | Scan repository; only synthetic fixtures allowed |
| CORE-016 | Foundational admin with exact user-specified credentials | 09,31,39 | User-provided credentials authenticate without hints/forced change |
| CORE-017 | Three-tier permissions as specified | 09,31 | General manages ordinary+supervisor; ordinary supervisor only; supervisors do not manage accounts |
| CORE-018 | Dynamic Excel import, rejects conflicts per row group | 14,15 | New sites, columns; duplicate IDs rejected with reasons; valid rows inserted |
| CORE-019 | Monthly grid with four pinned RTL columns | 16,21 | Fixed identity columns, vertically fixed header, scrollable dates |
| CORE-020 | Sealed monthly archive, immutable snapshots | 26 | Changing current person/site/status doesn't alter closed month's snapshot |
| CORE-021 | User-selected export destination and formats | 28–30 | Combined and site files preserve text IDs, markers and RTL |
| CORE-022 | Encrypted manual/daily backup and recoverability | 33–35 | Tampered backup rejected; alternative Windows machine restore tested |
| CORE-023 | Default backup time at 4:00 PM Windows local time | 35 | Scheduling/catch-up tests with application closed or PC off |
| CORE-024 | Entire application reset with password and countdown | 36 | Reset scope explicit, protected and audited; unavailable drive caveat shown |
| CORE-025 | All operations auditable | 08,32 | Mutations and export/import/backup linked to actor and timestamp |
| CORE-026 | 1k/5k/10k/20k dataset performance | 21,38 | Frame timings, memory and query performance measured on Windows |

## Functional domains

- Identity: immutable `person_id`, unique normalized personnel number stored as text, complete identity history.
- Organization: protected `غير محدد` system site, site history and nonoverlapping effective assignment intervals.
- Attendance: one official daily record per person/date; movement markers are distinct projections, not attendance statuses.
- Lifecycle: active, external transfer and dismissal are lifecycle states; historical rows are retained.
- Authentication: offline, verifier-based password storage, local sessions, audit of login attempts.
- Roles: policy verified in application/domain services (navigation hiding is insufficient).
- Month boundary: close/seal previous month exactly once; new month starts unprepared, including after downtime.
- Excel: strict duplicate handling, dynamic columns, 4 pinned identifiers, official status colors/abbreviations.
- Backup: consistent DB snapshot, authenticated ciphertext, local Windows scheduling, cross-device recovery material.
- Delivery: same repository, tested increments, Windows x64 CI, installable and portable final versions.

## Traceability source

`TRACEABILITY_MATRIX.csv` has **1021 source-line-linked work items** from all engineering phases, with `PLANNED/NOT_RUN` initial statuses. The rows are an *engineering capture* of numbered/bulleted instructions, not claims that every workflow has been tested. Additional top-level invariants are summarized above. After each phase, add actual test evidence and update execution status; do not downgrade requirements to make a build pass.

## Open implementation decisions (must be resolved before related coding)

1. Application's final product title/Windows publisher identifier: interim working names `نظام إدارة شؤون الأفراد` / `com.adwas`.
2. Same-day repeated internal movement: recommended policy = refuse the second conflicting movement for the same person/date, with explicit message. This is a proposed deterministic choice, pending phase 07/22 testing.
3. Release-time admin credential provisioning method: must preserve exact login, never commit plaintext production credentials.
4. Windows portable encryption recovery and DPAPI: define offline portable recovery mechanism and key loss policy before encrypted storage is finalized.
5. Operational sites and force lists should use effective dates, never solely mutable current-site fields.
6. Define default policy for windows that have been closed during scheduled backup; use Task Scheduler only if account context/permissions support it and report failures explicitly.
7. Excel library must be verified to support frozen panes, RTL worksheets, styles and print settings before committing to package choice.

## Phase acceptance protocol

For each phase record: requirements IDs; created/modified files; schema/UI/domain changes; test commands and real outputs; CI run URL or failure; regression; open defects; explicit owner approval to continue.
