MASTER IMPLEMENTATION PROMPT
AL-TAMAM AL-YAWMI / "التمام اليومي"
OFFLINE WINDOWS PERSONNEL STRENGTH, DAILY ATTENDANCE, TRANSFER, ARCHIVE AND REPORTING SYSTEM
Consolidated final engineering specification and staged implementation contract
Version: 1.0 — 16 October 2026
Language of this implementation brief: English.
Mandatory language of the shipped application: Arabic, with exact Arabic screen names and full RTL support.

===============================================================================
00. YOUR ROLE, MISSION AND NON-NEGOTIABLE DELIVERY STANDARD
===============================================================================
Act as a Principal Windows Desktop Software Architect, Senior C#/.NET Engineer, WPF/WebView2 Engineer, Database and SQLCipher Engineer, Domain-Driven Design Specialist, Windows Security Engineer, Arabic RTL UX Engineer, GitHub Actions/Release Engineer, and Independent QA Lead.

Build the fully functioning Windows desktop application named "التمام اليومي" from an initially empty PRIVATE GitHub repository, based on this consolidated specification. Deliver complete, buildable, testable, packaged source code and TWO release artifacts: (1) a portable version launched without application installation and (2) a Windows installer. The application must be ready for real use, not a clickable mockup, prototype, sketch, nonfunctional frontend, or architectural outline.

SOURCE-OF-TRUTH PRIORITY (resolve all conflicts in this order):
1) The user's explicit modifications in this brief, especially audit-log permissions, the new report, new-status counters, unprepared workflow and 20:00 carry-forward, and the exact internal-transfer day behavior.
2) The core functional specification and Arabic terminology reproduced in this brief.
3) The accepted engineering, functional, performance, security, usability, and release improvements reproduced here.
4) Necessary, conservative implementation details defined in the "Explicit operational decisions" sections; do not replace them with speculative business rules.

DO NOT silently discard any feature. DO NOT turn this into a web-hosted application or require a server. DO NOT ship hardcoded permanent credentials, online dependencies, fake exports, placeholder screens, or incomplete installers. DO NOT move on to a new implementation phase until the previous phase has passed its automated build and acceptance gates in GitHub Actions. Keep the repository private; no source code, personal data, database content, backups, passwords, encryption keys, or confidential sample rosters may be exposed in public artifacts.

HIGHEST-PRIORITY HISTORICAL DATA INVARIANT — MAKE THIS THE CENTRAL ARCHITECTURAL DECISION:
"The historical record of every person, every daily attendance status, and every transfer or personnel movement MUST survive any later change to that person's name, service number (الرقم (ع)), current site, current attendance-status name, current permissions, or operational status. Historical reports must reproduce the correct historical fact without rewriting past records. This rule is more important than UI convenience or short-term programming speed."

A person must have a permanent internal PersonId. Each personnel assignment, attendance event, attendance correction, site rename, status rename, transfer, external transfer, separation, and administrative change must be connected by permanent internal identifiers plus appropriate historical snapshots/effective timestamps. Never implement history by mass-replacing past person/site/status values whenever today's values change. Never use display names as relational keys.

Definition of done: all requested features work end to end; phase tests and regression tests pass; database and backups remain restorable; the app starts and functions without internet; Arabic RTL UI is correct; large-table performance has been measured; portable and installer artifacts have been tested on a clean compatible Windows environment. Be candid in RELEASE_NOTES and QA_REPORT about any test that was not actually run. Never announce success on the basis of compiling alone.

===============================================================================
01. APPLICATION SCOPE, USERS AND HARD CONSTRAINTS
===============================================================================
1. Name, visible title, installer title, application metadata, and Arabic home heading: "التمام اليومي". Standardize the product code name, e.g. AlTamamAlYawmi, across assemblies and directories.
2. Windows desktop only. Primary compatibility target: current supported Windows 10/11 x64 configurations compatible with .NET 10, WPF and WebView2. If the selected dependencies impose stricter minimum supported OS builds, document and test them explicitly.
3. One local PC at a time, where different authorized users (الإدارة العامة, الإدارة العادية, المشرفون) may take turns using the same installation. No LAN server, multi-device live synchronization, cloud database, remote login, web API, or telemetry.
4. Runtime operation is 100% offline. The user's private GitHub repository and GitHub Actions may access the internet during DEVELOPMENT/BUILD; the DISTRIBUTED APP must not need it. Use local HTML/CSS/JavaScript/assets, local database, and local export/backup paths only. Disable external navigation and external network requests in the embedded browser. Any offline WebView2 Runtime used for clean-machine deployment must be appropriately packaged and tested.
5. Arabic is the shipping UI language. Right-to-left layout, correct Arabic font/fallback, Unicode normalization for search, native Arabic and Western digits in input, readable messages and accessible focus order are mandatory.
6. Scope: full personnel force records, daily and monthly attendance, historical movement (internal/external), separation, roster editing, archive, import/export Excel, accounts and permission checks, report screen, searchable audit operations, settings, encrypted backups and restoration, scheduled 20:00 attendance carry-forward, daily/month-end locking, and secure packaging.
7. The four top-level application areas MUST remain: (أولاً: الشاشة الرئيسية), (ثانياً: التمام الشهري), (ثالثاً: شاشة الإدارة), (رابعاً: شاشة الإعدادات). Nested screens are defined in Section 09.
8. Use a conservative, maintainable codebase. Avoid unnecessary libraries, duplicated CSS/JavaScript, dead code, UI logic in controllers, verbose generated cruft, and architecture for an imaginary multi-server deployment.

===============================================================================
02. REQUIRED TECHNICAL STACK AND SECURITY BOUNDARIES
===============================================================================
REQUIRED:
- C# with .NET 10 (Windows desktop, long-term support).
- WPF shell (application lifecycle, host window, system dialogs, optional native components) and MVVM (CommunityToolkit.Mvvm is acceptable).
- Microsoft Edge WebView2 to render locally packaged HTML5 + CSS3 + JavaScript application screens, with a typed narrow message bridge into C# application services. Avoid WPF and web UI implementing business logic twice.
- SQLite encrypted with SQLCipher, with correct native/runtime binding and integration testing.
- Local Excel import/export (.xlsx) using a tested .NET library (e.g. ClosedXML if licensing and packaging are compatible).
- GitHub private repository, Windows GitHub Actions workflows, automated unit/integration/UI-smoke tests, versioned database migrations, and build artifacts.

ARCHITECTURAL LAYERS:
  AlTamam.Desktop            = WPF app shell, WebView2 host, resources, dialogs.
  AlTamam.WebUI              = pure HTML/CSS/JavaScript RTL presentation files.
  AlTamam.Application        = use cases, DTOs, transactions, orchestration, validation.
  AlTamam.Domain             = business entities, invariants, policies, domain events.
  AlTamam.Infrastructure     = SQLCipher/SQLite repositories, migrations, Excel, backup, scheduling, OS integration.
  AlTamam.Contracts          = typed bridge requests/responses, error schemas.
  AlTamam.Tests.Unit         = deterministic business policy tests.
  AlTamam.Tests.Integration  = actual encrypted database, migrations, crash/transaction behavior.
  AlTamam.Tests.E2E          = Windows desktop and offline packaging smoke tests.

Dependency direction: Desktop and Infrastructure depend on Application/Domain interfaces, never Domain on UI or database. Presentation cannot directly issue SQL or hold plaintext SQLCipher keys. Establish a single trusted entry point for every state-changing operation with authentication, role authorization, validation, transaction, concurrency/idempotency rules, and audit recording.

WEBVIEW2 ISOLATION:
- Use a local virtual host mapping or other vetted strictly local WebView2 resource strategy.
- Only allow the packaged local origin; no untrusted remote scripts, CDN, online fonts, navigation to third-party sites, or unconstrained script injection.
- Define a strict typed JSON request schema: requestId, action, version, payload. Validate action allowlist, DTO fields, sizes, session and permissions on the C# side.
- Responses: requestId, success, data, errorCode, localized userMessage; avoid stack traces or secrets in UI.
- Bridge actions must be explicit (GetDashboard, QueryPersons, SubmitAttendance, MovePersons, BuildPersonReport, ExportExcel, etc.). Prevent arbitrary filesystem/database methods from becoming bridge actions.
- Protect against HTML/script injection in any roster field and Excel values.

DATA ACCESS:
- Use an appropriate SQLCipher provider correctly linked for net10.0-windows. Prove database pages are encrypted and cannot be read by a standard plaintext SQLite reader.
- Enable foreign keys on every connection, WAL (when supported/configured appropriately), busy timeouts, parameterized SQL, least-necessary indexes, and one serialized logical writer; never assume WAL enables multiple concurrent writers.
- ACID transactions for multi-person attendance, movement, import and critical mutations.
- Async/background operations for expensive queries/exports; marshal UI progress/cancel appropriately. Do not block the WPF UI thread.
- Versioned migrations (schema_version), transactional where feasible, with pre-migration backup and rollback/recovery documentation.

