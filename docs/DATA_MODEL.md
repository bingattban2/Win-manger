# Logical Data Model — Design Contract (not yet migrated)

**State:** Design baseline only. Real Drift schema/migrations start phases 04–06. No database is implemented in phase 00.

## Identity, organization and attendance

| Entity / table | Stable key | Essential fields and constraints |
|---|---|---|
| `persons` | `id` | business number text, normalized number unique, full/normalized name, lifecycle, attribution stamps |
| `person_identity_history` | `id` | person FK, old/new name and number, actor, audit link |
| `sites` | `id` | name/normalized name unique for active sites, `is_system_site`, active flag |
| `site_name_history` | `id` | site FK, old/new labels, effective date, actor |
| `person_site_assignments` | `id` | person FK, site FK, effective-from/to-exclusive; **no overlapping person intervals** |
| `attendance_statuses` | `id` | name/code/color ARGB/order, system and active flags |
| `attendance_status_history` | `id` | metadata versions, including historic name/code/colors |
| `daily_attendance` | `id` | person/date unique, effective site, status, prepared/updated by, revision |
| `attendance_revision_history` | `id` | old/new status, old/new site, actor, timestamp, audit link |
| `internal_transfers` | `id` | person FK, from/to sites, effective date, actor, group ID |
| `external_transfers` | `id` | person FK, source, required destination, effective date, actor |
| `dismissals` | `id` | person FK, last site, required reason, effective date, actor |

## Flexible records and immutability

| Entity / table | Key / invariants |
|---|---|
| `attribute_definitions` | stable ID/internal key, customizable display labels and order, visibility/activity flags |
| `person_attribute_values` | unique `(person_id, attribute_id)`; value preserved when label changes |
| `monthly_archives` | unique `(year,month)`, archive version, integrity hash, sealed flag |
| `monthly_archive_persons` | historical identity and site participation snapshot, archive/person relationship |
| `monthly_archive_days` | sealed day-level historical statuses and movement markers |
| `app_users` | immutable ID, normalized username unique, nullable person FK only for foundational admin, role, salted verifier, active/deleted flags, created_by |
| `audit_events` | immutable append-only log with hash chain, operation target, actor, effective date, old/new values |

## Operational supporting tables

`authentication_events`, `import_batches`, `import_rejected_rows`, `export_history`, `backup_history`, `scheduled_backup_state`, `application_settings`, `schema_migrations`.

## Core constraints

1. Never use name or changeable personnel number as a foreign key.
2. Preserve leading zeros and normalize Arabic digits only for comparison/search, not display.
3. DB foreign keys and transactions mandatory; enforce invariants beyond UI checks.
4. Move events and daily attendance are distinct data; do not replace attendance with a transfer label.
5. Lifecycle transitions are soft removal; archived historical identities remain accessible.
6. `monthly_archive_*` is immutable after seal and independent from changes to live tables.
7. Required audit event must be in the same transaction as the business mutation.
8. Introduce and test deterministic, versioned migrations from first actual DB release onward.
9. Encryption backend must be verified on Windows in compiled Release builds and must not silently downgrade to plaintext.
10. Offline cross-machine recovery requires separately protected recovery material, never only a DPAPI key tied to a single Windows user.

## Seed values (phase 05)

- Protected site: `غير محدد`.
- Statuses: `موجود` / `م` / light blue, `إجازة` / `ج` / green, `غياب` / `غ` / red, `إذن` / `إ` / yellow.
- Foundational administrator: provisioning belongs to phase 09, with the credentials specified by the owner in the unredacted original instruction. Do not create plaintext credential fields.
