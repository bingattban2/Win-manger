# PART VI — Application Architecture and Mandatory Operation Pipeline

## Delivered in 0.0.6+6

### Section 13 — Layered feature architecture

The existing production-facing source stays intact. Shared interfaces and
orchestration were added under `lib/core/`, and a dependency composition root
under `lib/bootstrap/`. All specified feature folders are present; each has
`presentation/`, `application/`, `domain/`, `repositories/`, and `infrastructure/`
subfolders. Most are **unimplemented placeholders**, marked with `.gitkeep`
instead of misleading or unused Dart screens. The implemented Sites example
provides domain models, repository contract, and application operation.

Features SHALL import domain and repository contracts from their own layer.
Their presentation layer SHALL call application controllers/services only, not
SQLite or `OperationAuditWriter`. The composition root supplies the shared
session authorizer, transaction executor, audit writer, and state invalidator.

### Section 14 — Mandatory operation pipeline

`OperationCoordinator<Command, Snapshot, Result>` implements the shared
algorithm. `RenameSiteOperation` demonstrates real business preconditions,
identity-safe state changes, revision comparison using the **existing**
`sites.updated_at` database field, historical entry, and invariant checks.

| Contract step | Implementation |
| --- | --- |
| 1-2. Start + collect | Presentation supplies typed command |
| 3. Normalize | `BusinessOperation.normalize()` |
| 4. Validate | `BusinessOperation.validate()` |
| 5. Session | `OperationAuthorizer.require()` |
| 6. Authorization | Same method applies PART V `AccountPolicy` |
| 7. Read current | `readCurrent()` |
| 8. Preconditions | `checkPreconditions()` |
| 9. Preview | `OperationDescription` and single-use `PreparedOperation` |
| 10. Confirm | Explicit `confirmed` required; unconfirmed request never mutates |
| 11. Transaction | `TransactionExecutor.runInTransaction()` |
| 12. Update authoritative | `BusinessOperation.apply()` |
| 13. Record history | Mandatory `recordHistory()` |
| 14. Audit | Mandatory `OperationAuditWriter.append()` |
| 15. Check invariants | `BusinessOperation.checkInvariants()` |
| 16. Commit | Transaction executor commits after callback successfully returns |
| 17. Refresh | `OperationStateInvalidator.invalidate()` after commit only |
| 18. Result | `OperationReceipt` includes audit ID and refresh state |

**Concurrency:** commit reauthorizes the actor, requires the same account that
requested preview, reloads data inside the transaction, rejects a stale
`updated_at`/identity version, and re-evaluates preconditions. Previews are
single-use and cannot be replayed. The DB adapter MUST use a serializing write
transaction (e.g. `BEGIN IMMEDIATE`) and the repository MUST use compare-and-swap
updates (`WHERE id=? AND updated_at=?`) to prevent lost updates across processes.

**Atomicity:** The native encrypted SQLite adapter is not built yet. When
connected, history and audit MUST use the SAME connection and transaction as
the authoritative changes. Any failure before commit MUST roll back all
three; never surface success before the transaction returns normally. After
commit, failure refreshing UI projections does NOT mean the DB rolled back;
`OperationReceipt.projectionUpdated=false` allows a retry of refresh.

**Current limits:** The previous stand-alone user-management service introduced
in PART V still uses its test-only account store and is not wired into this
pipeline; its future production adapter must be migrated to the coordinator.
Likewise no site-management UI is exposed to end users. `ClosedTransactionExecutor`
rejects production writes until the real encrypted DB and transactional audit
sink are provided. This is an architectural/test milestone, not a complete
implementation of all 18 steps across every future feature.

## Test evidence

- Python/SQLite regression tests: all prior sections plus architecture checks.
- Real SQLite transaction proof: successful update/history/audit commit;
  deliberate history failure and audit failure prove full rollback.
- Dart unit tests: preview, confirmation, replay denial, stale version, failed
  write/history/audit/invariants, live account denial, system-site protection,
  duplicate name prevention, refresh failure after commit, and fail-closed
  storage. These execute in GitHub CI, where Flutter is installed.
- Windows CI: `flutter analyze`, `flutter test`, Windows release build, portable
  packaging, checksums, retained Flutter SDK/Dart Pub caches.

## Phone-only test option

`Android visual preview (optional)` is an independent, manually dispatched
workflow that compiles the SAME read-only Flutter UI into a temporary Android
APK. It never adds an Android production target to the repository or enables
personnel storage. This APK is **not** the Windows executable and does NOT
prove Wine/Winlator or native Windows compatibility. It is only a practical
visual preview for developers without a Windows computer.

The required acceptance gate remains the Windows GitHub Actions build. The
Android workflow is optional and cannot break the Windows workflow result.
