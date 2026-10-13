# PART V — Complete Account and Permission Policy (source milestone 0.0.5)

## Scope: sections 11 and 12 only

Delivered as an additive change to the exact Part IV repository. Prior schema,
PART III/IV SQL triggers, force/date algorithms, previous tests, and Arabic
Windows branding are preserved. No fake operational menus or database-backed
login screen are introduced before encrypted persistence exists.

| Part V obligation | Actual implementation | Tests |
|---|---|---|
| Fixed founding account | Stable ID, `adwas`, GENERAL_ADMIN, null personnel association, idempotent SQL bootstrap | Python 01, 04; Dart bootstrap |
| Initial password exactness | Verified **precomputed salted PBKDF2-HMAC-SHA256** password verifier; no plaintext in compiled runtime files/SQL | Python 02, 03, 19; Dart password fixture |
| Protect founding administrator | SQL triggers prevent removal, renaming, disabling, changing role/person link/verifier; avoid duplicate system admin | Python 05–11; Dart bootstrap |
| Offline password hashing | PBKDF2-HMAC-SHA256, per-account random 16-byte salt, 210000 iterations, 32-byte derived key, fixed-time compare of full digest | Dart `password_verifier_test.dart` |
| New user password policy | Exactly three ASCII letters, three ASCII numerals, and one ASCII printable special character; no mandatory password change on foundational account | Dart password tests |
| Permission matrix | Central `AccountPolicy` contains all routine operations plus five role-sensitive operations; only general admin can manage ordinary admins; ordinary admin may manage supervisors; supervisors have zero user-management privileges | Dart matrix tests |
| Authorization beyond hidden UI | `OfflineAuthenticationService.requirePermission` reloads live account, validates issued token, checks inactivity, status, and role; user-management service calls policy before changes | Dart auth/user-management tests |
| Link account to existing personnel | `PersonnelDirectory.findById(personId)` must return an active registered person; no arbitrary typed name can create an account | Dart management tests |
| No physical account deletion | Soft-deactivation instead, account identity/role cannot be altered; retired account cannot be resurrected | Python 13–17, Dart auth tests |
| Login throttling and session | 3 failed attempts then exponential local cooldown; unpredictable session ID; 10-minute inactivity expiration; sign-out; live disable check | Dart authentication tests |
| Privacy and offline | No network client, backend, or telemetry introduced; no plaintext secret in `lib/` or SQL assets | Python 19–20 |

## Security and deployment boundary

The foundational password is user-mandated and fixed. Such a predictable/shared
credential is inherently weaker than a unique secret, even with safe hashing;
private GitHub source control alone does not resolve this. This release follows
the explicit contract and does not force rotation or print a login hint.

The password verifier is a salted hash, **not encryption of the password**.
It is sufficient for password verification when backed by a secured store, but
it does not encrypt the database itself. Database key management and native
Windows encrypted SQLite remain mandatory before actual on-disk accounts or
people can be stored.

`assets/database/part_v_authorization.sql` is an additive, repeatable SQL overlay
that executes after `schema_v1.sql`, `seed_v1.sql`, and `part_iv_rules.sql`.
It is exercised against real SQLite in-memory here and must be formally
registered through migrations before encrypted persistence is enabled.

`InMemoryAccountStore` is for unit tests and demonstration of service contracts
**only**, not an application runtime store. No actual login screen is enabled
in this interim build, because that would imply secure persistent credentials
when encrypted SQLite is not integrated. The service layer is implemented and
unit-tested; the full production UI, audit sink, durable throttle/session
history, transaction-bound personnel-directory adapter, and backups follow
in later scheduled phases. In particular, do not mistake compile-time tests
for successful production authentication.

Account mutations must be paired with append-only audit events when the
production transaction/repository adapter is integrated. Destructive data
operations must preserve their separate password-confirmation gates at the
UI and service layers. The requested three-role matrix is implemented without
adding extra limits on supervisor's ordinary operations.

## Build acceptance

1. Upload the extracted files (including `.github/`) over the same private
   `Win-manger` repository; do not upload actual database files or secrets.
2. Require Python SQLite checks, `flutter analyze`, Flutter tests, contract
   validation, and Windows Release build to succeed on GitHub.
3. Verify that the `Altamam_AlYawmi_Part_V_Windows_x64` artifact includes the
   executable **التمام اليومي.exe** and DLL/data files.
4. Confirm this is the **Part V authentication-policy foundation screen** and
   not yet a database-backed login application.
5. Do not proceed to Part VI until the GitHub check is green. If failed, correct
   this same project and re-test before continuing.
