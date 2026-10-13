# Authorization Matrix — mandatory business-service policy

| Operation | الإدارة العامة | الإدارة العادية | المشرفون |
|---|:---:|:---:|:---:|
| Dashboard and status counts | ✓ | ✓ | ✓ |
| Monthly force accountability, archives | ✓ | ✓ | ✓ |
| Daily attendance and corrections | ✓ | ✓ | ✓ |
| Internal/external transfer, dismissal | ✓ | ✓ | ✓ |
| Edit personnel name / number | ✓ | ✓ | ✓ |
| Manage sites, statuses, optional attributes | ✓ | ✓ | ✓ |
| Automatic/smart import, Excel export | ✓ | ✓ | ✓ |
| Search, individual reports, audit viewing | ✓ | ✓ | ✓ |
| Ordinary settings, backup and restore | ✓ | ✓ | ✓ |
| Add/manage ordinary admin users | ✓ | — | — |
| Add/manage supervisor users | ✓ | ✓ | — |
| User management menu | Full | Supervisor accounts only | Hidden |

**Rules:**

- Only the foundational General Administrator is exempt from selecting a person in the personnel registry.
- All other accounts must be linked to an existing person, autocomplete names only, autofill `الرقم (ع)`.
- New-account passwords consist of exactly three English letters, three digits and one special character (seven total, arbitrary order, no whitespace); foundational user retains the user-specified original password instead.
- Edit can only change the account password; Delete deactivates the account, blocks future login, invalidates sessions and preserves audit attribution.
- Ordinary admin cannot add/manage other ordinary admins; supervisors cannot add/manage anybody and cannot access user management via direct routes or service invocations.
- Operational permissions should **not** be arbitrarily weakened for supervisors.
- Reset/destructive operations retain the extra password-confirmation safeguards required by their individual workflows.

Do not implement these permissions only by hiding UI controls; verify at the application service/domain boundary, with dedicated negative tests in phase 31 and phase 39.

## PART V implementation (0.0.5)

This permission table is now enforced by `lib/core/security/account_policy.dart`
and checked by `OfflineAuthenticationService.requirePermission()` before the
`UserManagementService` performs changes. PostgreSQL/server privileges are not
used; the future encrypted SQLite repository will expose only authorized
application operations. Foundation is protected by SQLite overlay triggers
`assets/database/part_v_authorization.sql`.

These services and policies are covered by SQLite + Flutter test suites, but
they are **not connected to a production login screen or persistent encrypted
SQLite until the prescribed authentication/database integration phases**.