===============================================================================
03. FORMAL VOCABULARY AND IMMUTABLE DATA MODEL
===============================================================================
Use these Arabic display labels exactly unless the user later changes them:
- "الفرد", "الأفراد", "اسم الفرد", "الرقم (ع)", "الموقع", "الحالة".
- "التمام اليومي", "التمام الشهري", "إدارة القوة", "التمام", "تعديل الأسماء", "التنقلات", "التقارير والفصل", "التقرير", "غير المحضرين", "سجل العمليات", "الكشوفات", "الإعدادات".
Do not substitute "الموظفين" for "الأفراد" in the deployed screens.

CORE RELATIONAL SCHEMA (logical model, implement concrete migration scripts, PK/FK/UNIQUE/CHECK constraints and supporting indexes):
A. Persons: PersonId (immutable UUID or monotonic surrogate PK), current visible name, current serviceNumberA (الرقم (ع)), firstRecordedAt, organizationalStatus, activeFlag, rowVersion, optional authorized custom fields. PersonId never changes or gets reused. Enforce one serviceNumberA among currently active persons and specify historic/re-hire collision policy explicitly in code/tests.
B. PersonIdentityHistory: PersonId, nameSnapshot, serviceNumberASnapshot, validFrom, validTo, changedBy, recordedAt, reason. Never overwrite/delete past snapshots.
C. Sites: SiteId (immutable), visibleName, isSystemSite, activeFlag, createdAt. Seed the protected site "غير محدد" with immutable ID: cannot rename or delete.
D. SiteNameHistory: SiteId, visibleNameSnapshot, validFrom, validTo. A site rename must NOT rewrite historical movement labels or exports.
E. PersonAssignments: AssignmentId, PersonId, SiteId, validFromLocalDate, validToLocalDate (exclusive, nullable), sourceMovementId, createdAt. Enforce no overlapping active assignment periods for a person. Distinguish current assignment and historical assignment.
F. AttendanceStatusDefinitions: StatusId, visibleName, shortSymbol, chosenColor, activeFlag, createdAt and schema fields if needed for display/analytics. Seed "موجود" (م, light blue), "إجازة" (ج, green), "غياب" (غ, red), "إذن" (إ, yellow). Historical status renames must not change original recorded identity or event snapshots. Avoid imposing an unwanted attendance/absence semantic classification on custom statuses.
G. AttendanceStatusNameHistory: StatusId, visibleNameSnapshot/symbol/colorSnapshot, validFrom/validTo.
H. AttendanceRecords: PersonId + attendanceDate local (unique for a valid primary daily attendance record), StatusId, assignmentIdAtEffectiveDate, source (manual/bulk/20h-auto), createdBy, committedAtUtc, effectiveLocalDate, revisionNumber, idempotencyKey. Attendance corrections are documented separately, not duplicate current-day rows. The transfer day is a movement marker, NOT an ordinary attendance status.
I. AttendanceRevisions: append-only before/after StatusIds and display snapshots, reason, actor, timestamp, target date and authorization method. Closed days cannot be user-edited under the user's rule; controlled exceptional policy must be explicitly handled only if enabled under the narrow general-admin emergency process.
J. PersonnelMovements: MovementId, PersonId, movementType (internal/external/separation), fromSiteId, toSiteId if internal, destinationExternalName if external, reason if required, effectiveLocalDate, committedAtUtc, actorId, snapshots of names/site labels for evidence, idempotencyKey, superseding/compensation references. Never rewrite previous attendance rows or past assignments when recording a new move.
K. Users: UserId, PersonId where roster-backed, username unique, role, credentialHash, salt/Argon2id parameters, security state, createdBy, createdAt, activeFlag. One initial bootstrap GeneralAdministration account may have no PersonId; all subsequent accounts must map to existing active roster Persons.
L. UserRoleHistory, UserSessions, FailedLoginEvents: changes and session security.
M. AuditEvents: immutable low-level facts including operation type, actor, target, before/after values where appropriate, reason, when executed, effective date, correlationId, event hash and prior hash if chain-backed. Do not silently rewrite the underlying original facts.
N. AuditLogViews / AuditLogPresentationEdits: mutable UI-facing log display overlay or tombstone records authored ONLY by general/ordinary administrators, while preserving the underlying AuditEvents for integrity, as explicitly required in Section 12.
O. CustomFieldDefinitions and CustomFieldValues: stable IDs, immutable technical identity, editable Arabic caption, type (text/number/date/selection), ordering, visibleFlag, activeFlag, constraints. Protect identity-critical/system columns against actual deletion. Editing column captions must not rewrite SQL, domain enums, or historical event semantics.
P. PeriodClosures: localDay/month, state, effective closure event, signed/recorded timestamps, close policy version and responsible actor/system origin.
Q. AttendanceDrafts: uncommitted batch selections and chosen statuses, scope, createdBy, updatedAt, expiration/cleanup policy. Never count drafts as committed attendance.
R. AutoAttendanceRuns: business date, 20:00 due time, started/completed timestamps, summary, job key, missed-run/recovery metadata and errors; uniqueness enforces exactly-once effects.
S. BackupHistory: backup path, checksum, schema version, success status, verification status, key metadata (never plaintext key), restoredFrom and timestamps.
T. ImportBatches and ImportIssues: source file checksum, preview/dry-run plan, rejected rows, accepted/created records, committed batch ID and audit metadata.

INDEXES: status/date, active person/site, person assignment effective date, person attendance date, movement by person/date and site, normalized username, person name and الرقم (ع) search, audit actor/time/target, closures, batch/schedule idempotency. Run real EXPLAIN QUERY PLAN on representative queries. All updates to person name/service number reflect in current UI but historic query uses effective date/snapshot. Retain archival movement and status records even if entities become inactive.

===============================================================================
04. TIME, DAILY/MONTHLY LOCKING AND BUSINESS-DATE POLICY
===============================================================================
Time zone: configured local machine/business timezone; for an offline local PC, display dates in the business local calendar and preserve UTC execution timestamps plus date-only local attendance dates. Detect backward clock changes and surface a warning/verification requirement for sensitive new changes. It is NOT possible to guarantee tamper-proof civil time without an external trusted time source; document this limitation, do not fake guarantees.

Business day: 00:00:00 through 23:59:59 local date. The current day closes automatically when the calendar crosses to the next day (after 23:59:59); historic days are read-only to ordinary user activity. A completed month closes after its final calendar day. "التمام الشهري" is always read-only. Use robust boundary comparisons on date values (no string sorting or timezone-ambiguous timestamps).

Default authorized manual attendance: CURRENT business day only. Never silently let a user edit yesterday by changing a UI date picker or OS clock. If a controlled emergency correction policy is implemented for the general administrator (as an accepted engineering recommendation), require reauthentication, reason, old/new audit trail, and an explicit separate override workflow; do not make it available in ordinary attendance screens and DO NOT alter the original historical event. If the organization elects strict no-correction, disable the override in configuration. The shipped default is strict closed-day lock; it requires an explicit policy change by general administration to permit an audited emergency correction.

Prior-day retrieval remains read-only in all screens except the authorized audited emergency process. Reports may be regenerated for any date from the event/assignment history without modifying the database state.

===============================================================================
05. THE THREE ROLE TIERS AND OPERATION-LEVEL AUTHORIZATION
===============================================================================
Roles: (1) "الإدارة العامة" GeneralAdministration, (2) "الإدارة العادية" OrdinaryAdministration, (3) "مشرف" Supervisor. The general administrator has overall rights; ordinary administrators share normal administrative rights except creation of ordinary-administrator accounts and exclusive general-admin security operations; supervisors have normal force/attendance/movement permissions but no ability to open, call or administer the user-management screen.

SPECIFIC RESTRICTIONS AND OVERRIDES:
- GeneralAdministration creates/edits/disables ordinary administrators and supervisors. OrdinaryAdministration creates/edits/disables supervisors only. Supervisor cannot create/edit/delete ANY account and never sees "المستخدمين".
- Creation of non-bootstrap accounts requires choosing an existing active person from the force roster; auto-populate the service number from the selected PersonId. Usernames unique. When the person is separated or externally moved, automatically disable that user account and archive account history; do not irreversibly erase it.
- "تعديل الأسماء" can rename persons/adjust الرقم (ع) for valid permitted operators, but DELETION of individuals from the active force is available only to OrdinaryAdministration and GeneralAdministration as specified in the source requirements. Implement as inactive/archive without destroying attendance/history.
- COMPLETE DATABASE RESET ("حذف جميع بيانات البرنامج") is GeneralAdministration-only for safety (the accepted improvement to the old permissive wording). Requires username/session reauthentication, multi-step confirmation, a countdown, verified recent encrypted emergency backup, and preservation of independently exported/off-device backups. Neither OrdinaryAdministration nor Supervisor may invoke it via UI OR bridge.
- CRITICAL USER OVERRIDE: Both GeneralAdministration AND OrdinaryAdministration may EDIT and DELETE UI-visible entries in "سجل العمليات". Supervisor may READ, FILTER and SEARCH but may NOT edit/delete the visible audit entries. The UI must expose Edit/Delete action buttons only to the two administrator classes; the application layer MUST enforce these permissions independently. An edited log entry must display the administrator's corrected visible description; a deleted log entry must disappear from the ordinary log view (or be visibly marked deleted in an administrator restoration view). Store the edit/deletion as a versioned correction/tombstone operation with reason, actor and timestamp. DO NOT physically destroy immutable original AuditEvents or corrupt attendance/movement history. Retain a restricted underlying audit trail for integrity, recovery and security review. This is intentional and is NOT a license to remove history.
- Sensitive modifications require reauthentication where appropriate; roles do not bypass transactional integrity.
- Authorization is not merely hide/show buttons: enforce in C# service methods and repository transaction entry points. Add tests for forged JS bridge requests and stale sessions.

