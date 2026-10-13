# التمام اليومي — ADWAS Personnel

**PART VI — Application Architecture and Operation Pipeline**  
**Version 0.0.6+6** — source foundation, **NOT** a production personnel system.

This milestone extends the verified Part V project in the existing private
GitHub repository `Win-manger`. The Windows desktop executable remains
**التمام اليومي.exe** and Arabic business terminology is unchanged.

## Added in PART VI

- Defined all required feature-layer boundaries, keeping unimplemented
  modules as directories rather than fabricated working screens.
- Built `OperationCoordinator` for normalized input, validation, session and
  permission checks, stale-preview detection, explicit confirmation,
  transactional updates, history, audit, invariant verification, and refresh.
- Added an implementable Site Rename business operation, plus a separate
  domain model and repository interface.
- Added a composition root, role-filtered navigation descriptors, typed
  error results with safe Arabic messages, and a fail-closed persistence port.
- Added Dart business-operation tests and SQLite rollback proofs.
- Preserved the entire Part III–V codebase, SQL test suite, native Windows
  packaging scripts, full requirements traceability, and dependency caches.

**No production personnel/accounts database has been enabled.** The encrypted
SQLite driver and durable transaction implementation remain later phases.
The previous test-only account management service is not a production action
and still needs to adopt this operation pipeline when wired to storage.

## Build and testing

See `docs/BUILD_GUIDE_AR.md`. Windows release CI is mandatory; an independent
**optional, manually triggered Android read-only UI preview** lets a user
without a Windows computer view the Flutter foundation interface on a phone.
The APK preview is not the Windows EXE and does not verify Windows behavior.

Do not proceed to the next milestone until the Windows build is green.
