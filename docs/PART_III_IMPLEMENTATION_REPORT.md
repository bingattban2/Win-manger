# PART III — Actual implementation report: Permanent identification + exact schema

**Product:** التمام اليومي (ADWAS Personnel)  
**Version:** 0.0.3+3  
**Scope:** Only PART III, sections 4 and 5. **PART IV is not implemented.**

## Implementation ledger

| Requirement | Executed implementation | Evidence |
|---|---|---|
| 4.1 Immutable person_id | RFC 4122 UUID v4 from `Random.secure()`, `PersonnelIdentity` API with preserved ID; SQL update trigger blocks `persons.id` mutation | `test/personnel_identity_test.dart`, Python SQLite tests |
| 4.2 Number «الرقم (ع)» | Original and normalized TEXT; Arabic-Indic and Persian digits mapped to ASCII digits without numeric conversion; SQL validates normalized values | `personnel_identity.dart`, `schema_v1.sql` |
| Global number uniqueness | UNIQUE normalized key plus permanent historical reservation table. Historical number cannot be reused by a different person after a correction or departure | `personnel_number_registry`, SQLite tests |
| 5.1–5.19 | Exact required tables with defined columns and indexed foreign keys | `assets/database/schema_v1.sql` |
| 5.20 | All eight supporting tables included | Schema catalog + SQLite tests |
| Default site | Protected `غير محدد` system site with fixed ID and blocking SQL triggers | `seed_v1.sql`, test 04/06 |
| Four default statuses | `موجود/م` light blue, `إجازة/ج` green, `غياب/غ` red, `إذن/إ` yellow, persisted in numeric ARGB | `seed_v1.sql`, test 04 |
| Assignment intervals | Non-overlapping half-open validity intervals enforced by SQL INSERT and UPDATE triggers | SQLite test 11 |
| Unique daily preparation | `(person_id, attendance_date)` unique; site and status separate from movement events | SQLite test 12 |
| Dynamic attributes | Definitions and per-person values with compound primary key | SQLite test 13 |
| Monthly archive snapshots | Historical person and site segments; immutable post-seal archive records; separate attendance and administrative markers | SQLite test 15 |
| Referential integrity | Foreign keys, normalized constraints, protections against physical personnel deletion, append-only audit | SQLite tests 03/10/16 |

## File inventory and table count

- `assets/database/schema_v1.sql`: SQLite 1 schema, **29 actual tables**, indexes, integrity triggers and foreign keys.
- `assets/database/seed_v1.sql`: idempotent default site and four attendance statuses. No personnel and no users.
- `lib/core/domain/personnel_identity.dart`: immutable IDs, number/name normalization and verified-domain creation/correction models.
- `lib/core/domain/schema_catalog.dart`: inventory of all tables and immutable system seed references.
- `scripts/test_part_iii_sqlite.py`: integration-style tests using SQLite exclusively **in memory**.
- `test/personnel_identity_test.dart`, `test/database_schema_catalog_test.dart`: Dart and Flutter tests.
- `.github/workflows/windows-foundation.yml`: SQLite contract tests + Flutter checks + Windows build + SDK/pub caches.

**Why 29 tables?** All **27** named schema tables from the contract exist, plus two normalized integrity tables required for safe history: `personnel_number_registry` (historical number ownership) and `monthly_archive_site_segments` (historic site participation without depending on current names).

## Important security boundary

PART III defines and executes **the schema itself** in tests, but does **not** activate an on-disk SQLite file in the compiled application. Creating unencrypted personnel data would breach the earlier offline encrypted-storage requirement. An encrypted Windows SQLite driver, key protection and runtime repository integration belong to the dedicated encrypted persistence / migrations phases. In this version the UI remains a transparent read-only construction screen; it does **not** claim working accounts, attendance or exports.

A generated `app_users` table does not mean the foundational admin is provisioned. Do not place that account's password or hash inside test fixtures. Only the later authentication phase will safely initialize accounts.

## Deferred outside PART III

PART IV's force calculations, temporal projection, transfer/day UI behavior, lifecycle eligibility, Gregorian calendar/month boundary management, and automatic sealing **are not implemented here**. They are dependent on verified runtime persistence and later application services. Similarly, encryption, migrations, authentication, printing, export, backup, and operation screens remain for their designated phases.

## Verification matrix

1. Run `python -m unittest discover -s scripts -p "test_*.py" -v` (SQLite SQL contract + Windows metadata tests).
2. Run `flutter pub get`, `flutter analyze`, `flutter test` (new identity/schema tests plus inherited tests).
3. Run the GitHub Actions Windows release compilation.
4. Download `Altamam_AlYawmi_Part_III_Windows_x64`; launch `التمام اليومي.exe` with its accompanying assets and DLLs on Windows 10/11 x64.
5. Check the read-only Part III label and appearance, without entering real personal data.

**Local outcome:** Python/SQLite: 25 tests executed successfully, foreign-key and integrity checks passed. **Flutter/Windows is pending your GitHub run.** No claim of Windows compatibility is made before that execution.
