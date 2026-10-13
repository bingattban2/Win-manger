# Business Rules and Historical Correctness

## Personnel identity and uniqueness

- Every individual is referenced by immutable `person_id` (UUID recommended).
- `الرقم (ع)` is a **TEXT** business identifier. Preserve original display, normalize Arabic/Western digits for matching, and retain leading zeros.
- One normalized ID may belong to only one identity, including inactive/dismissed/externally transferred persons.
- Corrections to name/number change metadata, not identity or history. Historical archive snapshots stay sealed.

## Sites and workforce

- `غير محدد` is system-created, undeletable and unrenamable.
- Closing/deactivating a site moves eligible members to `غير محدد` effective on the operation date while preserving the original site history.
- One person has at most one effective site on a business date. Assignment intervals follow `[effective_from, effective_to_exclusive)`.
- `eligible_force(D,S)` excludes dismissals/external departures effective on or before D.
- `eligible_force(D,S) = Σ status_count(D,S,each active recorded status) + unprepared(D,S)`.
- Unprepared is **not** equivalent to absent. `موجود` is a status selected in daily preparation, not the default for an unprepared person.
- Force totals are calculated from distinct effective person IDs, not the number of monthly-rendered rows.

## Daily attendance

- Exactly one official `daily_attendance` state per `(person_id, date)`.
- Daily preparation supports individual and atomic bulk operations and checks the current session, permissions and month seal before mutation.
- Edits inside the current unsealed month create revision history; closed months cannot be altered.
- A no-op preparation must not create a misleading status revision.
- After commit, dashboard and monthly grids requery authoritative data.

## Internal site transfer

- On day D, source displays `تم نقله للموقع (...)`, destination displays `تم نقله من (...)`.
- Before D: old site shows attendance; future site displays no fabricated historical attendance.
- On D: attendance belongs to destination site and is displayed along with the incoming marker.
- After D: old site stops preparation; new site continues.
- Repeated monthly transfers create distinct history and nonoverlapping intervals.
- Multiple site visual projections do not imply duplicated eligible-force counts.

## External transfer and dismissal

- Both remove people from active force without physical deletion.
- External transfer records required destination; dismissal records required reason and a five-second final confirmation.
- Dismissal day displays `مفصول` in the historical monthly participation view.
- Previous months/reports remain available.
- Linked accounts are deactivated where specified, with the foundational admin protected.

## Month boundaries and archives

- Dates are stored as Gregorian civil dates, timestamps as UTC; user-facing weekdays are Arabic, times are Windows-local.
- 28/29/30/31-day months, leap years and years crossed must be correct.
- When app resumes after downtime, it archives all eligible completed months chronologically and only once each.
- Sealed archives contain identity, site, status metadata, movements and daily records captured at closure.
- Do not recompute sealed historical reports using current data.

## Audit, validation and commit

- Route every mutation through normalized input → domain checks → authorization → preview → confirmation → one database transaction → history/audit write → invariant verification → commit → reactive refresh.
- On error before commit, rollback and never display a false success.
- Logs and audit records must avoid plaintext passwords, database encryption keys, or private recovery material.
- Deleted/deactivated operators remain identifiable in historical audit data.

## Unresolved policy details

- A secondary internal transfer occurring on the same calendar day is not yet specified more narrowly than 'use one deterministic rule'; prefer reject conflicting same-day moves. Record final decision in phase 07.
- Specify the date when a new person admitted mid-month becomes eligible, and ensure import/assignment temporal models handle it.