INITIAL GENERAL ADMINISTRATOR:
The original planning document included a fixed bootstrap account name and fixed password. Retain the intended GeneralAdministration identity (bootstrap username "adwas" if that is operationally required), but do NOT embed or distribute the original static password as a permanent shared secret. On first safe activation, require creation of a strong unique general-admin password and recovery key; password hashes via Argon2id with per-user salts. Display no credential hints. Provide a verified offline recovery path that does not weaken authentication or expose a backdoor. Document the first-run setup in Arabic. Never place plaintext passwords/SQLCipher keys in code, CI logs or configuration. Subsequent user password validation must support a strong password length/entropy policy rather than relying ONLY on the original "3 letters + 3 digits + symbol" superficial rule; if the minimum character-category rule is retained for compatibility, also enforce adequate length and breached/weak-password rejection where feasible offline.

===============================================================================
06. DAILY ATTENDANCE ENGINE — NORMAL, BULK AND DRAFT WORKFLOWS
===============================================================================
The daily attendance screen is "ثالثاً > شاشة الإدارة > 1- إدارة القوة > أ) التمام".
- Show the active force roster with site filter "جميع المواقع" and each defined site; searchable by name/الرقم (ع); include current-day status and unprepared indicator.
- Allow selecting a single person, multiple persons or all eligible persons in a selected site and assigning any active attendance status defined under "الحالات".
- Before commit show confirmation with PersonId-resolved display name, الرقم (ع), site, PREVIOUS displayed status, chosen NEW status, affected date, and number of people. The "previous" entry must differentiate (a) yesterday's last recorded status and (b) any existing status for today so they are never confused. The selected target status is today's status only and does not rewrite yesterday.
- Cancel retains/dismisses draft according to clear UI choice; do not commit implicitly. Save optional unconfirmed selections separately as draft.
- One primary attendance status per PersonId per business date (unique index); repeated confirm, double-click or WebView2 retry must not create duplicates (request idempotency). A change of today's already recorded status uses a revision event with before/after, actor and reason according to the authorized correction rule, not duplicate attendance rows.
- Block conflicting moves/closures and stale writes; show explicit localized conflict messages and refresh affected rows without full reload.
- Use one ACID transaction for a committed group. If validation fails for one member, present the conflict before commitment and let operator resolve it; no partial state unless separately selected/confirmed through explicit batch partitions.
- All saved attendance affects daily counters, site summaries, reports and monthly display through shared application service queries; do not scatter counter arithmetic across JavaScript and C#.
- If an individual has an INTERNAL TRANSFER EFFECTIVE TODAY, today's site-specific monthly cells must be movement markers, not normal attendance. Disable manual attendance and automated carry-forward for that person's movement date. Attendance resumes from the FOLLOWING calendar day in the destination site, as explicitly specified in Section 08.
- Status labels are configured separately; ordinary attendance statuses are NOT structural movements or separated/external-person statuses.

===============================================================================
07. UNPREPARED PERSONS: EXACT USER OVERRIDE AND 20:00 CARRY-FORWARD
===============================================================================
THIS SECTION OVERRIDES ANY GENERIC EARLIER RECOMMENDATION ABOUT UNPREPARED WORKFLOW.

DEFINITIONS:
- "غياب" is a NORMAL, EXPLICIT, RECORDED and COUNTED absence status; it is NEVER equivalent to an unprepared/missing attendance record.
- "غير المحضرين" = currently active, daily-attendance-eligible persons with NO committed AttendanceRecord for TODAY and no structural exemption such as a same-day internal movement marker. Their current-day value remains unprepared until a manual/bulk commit or automated 20:00 carry-forward succeeds.
- Auto-inferred/carry-forward entries count as approved attendance records with source "20h-auto"; they are not drafts and are not shown as unprepared after a successful commit.

MAIN DASHBOARD COUNTER:
- Show a dedicated clickable counter labeled EXACTLY "غير المحضرين". Number equals the count of eligible active persons unprepared for today's business date after site scope is applied. Render even when count=0.
- Clicking opens "شاشة غير المحضرين" with (1) site dropdown including all sites, (2) status dropdown, (3) table columns in exactly this logical order: "الرقم", "الرقم (ع)", "الاسم", "الموقع", "الحالة".
- Because a person has NO current-day recorded status by definition, the "الحالة" cell must say "غير محضر" and may also show a clearly labeled read-only "حالة اليوم السابق: ..." subtext. The STATUS FILTER filters by the status of the PREVIOUS CALENDAR DAY (including "بدون حالة سابقة") rather than claiming a nonexistent status today; the filter must be titled "الحالة السابقة" inside this page so it is meaningful. Site and previous-status filters combine (logical AND). Do not silently exclude persons with no yesterday record; include them under "بدون حالة سابقة".
- Support selecting one or multiple persons and pressing "تحضير". The operator must choose the target ACTIVE status for today. Show a confirmation describing selected names, service numbers, yesterday's status (if any), selected new/current status, and today's date, with "إلغاء" and "تأكيد". On confirmation save TODAY's status atomically, update all current views/counters, and audit the operation. Yesterday's record remains unchanged and locked.

MANDATORY 20:00 (8 PM) DAILY AUTO-RULE:
- Exactly once per local business date, at 20:00 local time, automatically examine STILL-UNPREPARED eligible persons only. For each one with a COMMITTED attendance status for the immediately preceding calendar date (YESTERDAY), copy that same status ID into a NEW attendance record for TODAY, mark source="20h-auto", record execution timestamp and reference the yesterday record. This is not a modification of the preceding day, which is read-only.
- Count all successful new records in the status-specific dashboard counters, force totals and monthly attendance. After completion the persons are no longer in "غير المحضرين". The name of the status counter remains its configured name.
- Do not create a guessed previous status. When yesterday contains no recorded attendance, yesterday was unprepared, or the person was not enrolled/eligible, keep them unprepared and show this reason in the auto-run summary; do not silently substitute "موجود" or "غياب".
- EXCLUDE same-day internal-transfer movement markers, separated/external-transferred persons, inactive/unassigned persons, and people not eligible on the effective date. Never copy an attendance status to the transfer date for that person.
- Manual confirmation and the 20:00 job may race: serialize/transactionally protect writes; a unique daily-attendance key and idempotency key must prevent duplicate/overwritten records. If manual attendance was committed first, do not overwrite it. If the automated commit happened first, an authorized current-day correction requires explicit user action and an audit revision.
- At 20:00, update only the affected rows/counters; add run summary to audit and auto-job history. Schedule/callback MUST work while the application is open and not freeze the UI.
- Important physical limitation: an ordinary desktop app cannot run while the PC is powered off. For the INSTALLER, register an appropriate LOCAL Windows Task Scheduler job/background entry point to perform the 20:00 operation while the machine is on, even if the UI is closed (subject to Windows execution/user credential conditions). For the PORTABLE build, offer a clearly documented optional per-user local scheduled-task registration and an in-app schedule while open. Do not claim guaranteed 20:00 execution if the computer is powered off or scheduling is denied.
- At next launch/wake, detect missed 20:00 jobs. Perform a deterministic, once-only SYSTEM recovery action using the historical snapshot of eligibility and yesterday's immediately preceding committed attendance, recording "catch-up for YYYY-MM-DD", actual execution time and intended 20:00 due time. This is a SYSTEM-created delayed scheduled effect, not an interactive permission to edit closed historic dates. If a day is already closed, append the distinct system recovery event, preserve the original closure fact, maintain reproducible historic reports, and show an administrator-visible recovery notice. Never allow ordinary users to choose an arbitrary back-date. Run catch-ups in ascending date order, use each date's as-of snapshots, and respect movement markers and final separation dates. Implement a bounded, transparent backlog with progress and error/retry policy; don't silently manufacture attendance for unsupported cases.
- Add clear tests at 19:59, 20:00, 20:01, 23:59:59, after midnight, first day, weekends, power-off/restart, role switch, transfer date and repeated schedule invocation. A newly added status starts with counter ZERO until assigned to one or more persons by manual attendance or the 20:00 rule.

===============================================================================
08. INTERNAL TRANSFER — EXACT MONTHLY TABLE SEMANTICS
===============================================================================
THIS SECTION OVERRIDES ANY PREVIOUS GENERIC MOVEMENT MODEL'S DISPLAY BEHAVIOR.

Transfer screen: "الإدارة > إدارة القوة > ج) التنقلات > 1) النقل الداخلي".
- On the right: source-site dropdown and filtered active persons for selection; arrow with text "ينقل إلى"; destination-site dropdown excluding selected source; individual/multi-select; confirmation of name, الرقم (ع), source, destination and effective transfer date.
- Transfer takes effect on the CURRENT business date by default; do not silently backdate into a locked day. Record PersonnelMovement and close/open assignment periods with one atomic transaction; site historical assignments must not overlap. If requested change conflicts with an already recorded same-day transfer, separation or another sensitive action, block automatic second transfer and show clear conflict; only use a dedicated authorized reversal/compensating movement with audit evidence, never overwrite the original move.

