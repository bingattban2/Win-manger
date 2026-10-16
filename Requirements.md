# التمام اليومي (Al-Tamam Al-Yawmi) - Requirements Baseline

## Requirements Baseline & Traceability Grid

| Req ID | Description | Acceptance ID |
|---|---|---|
| REQ-001 | Offline Windows Desktop application for personnel strength, daily attendance, transfer, and reporting. | AT-001, AT-042 |
| REQ-002 | Strict Arabic RTL UX, exact Arabic screen names as requested. | AT-001, AT-043 |
| REQ-003 | Historical data invariant: Every person, attendance event, transfer must survive changes to names, service numbers, or sites. No rewriting past records. | AT-021, AT-022, AT-030 |
| REQ-004 | Application relies on SQLite with SQLCipher encryption. | AT-001 |
| REQ-005 | Three roles: GeneralAdministration, OrdinaryAdministration, Supervisor. Permissions restricted appropriately. | AT-003, AT-004, AT-027, AT-028, AT-029 |
| REQ-006 | Automatic 20:00 attendance carry-forward for unprepared persons. | AT-011, AT-012, AT-013, AT-014, AT-015, AT-016 |
| REQ-007 | Excel Import/Export function without MS Office dependency. | AT-032, AT-033, AT-034, AT-035, AT-036 |
| REQ-008 | Internal Transfer monthly semantics with source/destination markers. | AT-017, AT-018, AT-019, AT-020 |
| REQ-009 | New User-Mandated Person Summary Report (هـ). | AT-023, AT-024, AT-025 |

## Screen Flow and Actions

1.  **أولاً: الشاشة الرئيسية (Dashboard)**
    *   Totals, statuses, "غير المحضرين".
    *   Table filtering by site and status.
2.  **ثانياً: التمام الشهري (Monthly Attendance)**
    *   Read-only monthly grid with day columns. Virtualized.
3.  **ثالثاً: شاشة الإدارة (Management)**
    *   *1- إدارة القوة*
        *   أ) التمام (Daily Attendance)
        *   ب) تعديل الأسماء (Edit Names)
        *   ج) التنقلات (Internal/External Transfers, Archive)
        *   د) التقارير والفصل (Reports and Separation)
        *   هـ) التقرير (New Lifetime Report)
    *   *2- الحالات والمواقع*
        *   أ) الحالات (Statuses)
        *   ب) المواقع (Sites)
    *   *3- الكشوفات*
        *   استيراد (Import)
        *   تصدير (Export)
        *   تعديل الهيكل للكشف (Column editing)
    *   *4- المستخدمين* (Users - Hidden from Supervisor)
    *   *5- سجل العمليات* (Audit Log - editable by Admin)
4.  **رابعاً: شاشة الإعدادات (Settings)**
    *   Backups, restore, theme, reset program data.

## Permission Matrix

| Operation | GeneralAdmin | OrdinaryAdmin | Supervisor |
|---|---|---|---|
| View Dashboard & Attendance | Yes | Yes | Yes |
| Record Attendance | Yes | Yes | Yes |
| Create Supervisor User | Yes | Yes | No |
| Create OrdinaryAdmin User | Yes | No | No |
| Edit/Delete "سجل العمليات" (Audit Log) | Yes | Yes | No |
| System Reset | Yes | No | No |

## Arabic Labels
*   "الفرد", "الأفراد", "اسم الفرد", "الرقم (ع)", "الموقع", "الحالة"
*   "التمام اليومي", "التمام الشهري", "إدارة القوة", "التمام", "تعديل الأسماء", "التنقلات", "التقارير والفصل", "التقرير", "غير المحضرين", "سجل العمليات", "الكشوفات", "الإعدادات"

## Event Taxonomy
*   `AttendanceRecorded` / `AttendanceRevised`
*   `PersonCreated` / `PersonRenamed` / `PersonSeparated`
*   `InternalTransferCompleted` / `ExternalTransferCompleted`
*   `SiteCreated` / `SiteRenamed` / `SiteDeactivated`
*   `StatusCreated` / `StatusDeactivated`
*   `AuditLogEntryEdited` / `AuditLogEntryDeleted` (Overlay only, underlying event immutable)
*   `BackupCreated` / `BackupRestored`

## Date / 20:00 Policy
*   Current day closed at 23:59:59.
*   Prior days read-only unless an explicit, authorized, audited override is invoked (configurable, default off).
*   At 20:00 local time, still-unprepared eligible persons have their *yesterday* recorded status copied as their *today* status (source "20h-auto"). Missed runs detected at next launch.

## Movement-Day Acceptance Examples
*   Transferred from Site A to Site B on 16 Oct.
*   Site A month table: Days 1-15 normal. Day 16: "تم نقله إلى الموقع ب". Days 17+: Blank.
*   Site B month table: Days 1-15 Blank. Day 16: "تم نقله من الموقع أ". Days 17+: Normal.

## Backup / Recovery Policy
*   Default backup daily at 16:00 local, user-configurable.
*   Encrypted DB, separate recovery key. Target E:\ preferred.
*   Integrity verified on restore. Manual backup support.

## Open-Risk Section
*   **Time Tampering:** Desktop system time can be manipulated; application will detect backward clock changes, but cannot guarantee 100% tamper-proof civil time without network NTP (which is explicitly forbidden due to 100% offline rule).
*   **Offline Scheduled Tasks:** 20:00 auto-run requires the PC to be powered on. If PC is off, a catch-up run executes on the next startup.

## Architecture Decision Records (ADRs)

1.  **Historical Immutability:** No updating past records when names/sites/statuses change. Events reference immutable IDs, accompanied by point-in-time snapshots of display names.
2.  **Site Effective-Dating:** Person site assignments have `validFrom` and `validTo`. Internal movements close the previous assignment and open a new one.
3.  **Status-Definition Versioning:** Statuses can be created/deactivated, but historical attendance records remain bound to the stable StatusId.
4.  **Append-Only Audit Plus Admin Editable View:** The core audit ledger is immutable. However, General/Ordinary admins can "edit/delete" visible log rows. This is implemented via an overlay/tombstone layer (`AuditLogPresentationEdits`), preserving the original underlying facts.
5.  **WebView2 Bridge:** UI is pure HTML/CSS/JS rendered in offline WebView2. Bridge is strict typed JSON (requestId, action, payload). No inline/dynamic eval, no external navigation.
6.  **Offline Scheduling Limits:** The 20:00 auto-run uses a local Windows Task Scheduler job (if installer) or in-app timer + startup catch-up to handle offline intervals honestly.
7.  **First-Run Credentials:** No static permanent passwords. On first launch, the GeneralAdmin (`adwas`) must establish a strong password. Hashes stored using Argon2id.