CRITICAL MONTHLY DISPLAY — EXAMPLE:
Suppose a person moves on 16 October from "الموقع أ" to "الموقع ب":
1) The OLD/SOURCE site monthly table: days 1–15 show their real previously approved attendance statuses. Day 16 shows a MOVEMENT MESSAGE "تم نقله إلى الموقع ب" (with the actual captured destination display name). Days 17–31 in that source-site row are BLANK; do not render attendance statuses there.
2) The NEW/DESTINATION site monthly table: days 1–15 are BLANK. Day 16 shows "تم نقله من الموقع أ" (with the actual captured source name). Starting day 17, attendance is recorded/displayed normally by the application's ordinary manual and 20:00 rules. No regular attendance status on the day-16 movement cell in either site.
3) Transfer annotations are distinct movement cell types (e.g. movement-out, movement-in), NOT records in AttendanceStatusDefinitions; do NOT add them into "موجود", "غياب", "إجازة", "إذن", or customized status counts. Do NOT double count the transferred person in the ALL-SITES force total on the same business date. On the transfer date the person has one current effective destination assignment for today's active force counting, while the source site's monthly historical row remains visible to show the movement.
4) Internal transfer remains in the transfer archive with effective day, historical snapshots, actor and sites, and in the person's report. Changing either site's CURRENT name later must never relabel the frozen source/destination text of historic transfer events unless an explicitly separate versioned annotation is displayed.
5) Filtering a previous month by source or destination site must reflect membership AS OF EACH DAY; a person's prior site dates must not move to their current site. Past empty cells remain empty, not "غير محضر" and not inferred absences.
6) Repeated transfers across several months must show the right historical site segments and event annotations without overlaps. Cross-month transfer at the first/last day must be tested.

EXTERNAL TRANSFER:
- "النقل الخارجي": filter force by site and name/الرقم (ع); request a mandatory free-text external destination; confirm and save the effective date, mark person not active and remove from CURRENT active rosters, but preserve person, previous attendance, movements and archived reports.
- Archive filter internal/external, person name/service number and display columns: "الرقم", "الرقم (ع)", "الاسم", "الموقع", "نوع النقل", "تاريخ النقل". Include destination in movement-type/details.

SEPARATION:
- Under "التقارير والفصل > الفصل", choose person by name or number; separation reason mandatory; first confirm, then a five-second visible countdown before final confirm as in original brief; archive with precise calendar date. Stop active eligibility and disable linked user account, retain full history. In the monthly table mark the effective separation date with "مفصول" as a structural marker, not an ordinary user-defined status; previous real attendance and historical sites remain intact. Do not create future daily attendance after separation.

===============================================================================
09. COMPLETE ARABIC SCREEN MAP AND INTERACTION CONTRACT
===============================================================================
There are FOUR top-level screens. Implement all nested screens below. Preserve navigation breadcrumbs and use role-aware menus. No placeholder pages.

09.1 FIRST — "الشاشة الرئيسية" / dashboard
- Heading "التمام اليومي"; refresh button "تحديث" explicitly reloads displayed counters based on committed database records. Also use targeted update after a successful commit to avoid stale UI; manual refresh remains available.
- Site filter "جميع المواقع" plus every visible active site; changing it recalculates site-scoped totals and the table.
- Counter "إجمالي القوة" = unique active persons in selected site(s) on business date; other counters: one PER ACTIVE attendance status using precisely the defined Arabic name, symbol/color; "غير المحضرين" even at zero; and "نسبة اكتمال التحضير". Status counters of newly created statuses are ZERO until a person has the corresponding recorded today's status.
- A single person is counted in exactly one ordinary attendance-status counter or the unprepared count; internal movement on the same date is a structural exemption and must be accounted for distinctly in a reconciliation/exemption indicator so the force total equation is provable. Formula: eligible daily-status population = sum(all actual attendance statuses) + unprepared. Total active force = eligible daily-status population + active movement-day exemptions, if any. Show the exception count clearly rather than falsely declaring all persons absent/unprepared.
- One clickable filter chip "الكل" plus colored chips for actual statuses. "الكل" shows the full scoped active dataset; clicking a status chip filters the main table by that day's status, while clicking "غير المحضرين" opens the SPECIFIC workflow screen defined in Section 07.
- Main table columns: "الرقم", "الرقم (ع)", "الاسم", "الموقع", "الحالة". Combined site/status filters apply using AND. Dashboard itself must not add a global free-text person search (the source brief requests filters only here).
- Display optional local alert if sites still have unprepared individuals; no external notifications.

09.2 SECOND — "التمام الشهري"
- Arabic heading "التمام الشهري لشهر [actual Arabic month/year]"; default current calendar month and year.
- Site dropdown "جميع المواقع" or one site; at bottom archive month/year dropdowns plus "إظهار"; missing archive message exactly "لا يوجد أرشيف لهذا الشهر" (or grammatically equivalent approved local copy), never fabricated data.
- Read-only table, sticky top day header and right-side fixed basic columns in display order: "الرقم", "الرقم (ع)", "الاسم", "الموقع"; 28/29/30/31 day columns as appropriate, each with day number and Arabic weekday abbreviation. Horizontal scrolling affects day columns, not frozen identifying columns. Vertical scrolling keeps day headings aligned.
- Efficient virtualization/recycling/lazy data retrieval for large rosters; correctly handle both horizontal and vertical scrolling in RTL. Render ONLY current visible region/pages; avoid 10,000 x 31 DOM nodes at once. Bounded month cache, page-size API, cancellation and stable sort.
- Show ordinary attendance short symbol/colors, unprepared distinct from "غياب", structural transfer text on transfer day with hover/click full tooltip/details, separation marker "مفصول", and intentionally blank cells outside person-site assignment. Never draw a moved person's old attendance under new-site historical columns.
- No ability to edit any record in this read-only screen.

09.3 THIRD — "شاشة الإدارة" containing EXACTLY these major sections (add new E report WITHOUT removing old D):

1- "إدارة القوة":
  أ) "التمام": today's force list with site filter; single/bulk attendance + full confirmation as in Section 06.
  ب) "تعديل الأسماء": filter by all/specific sites; modal to edit "اسم الفرد" and "الرقم (ع)"; validate unique service number; propagate current display values by stable IDs to current screens WITHOUT rewriting historic facts; individual/multi-selection archive/removal from current force permitted only to ordinary/general administration, with confirmation and history intact.
  ج) "التنقلات": (1) "النقل الداخلي" (2) "النقل الخارجي" (3) "الأرشيف" as in Section 08.
  د) "التقارير والفصل": maintain the original existing subtasks: (1) "التقارير": search person by name/الرقم (ع), show a chronological/day/month attendance history with counts as originally requested; (2) "الفصل": separation workflow plus archive of separated individuals including name, الرقم (ع), date/day/month and reason. Share the same report domain/query layer with section هـ to avoid duplicate code, but KEEP distinct navigable user features.
  هـ) "التقرير" — NEW USER-REQUESTED SCREEN, mandatory placement directly under (ثالثاً > شاشة الإدارة > 1- إدارة القوة). EXACT specification in Section 10 below.

2- "الحالات والمواقع":
  أ) "الحالات": seed statuses "موجود" symbol "م" light blue; "إجازة" symbol "ج" green; "غياب" symbol "غ" red; "إذن" symbol "إ" yellow. Show all statuses, allow adding/editing status name, symbol, color. On creation status is registered but its dashboard count is ZERO until a person's attendance is approved under it. Counter caption EXACTLY the status name. Do NOT infer attendance/absence or count a newly created status as occupied just because definition exists. Avoid requiring a custom status classification ('present vs absent') the user explicitly replaced; if analytics require a meaning, do NOT alter raw counters or assume one.
  Historical safety: a definition already used in attendance may be renamed (new version) but not physically purged; "حذف" becomes deactivate/hide from FUTURE selection while preserving old monthly reports, status Id and labels as-of events. Unused definitions may be removed safely with audit, if no history references them.
  ب) "المواقع": list sites, add/rename/delete visible site. Protect the system site "غير محدد" permanently. Deleting a site containing currently active persons archives/deactivates it, reassigns current members to "غير محدد" effective TODAY via auditable operations, and retains past site IDs/names/history. If no members remain, can deactivate with history preserved.

3- "الكشوفات":
  1) "استيراد": choose Excel .xlsx; read all worksheets appropriately; map person name, الرقم (ع), location, optional fields; normalize digits; preview detected columns and create-sites proposal; detect duplicates both within file and existing active database; reject invalid/conflicting rows with row numbers and explanations, optionally accept valid rows in one committed transaction; display counts of new people, rejected people, new sites and successful records; export error workbook; no blind overwrite of existing people.
  2) "تصدير": site filter (all/specific), archived/current month filter, year filter, "تصدير" with Windows choose-folder dialog + explicit pre-export summary. If ALL sites, export one combined workbook plus one workbook PER site; if ONE site, export that site workbook only. Columns: "الرقم", "الرقم (ع)", "الاسم", "الموقع" followed by day columns and saved attendance/movement markers for chosen month; months and historically effective sites preserved. Name files safely with Arabic-friendly paths; progress UI and cancel; no UI freeze. Handle overwrites explicitly, never silently overwrite. Use safe cell escaping to prevent formula injection on export.
  3) "تعديل الهيكل للكشف": allow add (typed) / rename / reorder / hide / deactivate custom columns; protect identity/system columns from destructive removal while still permitting display caption/reorder adjustments when safe. Changing captions must NOT change internal IDs, SQL column references, permission checks, historical semantics or stored event keys.

4- "المستخدمين": visible and authorized only to GeneralAdministration and OrdinaryAdministration (ordinary restricted to supervisors). "إضافة" opens form with username, full name searchable/selectable from active force list (not arbitrary outside name), auto-filled الرقم (ع), role selector filtered by permission, password creation, confirm/cancel. Table: "الرقم", "الرقم (ع)", "اسم المستخدم", "الاسم الكامل", "نوع الحساب", "من الذي أضافه". Under account: edit password, deactivate/delete account after confirmation (preserve audit/person); support password change and reset with appropriate actor reauthentication. Supervisor NEVER sees the screen or can invoke API.

5- "سجل العمليات": operation filters by type/date/actor, search by actor/target, and a sortable table at least: "اسم العملية", "المنفذ عليه", "من قام بالتنفيذ", "وقت التنفيذ" and expandable before/after, reason, effective date/correlation ID. GeneralAdministration AND OrdinaryAdministration can edit/delete visible log entries using explicit buttons and audited reasons; Supervisor can only view/search/filter. Original AuditEvents remain intact in a restricted immutable ledger. This user override is mandatory.

09.4 FOURTH — "الإعدادات"
- Display "التمام اليومي", current user, role, app version and logout.
- Encrypted manual backup and import/restore backup, daily automatic backup default 16:00 local with configurable time, history/retention and restoration validation.
- Prefer E:\[program folder] for backup if present/writable as originally requested; offer safe configurable fallback if E: missing, read-only, low on space; do not hardcode the installation directory as the database/backup directory, and do not write into protected Program Files.
- "حذف جميع بيانات البرنامج" with irreversible-operation warnings, password reentry, explicit countdown and SUPER ADMIN ONLY, verified emergency backup and separate external backups retained.
- Theme light/dark, selected backup folder and retention options, integrity check status, application/build details; any settings change logged with actor and timestamp.

===============================================================================
10. NEW "هـ) التقرير" — PRECISE USER-MANDATED PERSON SUMMARY
===============================================================================
PATH: ثالثاً > شاشة الإدارة > 1- شاشة إدارة القوة > هـ) شاشة التقرير.
Do not relocate this feature into the home page or replace "د) التقارير والفصل" with it. It is an added screen with shared underlying report services.

SCREEN BEHAVIOR:
1) Search input accepts partial/full "اسم الفرد" or "الرقم (ع)". Display matched suggestions while typing, with name, الرقم (ع), current site and person identity; internal selection must be PersonId, never ambiguous name alone.
2) Click/select desired person; display a report beginning at the person's original effective enrollment/creation in the application through the EXACT report query time. The report must work for currently active, externally transferred and separated/archived people, preserving full historic data.
3) Main SUMMARY TABLE: ONE summary row for selected individual (or one explicit row per person if a future multi-person enhancement is deliberately added). Columns in this order:
    "الرقم" [row number]
    "الرقم (ع)" [display current number with historic snapshots available separately]
    "الاسم" [display current name with historic snapshots separately]
    ONE DYNAMIC COLUMN PER DISTINCT ORDINARY ATTENDANCE STATUS RECORDED FOR THIS INDIVIDUAL during the report period. The header is that status's clear Arabic name; the value is the COUNT OF DAYS recorded under the status, not a list of names or a sum of unique status definitions. Build dynamic columns from actual individual recorded statuses; sort deterministically by status configuration/order or first recorded date. New status defined with no historical record for this person need not create a report column. StatusId, not mutable status name, identifies the category.
    "التنقلات الداخلية" [number of completed INTERNAL transfer events for the selected person during the lifetime period].
   Do NOT count internal movement markers, external transfers or separation as normal attendance days. Do not count an attendance revision twice: count the final valid status for each day under the applicable as-of-correction policy.
4) In addition to the requested summary columns, provide below the summary (or expandable detail) a read-only chronological operations/history panel with date, operation type, old/new values, original and destination site, performer and execution time. Include changes to person name/service number, attendance corrections, internal/external movements, separation and other operations that targeted the person. A movement details grid shows exact effective dates and "من [الموقع]" -> "إلى [الموقع]"; no losses across several transfers. Keep this supplemental panel OUTSIDE the prescribed core summary column order.
5) Date range in this NEW screen is automatically full lifetime: enrollment to query moment, without default month restriction. Any optional date filters must NOT replace this lifetime default.
6) Button "تصدير إلى Excel" opens Windows Save As dialog. Export the main one-row dynamic-column summary into worksheet "ملخص الفرد"; and the timeline/movement details to additional worksheets "سجل العمليات" and "التنقلات". Use exact IDs and historical snapshots for consistency. Support Arabic RTL workbook display, legible headers, date formats, file naming, progress/error handling and validated generated .xlsx.
7) Report calculations and the workbook must return identical counts. Changes to current names/sites after reportable events may affect the current visible identity header only; MUST NOT change event counts or historical descriptions.
8) Explicit tests: 0 attendance days; status renamed after use; custom status added then used; several transfers in same year; separation; corrected attendance; person renamed and الرقم (ع) changed; rerun export; user is supervisor with permitted read access; large multi-year history.

===============================================================================
11. SEARCH, LOOKUPS, COUNTERS AND PERFORMANCE CONTRACT
===============================================================================
- Search persons by normalized Arabic name variants, substrings where appropriate, full/partial الرقم (ع), Western/Arabic-Indic digits. Preserve raw original name/number and avoid lossy updates. Use indexes and bounded result sets. Debounce search UI; include cancel and result pagination, never fetch the entire historical roster on every keypress.
- Global search accessible on supporting screens, but NOT an extra dashboard person-search field. Clicking a person opens the appropriate contextual details; the new lifetime SUMMARY report remains at its required path in Section 10.
- Counters must be grounded in committed data and stable dates/site membership, not mutable cached client variables. One common query/service calculates all counter components using matching filters; reconcile all-sites totals and avoid duplicates on transfer day.
- Target test scale: 10,000 active persons, multiple sites, 31-day months, several years of attendance and movement events. Set up synthetic datasets and performance benchmarks.
- Initial PERFORMANCE GOALS (measure on a documented representative SSD-equipped Windows machine; targets, not fictitious guarantees): display login screen <3s; ordinary screen navigation <300ms; search 10,000 persons <200ms; switch site filter <300ms; approve 1,000 persons <3s; monthly scrolling responsive; large Excel export asynchronous with progress indicator. If a goal fails, profile actual bottleneck, optimize measured hotspot, and report before/after metrics.
- Use DOM row/column virtualization or a proven equivalent. If the WebView2 HTML monthly grid cannot satisfy sticky RTL columns + dual-axis virtualization after measured testing, use a dedicated WPF virtualized table for that screen, with identical services and visual system; do NOT compromise correctness or create two competing attendance engines.
- Restrict memory allocations, avoid n^2 scans and ad hoc SQL query-per-row patterns, and use paging/chunked scans. Provide unit/integration benchmarks runnable in CI where stable and a dedicated non-blocking local perf harness for full benchmarks.

===============================================================================
12. AUDIT, HISTORY, ACCOUNTABILITY AND AUTHORIZED LOG ALTERATION
===============================================================================
LOG ALL: authentication attempts, creation/edit/deactivation of accounts, permission/role changes, person additions/archival and identity edits, custom field and definition changes, every attendance approval/revision, all site movements, external destination and separation, imports/exports, report exports where appropriate, backup/restore, day/month closure, scheduler auto-run and catch-up, user-visible audit entry edits/deletions, settings changes, failed security-sensitive actions and full reset.

Each immutable AuditEvent stores: eventId, actorId/username snapshot, target entity ID/type, operation code, old value, new value, effective business date where any, actual execution timestamp, reason, correlation/request ID, client/build version and optional hash chain. Never store passwords or SQLCipher keys. All user-facing Arabic descriptions should derive from stable event codes and human-readable snapshots.

USER-SPECIFIED EXCEPTION: OrdinaryAdministration AND GeneralAdministration have permission to EDIT and DELETE displayed rows of "سجل العمليات". Implement exact UX: choose row -> "تعديل" edit visible text/label or clarification fields -> mandatory reason -> confirm -> displayed row reflects change. Choose row -> "حذف" -> mandatory reason and explicit confirmation -> normal list excludes/marks deleted entry. Track author/time/reason and allow admin review of corrected/deleted entries. Supervisor has no mutation action.

Use an append-only evidence layer (AuditEvents) plus an overlay (AuditLogPresentationEdits) to reconcile this granted UI capability with historical accuracy and recoverability. Do not tell users their UI edit physically destroyed an original audit event; it did not. Record the log-edit/delete operation itself as a new immutable event. Test both administrator tiers, rejected supervisor API attempts, filter/search after delete, restoration review, and preservation of attendance/movement history.

===============================================================================
13. BACKUP, ENCRYPTION, RESTORE AND DISASTER RECOVERY
===============================================================================
- Protect the encrypted database key separate from passwords. Use suitable Windows DPAPI protection for the local key-wrapping material and a separately generated EXPORTED RECOVERY KEY for recovery on another PC. Never rely on a machine-bound DPAPI ciphertext alone for portability.
- Store portable/installer application data and secrets in a safe per-user application data folder or explicitly selected writable portable-data directory, with a clear, tested policy. Never embed personal data inside versioned application source files or wipe data on software update.
- Use SQLite's supported consistent online backup strategy appropriate for SQLCipher/WAL; never use arbitrary filesystem copy of only a live .db file. Verify restored copies with database-integrity checks and correct key/material. Encryption alone is NOT proof of backup integrity.
- Default backup schedule daily 16:00 local, user-configurable; manual backup and pre-destructive/pre-large-import backups; robust rotation policy with several historical copies; checksum and restore test; explicit progress and warnings on failure.
- The INSTALLER must register suitable Windows scheduled backup and 20:00 attendance tasks with the minimum required rights; the PORTABLE build must either support explicitly opted-in per-user scheduled tasks or transparently explain that background tasks cannot run while the program/PC is off, with on-launch reconciliation. No network service is allowed.
- Preferred output directory on E: if it exists; if not, explain and choose a safe alternative. Do not equate E: with executable/install path. Recommend an additional external/offline backup.
- Restore is a protected, explicit process: choose file, inspect format/schema/version/crypto metadata, validate password/recovery key, verify integrity, preview counts/date, capture backup of current data, obtain confirmation, perform atomic swap/restart, revalidate logins and integrity, and keep reversible rollback if restore fails. Data migration after restore must be explicit and tested; never silently overwrite active database with unreadable/incompatible files.
- Full reset must not delete external/off-device backup archives. If user requested in-app deletion of local program-owned backup copies, list exactly those copies, preserve an offline recovery copy, require super-admin multi-confirmation and never traverse unrelated folders.
- Test crash, disk full, E: absent, corrupted backup, key loss, a fresh second PC, database schema upgrades, and scheduled task failure.

===============================================================================
14. IMPORT/EXPORT AND HISTORICAL EXCEL SAFETY
===============================================================================
- Use Excel .xlsx reader/writer, not spreadsheet automation requiring Microsoft Office. Preserve Arabic strings and digit formats. Support multiple worksheets and user-adjustable column mapping during preview; identify exact missing required columns and malformed values.
- Each import row: individual identifier service number, person name and associated site, optional custom columns. Clean leading/trailing whitespace carefully, normalize for comparison only, avoid destructively normalizing actual names. Unique and cross-worksheet duplicate detection. If duplicate الرقم (ع) belongs to a different person, reject with reason. No covert merging.
- Staging preview: parsed row totals, accepted, rejected, duplicate, new sites, existing sites, and detailed errors downloadable to Excel. On commit, create sites/persons in appropriate relation order as a single transaction; keep import batch audit. A deliberate partial-valid-rows mode is allowed ONLY after explicit acceptance of a precomputed filtered plan.
- Exports of all sites must produce a combined workbook plus separate per-site workbooks; site-specific output only for requested site. Handle archive months/years and transfer-day text without reconstructing past values from current assignment.
- Excel reports under the NEW "هـ) التقرير" follow Section 10; generic attendance Excel follows the original screen spec. Do not conflate formats.
- Escape leading formula trigger characters (e.g. =, +, -, @ and tab where applicable) when exporting untrusted text; use actual text cell types or other safe library settings. Verify workbook opens and formulas are not executed unintentionally.
- File dialogs must support long Unicode paths and safe replacement confirmation; clean up partial output when cancelled/failed. The UI remains interactive and progress is visible for large exports.

===============================================================================
15. ROBUSTNESS, ERROR HANDLING AND UX ACCEPTANCE
===============================================================================
- Beautiful but restrained professional RTL interface (not bulky or code-heavy). Consistent theme tokens, status colors/symbols and charts/counters. Light/dark modes, accessible contrast, resizable window, modest minimum resolution and correctly frozen table headers/identity columns.
- Every button works: show skeleton/loading states, no dead links, disabled actions with explanation, progress/cancel for long operations, user-friendly Arabic messages, keyboard shortcuts and dialogs respecting focus.
- The source user's workflows prefer confirmation before changes. For individual/multi-person attendance, internal/external transfer, site deletion, user deletion, separation, restore and reset, show exactly what will change, who/where/from/to and whether it is irreversible.
- Prevent double submission, reentrant background jobs and races using idempotency keys, transactional unique constraints, explicit concurrency handling and retry rules for BUSY database operations.
- Logs and crash reports stay local, do not reveal secrets and should be exportable by authorized administrators.
- Automatic integrity check on startup after abnormal exit and an explicit diagnostic function in settings. Show recovery guidance rather than silently deleting a damaged database.
- Keep user settings local and separated from domain records; ship no analytics or network access.
- All UI effects from database commits should be consistent. Manual home refresh is retained but NEVER required to keep a newly saved report fact correct. Refresh affected result sets when necessary; full grid refresh only on explicit user action or changed query scope.

===============================================================================
16. DETAILED PHASED IMPLEMENTATION ORDER AND GATES
===============================================================================
Implement phases in this exact dependency order. Do not skip. Keep code compiling and tests green throughout. One phase produces source commits, executable acceptance evidence and GitHub artifacts/logs. If using AI assistance, work phase-by-phase within available context but maintain the full specification as the master contract. Never replace unfinished phases with TODO stubs or claim final readiness prematurely.

PHASE 00 — REQUIREMENTS BASELINE AND ACCEPTANCE MATRIX
Deliver: Requirements.md containing every screen/action in this specification, permission matrix, screen flow, Arabic labels, event taxonomy, date/20:00 policy, movement-day acceptance examples, backup/recovery policy, acceptance IDs and traceability grid. Provide an explicit open-risk section but DO NOT defer any specified feature. Convert apparent contradictions using the priority rules above; do not silently discard. Add architecture decision records: historical immutability, site effective-dating, status-definition versioning, append-only audit plus admin editable view, WebView2 bridge, offline scheduling limits and first-run credentials.
Gate: documented requirements cover all source screens and user overrides; reviewer can trace each to tests.

PHASE 01 — SOLUTION SCAFFOLD, SECURE FIRST RUN, BUILD PIPELINE
Deliver: C#/.NET 10 multi-project solution, WPF shell, local HTML/CSS/JS build/load, strict WebView2 bridge, Arabic RTL login, first-run GeneralAdministration secure credential setup, basic role gate, encrypted SQLite/SQLCipher connection and migration bootstrap, deterministic clock abstraction, seed states and protected site, GitHub Actions Windows workflow with NuGet cache and test publishing.
Gate: CI passes, clean offline boot test passes, browser cannot open external URL, direct unauthorized action rejected, database verified encrypted.

PHASE 02 — COMPLETE HISTORICAL SCHEMA, AUTHORIZATION AND AUDIT FOUNDATION
Deliver: all core schema tables/indexes/constraints/migrations, stable IDs, effective date identity/site/status history, audit ledger and administrator-visible editable projection, repository service tests, Argon2id auth and session policies, permissions matrix including log edits, migration rollback and version test data.
Gate: identity and site changes do not alter earlier records; ordinary admin can create only supervisors and edit visible audit; supervisor cannot invoke users/audit mutation; no orphan entities or overlapping assignments.

PHASE 03 — PERSONS, SITES, STATUSES, CUSTOM COLUMNS AND USER MANAGEMENT
Deliver: active personnel roster, name/service-number editing and archival, site management ("غير محدد" protected), default/custom status creation/deactivation and ZERO counters, field-definition UI, users creation only from force, user editing/deactivation and auto-deactivate on external transfer/separation.
Gate: integrity, unique numbers, historic definition/snapshot preservation, role tests and responsive roster search succeed.

PHASE 04 — TODAY'S ATTENDANCE AND ALL DASHBOARD COUNTERS
Deliver: individual/bulk status selection, draft storage, confirmation, per-day uniqueness, status counters and unprepared counter, dashboard site/status combined filtering, partial update and manual refresh, deterministic attendance correction/audit rules.
Gate: no double submits or partially committed batches; every eligible person reconciles to exactly one approved-status or unprepared state for the day (plus movement exemptions); absence never conflated with unprepared.

PHASE 05 — 20:00 ATTENDANCE AUTO-RULE AND DAY/MONTH CLOSURE
Deliver: clock-injected auto-run engine, scheduled 20:00 entry points, installer/portable scheduling strategy, missed-run recovery, idempotency, prior-day copying only for eligible unprepared persons, explicit scheduler history, day/month locking and abnormal clock detection.
Gate: deterministic 19:59/20:00/retry/restart tests; power-off limitation handled honestly, no invalid backdated manual edits, auto-run never fills internal-transfer date.

PHASE 06 — INTERNAL/EXTERNAL TRANSFER, SEPARATION, HISTORIC MONTHLY GRID
Deliver: transfer forms/archive, separated archive, correctly effective-dated person assignments, read-only monthly grid with sticky RTL headers/columns and dual-axis virtualization, EXACT "تم نقله إلى" / "تم نقله من" date examples and blanks in old/new site months, day-of-transfer non-attendance semantics and separation markers.
Gate: cross-site and cross-month tables match Section 08 byte-for-byte in logical values; no duplicate all-sites headcount; current site rename does not rewrite old move text; grid performance measured.

PHASE 07 — REPORTS INCLUDING MANDATORY NEW (هـ) REPORT
Deliver: existing "د) التقارير والفصل > التقارير" and the separate new "هـ) التقرير" with identity search, lifetime dynamic status-day-count columns, "التنقلات الداخلية" count column, chronological operations detail, Excel summary/timeline/movement export. Include historical archived persons.
Gate: report totals match attendance events on test oracle; renamed person/status/site and repeated transfers preserve counts; Excel values equal screen values; NEW screen is at exact nested navigation path.

PHASE 08 — EXCEL IMPORT/EXPORT AND CUSTOM ROSTER LAYOUTS
Deliver: multi-worksheet staged import, detailed rejection/preview and automatic site creation in confirmed transaction, source roster export all-site + per-site variants, monthly status/movement export, custom column layout editor, safe Excel value encoding.
Gate: import on duplicates/malformed rows does not corrupt data; all-site export yields combined and per-site files; archived month export remains historically correct.

PHASE 09 — LOG UI, SETTINGS, BACKUP, RECOVERY, FULL RESET
Deliver: full searchable audit UI with role-limited edit/delete for BOTH admin tiers, restore history view, backups daily at 16:00 and on demand, configurable retention/E: fallback, recovery key export and cross-PC restore, verified restore and corruption checks, secure reset restrictions, user info/settings, logout, theming.
Gate: two admin roles may edit/delete presented log rows but immutable evidence persists; supervisor attempts rejected; scheduled/manual backup/restore tests pass; super-admin reset cannot remove external backup; settings operations audited.

PHASE 10 — PERFORMANCE, ARABIC UX, SECURITY AND FAILURE-MODE HARDENING
Deliver: virtualized grid tuning, SQL indexes and query plans, synthetic multi-year/10k-person dataset, accessibility and RTL checks, event-replay and historical consistency checks, malware-resistant Excel output handling, interruption tests and pre-release QA report with actual timings.
Gate: no critical regressions, known performance targets met or explicitly explained with measured evidence and corrective action plan. No critical security issues left unresolved.

PHASE 11 — FINAL PACKAGING, CLEAN-MACHINE VALIDATION AND RELEASE
Deliver: signed builds IF a valid signing certificate is provisioned (otherwise document unsigned status truthfully), self-contained .NET publish as required, local WebView2 Runtime deployment solution, PORTABLE zip/folder and Windows INSTALLER (MSIX/EXE/MSI according to verified packaging constraints, prefer reliable conventional installer for scheduled tasks), compatible app icons/version strings, SHA-256 checksums, clean install and uninstall test, portable no-install test, both app variants run with network disabled, backup data persists across updates, instructions in Arabic.
Gate: two downloadable, independently tested real Windows release artifacts. Never label source-only ZIP as "portable app". Verify scheduler registration and uninstallation do not delete user data unexpectedly. Tests on fresh Windows runner/VM or documented equivalent, not just developer PC.

PHASE 12 — HANDOVER, SUPPORTABILITY AND FINAL GO/NO-GO
Deliver: full GitHub source, tagged private release, two binaries/packages, README_AR.md with setup/use/restore/backup/security, ARCHITECTURE.md, DATABASE_SCHEMA.md, OPERATIONS_POLICY.md, TEST_MATRIX.md, QA_REPORT.md (actual passes/fails and machine context), RELEASE_NOTES_AR.md, SECURITY_MODEL.md, MIGRATION_GUIDE.md, LICENSES/third-party notices and troubleshooting. Perform cross-feature smoke test and freeze release only on green gates.
Gate: release acceptance checklist in Section 18 fully satisfied and user has a credible install/run/restore path.

===============================================================================
17. GITHUB ACTIONS PIPELINE AND RELEASE REQUIREMENTS
===============================================================================
- All development in PRIVATE GitHub repo with branch protection where possible. Meaningful commits per phase, no rewriting shared completed phase tags without an explanation.
- On every push/PR: checkout -> setup .NET 10 -> restore with NuGet dependency cache keyed to lock files -> build Release with warnings relevant to correctness treated as errors -> run unit and integration tests -> collect TRX/test summaries -> lint/check web assets and no-network references -> run migrations/integrity tests. Windows runner for WPF/WebView2 end-to-end tests.
- Test quality gates fail the workflow on authorization bypass, data-history regressions, broken schema migrations, transfer-day rule failure, 20:00 race, backup corruption, a missing new (هـ) report, or packaging failure. No continue-on-error masking for required checks.
- Use stable dependency versions and NuGet lock files, deterministic artifact names, clear software versioning and per-phase release notes. Avoid duplicate/redundant workflow jobs; cache only safe restored package content, NEVER encryption keys or private databases.
- Final workflow separately builds portable and installed products, smoke tests launch/startup including packaged assets and SQLCipher native binaries, computes hashes, and attaches them to a PRIVATE release or Actions artifacts. Do not publish real rosters, source personal data or keys into workflow artifacts. Store code-signing credentials as GitHub encrypted secrets only if the user provides them.
- Each phase must include: changed files list, implemented requirements IDs, tests run and results, limitations/blockers, actual GitHub Actions run URL/ID if available, and exact instructions for acceptance. Wait for phase gate to pass before beginning next phase.

===============================================================================
18. MANDATORY GIVEN/WHEN/THEN TEST ACCEPTANCE MATRIX
===============================================================================
AT-001 Given a newly provisioned offline PC, when launching portable or installed build with internet disabled, then the login/first-run screen renders and all packaged UI assets load with no external requests.
AT-002 Given the initial administrator account, when completing safe first-run enrollment, then a unique administrator secret is established and no original fixed password is usable as a permanent credential.
AT-003 Given Supervisor role, when attempting to open or call Users API, then it is unavailable/forbidden even with forged WebView2 message.
AT-004 Given OrdinaryAdministration, when creating Supervisor, then succeeds; when creating OrdinaryAdministration, then forbidden. GeneralAdministration can create both.
AT-005 Given any unauthorized actor, when invoking complete data reset, then request denied by application services even if action is spoofed.
AT-006 Given newly created attendance status "مهمة" with no attendance, when viewing dashboard, then the counter caption is "مهمة" and value is ZERO.
AT-007 Given a person with status "مهمة" approved today, when dashboard is refreshed, then the "مهمة" counter increments correctly, the unprepared counter decrements and any absence count is unaffected.
AT-008 Given approved "غياب" for person on today's date, when calculating unprepared, then that person is NOT unprepared.
AT-009 Given an active person unprepared today, when clicking "غير المحضرين", then site and previous-status filters and exact five table columns appear.
AT-010 Given a person filtered by previous-status "إجازة", when selected for today "موجود", confirmation shows yesterday's "إجازة" and today's "موجود"; approve changes today only; yesterday remains "إجازة".
AT-011 Given person has yesterday "غياب" and no today record, when 20:00 job executes, then today gets new approved "غياب" with source 20h-auto, counted in "غياب"; yesterday unchanged.
AT-012 Given yesterday's attendance does not exist, when 20:00 job executes, then do NOT fabricate today's attendance; person remains unprepared with reason.
AT-013 Given a manual status saved at 19:59, when 20:00 job runs, then it cannot replace the manual value.
AT-014 Given two invocations of 20:00 job or a repeated confirm, when processing, then just ONE approved daily record exists, with an auditable duplicate/no-op.
AT-015 Given PC powered off at 20:00, when restarted later, then detect missed job, apply documented deterministic catch-up with actual vs due timestamp, report limitations; never pretend it ran while powered off.
AT-016 Given a same-day internal transfer, when 20:00 runs, then NO normal status is added for the transfer date.
AT-017 Given person at Site A days 1-15 and transferred to B day 16, when viewing A's monthly grid, days 1-15 show original approved status, day 16 "تم نقله إلى الموقع ب", days 17-end are BLANK.
AT-018 Given same transfer, when viewing B's monthly grid, days 1-15 are BLANK, day 16 "تم نقله من الموقع أ", and normal attendance begins from day 17 only.
AT-019 Given transferred person on day 16, when calculating combined force, then PersonId is counted once, transfer marker isn't an ordinary status.
AT-020 Given Site A renamed Site C AFTER day-16 transfer, when reopening archived October movement, then source historical transfer text remains original Site A snapshot, while current site list shows renamed Site C.
AT-021 Given person's name and الرقم (ع) changed today, when querying last year's historical records, then previous IDs/snapshots, attendance and movement history remain correct.
AT-022 Given an attendance status renamed or deactivated, when opening an older archive, then the original recorded event remains interpretable and counts are based on the same StatusId.
AT-023 Given same individual with 5 "موجود", 3 "غياب", 2 "إجازة" and 2 internal transfers, when opening "إدارة القوة > هـ) التقرير", the summary has dynamic status columns 5/3/2 and "التنقلات الداخلية"=2; transfer days do not add to status counts.
AT-024 Given the above report, when exporting Excel, then the summary counts and operations/movement sheets match the screen and historical event data exactly.
AT-025 Given archived externally transferred or separated individual, when searching new (هـ) report, then all prior attendance/movement/change history remains available.
AT-026 Given a month without archive, when user selects year/month and "إظهار", then show "لا يوجد أرشيف لهذا الشهر" rather than stale/fictional data.
AT-027 Given OrdinaryAdministration, when editing a displayed audit entry with reason, then edited display appears, underlying original AuditEvent remains, and new correction event records actor/time/reason.
AT-028 Given GeneralAdministration, when deleting a displayed audit entry with reason, then hidden/marked as deleted in ordinary list and immutable evidence survives.
AT-029 Given Supervisor, when attempting edit/delete log via UI or bridge, then denied.
AT-030 Given a deleted non-system site with current members, when confirmed, then today's current members move to protected "غير محدد" and old assignment history/site snapshots remain intact.
AT-031 Given user-defined status with historical attendance, when user presses Delete, then it is deactivated for future use and prior records are still readable.
AT-032 Given Excel file with duplicate الرقم (ع), malformed names and two sheets, when previewing import, then detailed rejected rows and accepted/new-site counts are correct; no DB changes before approval.
AT-033 Given an approved import, when a database exception occurs midway, then no partial state persists; either explicit accepted set all commits or rolls back.
AT-034 Given all-sites monthly export, when exporting, then combined file PLUS one file per site are created, and each shows historical assignment/transfer markers correctly.
AT-035 Given one selected site, when exporting, then only that site's export is produced.
AT-036 Given large export, when running, then UI stays responsive, shows progress and supports safe cancellation.
AT-037 Given database backup while attendance activity occurs, when restored on another PC with proper recovery key, then data is consistent, decryptable and matches verification checks.
AT-038 Given missing/unwritable E:, when backing up, then user receives explanation, backup is placed in verified safe fallback and no silent data loss occurs.
AT-039 Given abrupt interruption during bulk attendance/transfer, when reopening, then transaction either fully committed or fully rolled back; history remains reconciled.
AT-040 Given closed prior day, when ordinary user tries to modify it, then refused with explanatory Arabic message, except separate authorized audited emergency override if explicitly enabled; system missed-20:00 recovery is auditable and distinct.
AT-041 Given app updated to a newer database schema, when migration runs, then source data and historic reports are preserved and backed up.
AT-042 Given clean install/uninstall/reinstall, when starting, then user data and recovery options have not been silently erased; portable version runs without app installation.
AT-043 Given 10,000 active persons over years, when scrolling monthly day columns and rows, then tested virtualization maintains usable responsiveness with frozen RTL headers/identification columns.
AT-044 Given expired/deactivated user or person separated/external-moved, when authenticating, then account disabled while immutable records still attribute old actions to that user.
AT-045 Given custom field name changed, when rendering old report and performing database queries, then internal field ID and data remain intact.
AT-046 Given normal dashboard filters site + status, when filtering, then both predicates apply simultaneously and counts/table refer to same committed day and site snapshot.
AT-047 Given abnormal device clock rollback, when entering sensitive new attendance or moving person, then suspicious rollback is detected and controlled action/alert occurs; no false trusted-time guarantees.
AT-048 Given general-admin deletion attempt after unsuccessful emergency backup, when trying to confirm, then reset is denied; external archives cannot be traversed/wiped by default.
AT-049 Given installed app runs local scheduled 20:00 job while UI closed and PC awake, when job executes with proper prerequisites, then database is updated even with no WebView2 window open.
AT-050 Given user changes today's manual status in an approved revision, when reporting the day, then exactly one final status counts while revision history shows before/after and actor.

AUTOMATE as many above as possible; make manual-only tests explicit with reproducible steps and evidence (screenshots/logs). For any requirement not directly testable in CI, provide a specific clean-machine or QA procedure; do not silently omit it.

===============================================================================
19. NONFUNCTIONAL REQUIREMENTS, QUALITY AND RELEASE DECISIONS
===============================================================================
- Privacy: no telemetry, web requests, auto-update requiring internet, crash-report upload or cloud backup.
- Durability: ACID writes, integrity checks, archive preservation, transaction boundaries, versioned schema and full rollback paths.
- Security: Argon2id password verifier, secret isolation, local session management, short-lived authentication context for critical actions, least privilege, strong local secure default and restricted file ACLs.
- Maintainability: clear separation of responsibilities, English code naming + Arabic resource localization; no uncontrolled string matching of Arabic labels in core domain rules. Typed enums/IDs, no SQL interpolated user values, unit-testable clock and filesystems.
- UI: Arabic native appearance with right-to-left alignment, consistent light/dark, status color text alternatives, accurate business messages, tab/key support, protected operations with confirmation.
- Data size: multi-year history for tens of thousands of persons without forced network/server changes. Do not prematurely add microservices, HTTP service, distributed cache, heavyweight UI frameworks or cloud components.
- Portability: portable build means launching compiled binary without installer, not merely the source tree. Fully declare where user database, WebView2 data and recovery key live and how to move them safely.
- Installer: proper shortcuts, product registration/uninstallation, permissions, offline prerequisites, scheduled task registration and safe uninstall. No destructive deletion of database on upgrade/uninstall by default.
- Supply-chain: dependencies licensed appropriately and notices included, pinned versions, build repeatability, security scanning possible with online BUILD time (never online RUN time).
- Resource use: do not retain huge grids/histories in RAM just because 10k records fit in one test.

===============================================================================
20. INSTRUCTIONS FOR THE IMPLEMENTING AI — HOW TO PROCEED
===============================================================================
1. Treat this prompt as the authoritative COMPLETE task specification. Start by creating the traceability matrix, architecture diagram, schema/migration plan, and phase gate checklist.
2. Implement actual code and files in the private GitHub repository, not pseudo-code or broad instructions. Never assume external project files other than this prompt. Create full solution from scratch.
3. Ask for user action ONLY when inherently required (e.g. granting GitHub access/repository setup, a code-signing certificate, or placing an encrypted recovery key). Do not ask for routine choices that this document already specifies.
4. Stage all work through the exact phases, ensure GREEN Actions build/test after each. On a failing phase, inspect source and logs, repair ROOT CAUSE and rerun tests before continuing. Keep build cache efficient and safe.
5. Any change to this prompt's mandated operational semantics is a blocking discrepancy requiring explicit user approval, not a discretionary simplification.
6. Never report the application COMPLETE without verified Windows portable and installer artifacts plus relevant test results. If environment/tools cannot perform a needed operation, say precisely what is blocked; do not invent build run IDs, links, images, released packages or pass results.
7. Provide at each phase a concise English engineering report with critical Arabic names kept exact; for final handover provide Arabic installation/use instructions and clearly labeled final artifacts.
8. End only when every mandated screen and workflow, especially history invariants, unprepared 20:00 behavior, movement-day display, BOTH-admin visible audit editing/deleting, and the new هـ report, are present and tested.

===============================================================================
21. FINAL NON-NEGOTIABLE CHECKLIST / RELEASE CONTRACT
===============================================================================
[ ] Four original top-level screens and all nested screens exist.
[ ] Three role tiers implemented correctly, with both admin tiers allowed visible audit EDIT/DELETE and supervisor denied.
[ ] No permanent bundled shared admin password; secure first-run enrollment works offline.
[ ] A stable PersonId and effective-dated identity/assignment/attendance/movement history preserve past facts after changes.
[ ] Default and dynamic status counters work, including ZERO immediately after new status creation.
[ ] غياب remains an approved status; غير المحضرين has its clickable filters, five-column table and manual selection/confirmation.
[ ] The 20:00 rule copies EXACT yesterday's approved status ONLY for still-unprepared eligible people, handles offline/scheduler limitations honestly and never changes yesterday.
[ ] Transfer-day source/destination messages, empty before/after cells and attendance beginning NEXT day match required examples.
[ ] Month table read-only, fast and fully RTL with fixed identity columns and day headers.
[ ] Full lifetime "هـ) التقرير" is at its exact requested nested location and contains dynamic per-status count columns and internal transfers count.
[ ] Excel export of new report, monthly attendance, all sites and each site is accurate and safe.
[ ] Existing "د) التقارير والفصل" remains functional alongside the new "هـ) التقرير".
[ ] Import preview, duplicate rejection, safe transactional commit and error report are functional.
[ ] Protected "غير محدد" and historical site/status data survive deletes/deactivations.
[ ] Automatic and manual encrypted backups, verification and safe cross-PC restore work.
[ ] Current-day/month closure and system catch-up are explicitly audited and tested.
[ ] No online runtime dependency, network request or external CDN.
[ ] GitHub Actions builds/tests every phase and fails on functional regression.
[ ] Final PORTABLE and WINDOWS INSTALLER releases are independently testable on a clean compatible Windows PC.
[ ] Arabic documentation and honest QA release evidence accompany the final packages.

FINAL ORDER: BUILD AND DELIVER THE REAL, COMPLETE, WORKING, SECURE, OFFLINE WINDOWS APPLICATION "التمام اليومي". PRESERVE THE HISTORICAL RECORD OF PERSONS, ATTENDANCE AND ALL MOVEMENTS ABOVE ALL ELSE. DO NOT IMPLEMENT A SHORTCUT THAT CHANGES PAST FACTS WHEN PRESENT VALUES CHANGE. ALL USER OVERRIDES IN THIS DOCUMENT ARE BINDING.

END OF MASTER IMPLEMENTATION PROMPT
